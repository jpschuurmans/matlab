function [max_lag, max_r] = lagcorr2(timeseries4d, TR, lag_dur, sweep_time, ncylces, cycle_length, varargin)
    % mandory arguments
    % timeseries4d : a nifti file containing 4D timeseries of the retinotopy
    % TR : how many ms to acqurire each functional volume?
    % lag_dur : how long do you want to advance per lag?
    % sweep_time : how long does it take for the relevant area of visual field
    %              to be swept?
    % ncylces : how many cycles of did the retinotopy complete in the run?
    % cycle_length : how long was a cycle (in ms)?

    % default values for vars not set in varargin
    stim_length = 5333; % thicker wedges stimulate a visual field region for longer
    time_res = 'vols';

    % if varagin variables have been provided, overwrite the above default
    % values with provided values
    if ~isempty(varargin)
        if size(fieldnames(varargin{1}), 1) ~= 0

            vars_in_fields = fieldnames(varargin{1});
            for i = 1:numel(vars_in_fields)
                if ~exist(vars_in_fields{i}, 'var')
                    error('one or more of varargins does not correspond exactly to any variable name used in the function')
                end
            end
            additional_params = varargin{1};

            for additional_params_index = 1:size(fieldnames(varargin{1}), 1)
                eval([vars_in_fields{additional_params_index}, ' = additional_params.', vars_in_fields{additional_params_index}, ';'])
            end
        end
    end

    %% start the actual fuction
    steps = [0:lag_dur:sweep_time];
    nlags = length(steps);
    %% reshape the functional data into a 2D matrix
    orig_size = size(timeseries4d);
    nvols = orig_size(4);

    % get the time dimension to be the first one
    timeseries4d = permute(timeseries4d, [4,1,2,3]);

    % make a nvols x nvox matrix
    timeseries4d = reshape(timeseries4d, nvols, []);

    %% create HRF models (one for each lag)
    event_list = ones(ncylces,1);
    extra_params.BlockLength = stim_length;
    extra_params.ISI = cycle_length - stim_length;
    extra_params.TR = TR;
    extra_params.time_res = time_res;
    model = make_dm(event_list, extra_params);
    models = zeros(size(model,1), nlags);
    for idx = 1:nlags
        models(:,idx) = circshift(model, steps(idx));
    end

    %% Extract a timepoint per TR
    if strcmp(time_res, 'ms')
        models = models(TR:TR:end,:);
    end
    % kludge
    % models = [zeros(2,nlags); models];
    models = [models; zeros(142-size(models,1),nlags)];

    %% compute correlation for each model for each voxel and store highest
    % voxels x lag
    all_corrs = corr(double(timeseries4d), models);
    [max_corrs, ind] = max(all_corrs,[],2);

    % reshape to original dims and output
    max_r = reshape(max_corrs, orig_size(1:3));
    max_lag = reshape(ind, orig_size(1:3));

