function reliability = internal_reliability(func, varargin)
    %% documentation:
    % Computes the reliability of each voxel or in the mask as a whole between
    % random splits of the func (~roughly half the runs in each split) by
    % calculating GLM beta values of each condition in <func>.<dm>.
    %
    % If <mask> is provided, <pervoxel> is False by default and the function
    % returns a 1D matrix where each column contains the correlations from each
    % split of the average data in the mask.
    %
    % Else if <pervoxel> is True, returns:
    % A structure containing two 3D maps (the same size as the first 3 dims of
    % <func>(1).data>). Each voxel in the first map contains the mean
    % correlation over splits. Each voxel in the second map contains the
    % standard deviation of the correlations over splits. Providing <mask> and
    % setting <pervoxel> to True will mean that only the part of the map in
    % mask will be computed, with the non-mask voxels being NaN values.
    %
    % mandory arguments:
    % func :  structure containing the fields func(n).data and func(n).dm
    % func(n).data: 4D functional data
    % func(n).dm: 2D design matrix
    %
    % optional arguments (passed as structure - see usage example below):
    % mask              :   logical (default = ones)
    % pervoxel          :   (default = True if mask is all ones, False
    %                       otherwise)
    % which_conditions  :   vector of which regressors in <func(n).dm> to
    %                       compute reliability over (default = all in <dm>)
    % max_n_splits      :   (default = 1000)
    %
    % function usage example:
    % clear internal_reliability_params
    % internal_reliability_params.mask = <value1>;
    % internal_reliability_params.pervoxel = <value3>;
    % internal_reliability_params.which_conditions = <value3>;
    % reliability = internal_reliability(func, dm, internal_reliability_params);

    %% set default values for optional variables
    func_dims = size(func(1).data);
    mask = ones(size(func_dims(1:3)));
    pervoxel = min(mask(:))==1;
    which_conditions = 1:size(func(1).dm, 2);
    max_n_splits = 1000;

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
    n_runs = size(func, 2);

    lin_mask = logical(mask(:));

    % check if we need to average the voxel timecourses
    if pervoxel
        betas = nan(sum(lin_mask), size(func(1).dm, 2), n_runs);
    else
        betas = nan(1, size(func(1).dm, 2), n_runs);
    end

    % compute betas for each run
    for run_idx = 1:n_runs
        % extract run and dm
        tmp_data = double(func(run_idx).data);
        tmp_dm = func(run_idx).dm;

        % adjust size of dm if needed
        discrepancy = size(tmp_dm, 1) - size(tmp_data, 4);
        if abs(discrepancy) > 0
            disp('')
            warning(sprintf(['The design matrix for run %d has a ',...
                'different number of volumes than the data. The dm will ',...
                'be adjusted by %d volumes'], run_idx, discrepancy))
            disp('')
        end
        if discrepancy < 0
            padding = zeros(abs(discrepancy), size(tmp_dm, 2));
            tmp_dm = [tmp_dm; padding];
        elseif discrepancy > 0
            tmp_dm = tmp_dm(1:size(tmp_data, 4), :);
        end

        % reshape tmp_data to be time x voxels
        tmp_data = permute(tmp_data, [4, 1, 2, 3]);
        tmp_data = reshape(tmp_data, func_dims(4), []);
        % throw away non-mask data
        tmp_data(:, ~lin_mask) = [];

        if ~pervoxel
            tmp_data = mean(tmp_data,2);
        end

        % compute betas for this run for all voxels
        betas(:,:,run_idx) = (tmp_dm \ tmp_data)';
    end

    % correlate betas between splits
    A_splits = nchoosek(1:n_runs,floor(n_runs/2));
    B_splits = flipud(nchoosek(1:n_runs,ceil(n_runs/2)));

    % how many splits will we do
    n_splits = min(size(A_splits,1), max_n_splits);

    % shuffle if we're over max_n_splits
    if size(A_splits,1) > max_n_splits
        shuffle = randperm(n_splits);
        A_splits = A_splits(shuffle,:)
        B_splits = B_splits(shuffle,:)
    end

    % compute split-half correlations
    corrs = zeros(size(betas,1), n_splits);
    for split = 1:n_splits
        A_runs = A_splits(split,:);
        B_runs = B_splits(split,:);
        A_betas = mean(betas(:,which_conditions,A_runs),3);
        B_betas = mean(betas(:,which_conditions,B_runs),3);
        % needlessly doing all voxel pairwise correlations here...
        tmp_corrs = corr(A_betas', B_betas');
        self_corrs = tmp_corrs(logical(eye(size(A_betas,1))));
        corrs(:, split) = self_corrs;
    end

    if ~pervoxel
        reliability = corrs
    else
        % compute mean and std dev across splits
        mean_corrs = mean(corrs, 2);
        std_corrs = std(corrs, [], 2);

        % create maps
        reliability.mean_map = nan(func_dims(1:3));
        reliability.std_map = nan(func_dims(1:3));

        reliability.mean_map(lin_mask) = mean_corrs;
        reliability.std_map(lin_mask) = std_corrs;
    end
