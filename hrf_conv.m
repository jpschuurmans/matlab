function dm_conv = hrf_conv(dm, varargin)
    % documentation:
    % Convolve the columns of a design matrix <dm> with an double gamma hrf
    % function. The <dm>

    % mandory arguments:
    % dm :  2D matrix where the columns contain timecourses of the level of
    %       stimulation. This is assumed to be in millisecond resoltion (if
    %       not, specify the <time_res> variable. If the resoltion is in
    %       something other fraction of a second, but not milliseconds (i.e.
    %       not 1/1000), then specify how many milliseconds in <time_steps>

    % default values for vars not set in varargin:
    time_res = 'ms'; %  this can be 'ms' or 'vols'. When it is 'vols', you
    %                   should also specify <TR> in milliseconds

    TR = 1000; %        TR in milliseconds

    time_steps = 1000; % If the resoltion is in something other fraction of a
    %                   second, but not milliseconds (i.e. not 1/1000), then
    %                   specify how many milliseconds out of a second it is in


    % if varagin variables have been provided, overwrite the above default values with
    % provided values
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

    %% Convolve
    doublegamma = hrf(1/time_steps, 20)';

    pre_size = size(dm,1);

    % comment for future matt: this was once conv2 and might be needed for more
    % than 1 column in dm? ...have fun
    dm_conv = conv2(dm, doublegamma);
    dm_conv  = dm_conv./max(dm_conv(:)); % scale to max height == 1;
    dm_conv = dm_conv(1:pre_size, :); % trim?

    %% Extract a timepoint per TR
    if strcmp(time_res, 'vols')
        dm_conv = dm_conv(TR:TR:end,:);
    end
