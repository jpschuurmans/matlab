function reliability = internal_reliability(func, varargin)
    %% documentation:
    % Computes the reliability of each voxel or in the mask as a whole between
    % random splits of the func (~roughly half the runs in each split) by
    % calculating GLM beta values of each condition in <func>.<dm>.
    %
    % If <mask> is provided, <pervoxel> is False by default and the function
    % returns a 2D matrix where each column contains the correlations from each
    % split of the average data in the mask.
    %
    % Else if <pervoxel> is True, Returns:
    % A structure contating two 3D maps (the same size as the first 3 dims of
    % <func>(1).data>). Each voxel in the first map contains the mean
    % correlation over splits. Each voxel in the second map contains the
    % standard deviation of the correlations over splits. Providing <mask> and
    % setting <pervoxel> to true will mean that only the part of the map in
    % mask will be computed, with the non-mask voxels being NaN values.

    % mandory arguments:
    % func :  structure containing the fields func(n).data and func(n).dm
    % func(n).data: 4D functional data
    % func(n).dm: 2D design matrix

    % optional arguments (passed as structure - see usage example below):
    % mask :  logical (default = ones)
    % pervoxel  : (default = True if mask is all ones, False otherwise)
    % n_conditions :  (default = all in <dm>)
    % n_splits  :  (default = 1000)

    % function usage example:
    % clear internal_reliability_params
    % internal_reliability_params.mask = <value1>;
    % internal_reliability_params.pervoxel = <value3>;
    % internal_reliability_params.n_conditions = <value3>;
    % reliability = internal_reliability(func, dm, internal_reliability_params);

    %% set default values for optional variables
    func_dims = size(func(1).run);
    mask ones(size(func_dims(1:3));
    pervoxel = min(mask(:))==1;
    n_conditions = size(func(1).dm, 2);
    n_splits = 1000

    %% override optional arguments
    % if varagin variables have been provided, overwrite the above default
    % values with provided values
    if ~isempty(varargin)
        if size(fieldnames(varargin{1}), 1) ~= 0
            vars_in_fields = fieldnames(varargin{1});
            % check variable names in varargin are expected by this function
            for i = 1:numel(vars_in_fields)
                if ~exist(vars_in_fields{i}, 'var')
                    error(sprintf([['variable <%s> does not correspond ',...
                        'exactly to any variable name used in the function',...
                        '\n\nvalid variable names are as follows:',...
                        '\n'],...


                        ], vars_in_fields{i}))
                end
            end
            additional_params = varargin{1};
            for additional_params_index = 1:size(fieldnames(varargin{1}), 1)
                eval([vars_in_fields{additional_params_index},...
                    ' = additional_params.',...
                    vars_in_fields{additional_params_index}, ';'])
            end
        end
    end

    %% start the actual fuction
    % DO SOMETHING ABOUT PER_VOXEL ARGUMENT
    n_runs = size(func);

    lin_mask = mask(:);

    % compute betas for each run
    betas = nan(sum(mask), size(dm,2), n_runs);
    for run_idx = 1:n_runs
        % extract run and dm
        tmp_data = func(run_idx).run;
        tmp_dm = func(run_idx).dm;

        % reshape tmp_data to be time x voxels
        tmp_data = permute(tmp_data, [4, 1, 2, 3);
        tmp_data = reshape(tmp_data, func_dims(4), []);
        % throw away non-mask data (I don't remember how to index)
        tmp_data(~lin_mask, :) = [];

        % compute betas for this run for all voxels
        betas(:,:,run_idx) = tmp_dm \ tmp_data;
    end

    % correlate betas between splits
    corrs = nans(size(func_dims(1:3),
    for split = 1:n_splits
        A_runs = ;
        B_runs = ;

        corr(betas(:,:,[A_runs), betas(:,:,[B_runs))

    end


