function reliability = internal_reliability(func, TR, varargin)
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
    % func  :   structure containing the fields func(n).data and func(n).dm
    %           func(n).data: 4D functional data
    %           func(n).dm: 2D design matrix
    % TR :      can be given in seconds or milliseconds
    %
    % optional arguments (passed as structure - see usage example below):
    % mask              :   logical (default = ones)
    % pervoxel          :   (default = True if mask is all ones, False
    %                       otherwise)
    % which_conditions  :   vector of which regressors in <func(n).dm> to
    %                       compute reliability over (default = all in <dm>)
    % max_n_splits      :   (default = 1000)
    % batch_size = 400  :   The correlations are computed in batches, and the
    %                       batch size can be optimised to give the best speed
    %                       (default = 400).
    % optimise_batchsize:   This optional will figure out the optimal size,
    %                       print it, and return all the check times in
    %                       reliability.optimal_batch_size. The batch size can
    %                       be set with <batch_size>.
    %
    % function usage example:
    % clear internal_reliability_params
    % internal_reliability_params.mask = <value1>;
    % internal_reliability_params.pervoxel = <value3>;
    % internal_reliability_params.which_conditions = <value3>;
    % internal_reliability_params.max_n_splits = <value5>;
    % internal_reliability_params.batch_size = <value6>;
    % internal_reliability_params.optimise_batchsize = <value7>;
    % reliability = internal_reliability(func, dm, internal_reliability_params);

    %% set default values for optional variables
    func_dims = size(func(1).data);
    mask = ones(func_dims(1:3));
    pervoxel = min(mask(:))==1;
    which_conditions = 1:size(func(1).dm, 2);
    max_n_splits = 1000;
    batch_size = 400;
    optimise_batchsize = 0;

    wiggles = mean(abs(diff(func(1).data, [], 4)),4);
    mask(wiggles==0)=0;

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
                        ['\nfunc_dims'],...
                        ['\nmask'],...
                        ['\npervoxel'],...
                        ['\nwhich_conditions'],...
                        ['\nmax_n_splits'],...
                        ['\nbatch_size'],...
                        ['\noptimise_batchsize'],...
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
    if TR > 500
        TR = TR/1000;
    end

    n_runs = size(func, 2);

    lin_mask = logical(mask(:));

    % check if we need to average the voxel timecourses
    if pervoxel
        betas = nan(sum(lin_mask), size(func(1).dm, 2)+1, n_runs);
    else
        betas = nan(1, size(func(1).dm, 2)+1, n_runs);
    end

    if optimise_batchsize
        times = zeros(3,100);
        batch_sizes = [10:10:1000];
        for i = 1:size(times, 1)
            count = 0;
            for batch_size = batch_sizes
                count = count + 1;
                tic
                for vox_idx = 1:batch_size:size(A_betas,1)
                    if vox_idx+batch_size>size(A_betas,1)
                        continue
                    end
                    self_corrs = corr(A_betas(vox_idx:vox_idx+batch_size-1,:)', B_betas(vox_idx:vox_idx+batch_size-1,:)');
                end
                x = toc;
                times(i,count) = x;
                fprintf('\nloop (N=3):\tbatch_size (N=100):\ttime:\n');
                fprintf('%d\t\t%d\t\t\t%s\n', i, batch_size, num2str(x));
            end
        end
        [value, index] = min(mean(times));
        fprintf('\nfastest batch_size size was: %d (%s secs)...\n', batch_sizes(index), num2str(value));
        reliability.optimal_batch_size = times;
        return
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
                'be adjusted by %d volume(s)'], run_idx, discrepancy))
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

        % remove low frequncy drifts from the timecourses
        %
        % following Kay et. al (2013) GLMdenoise: a fast, automated technique
        % for denoising task-based fMRI data. (Frontiers in neuroscience, 7,
        % 247)  :
        %       The number of polynomial regressors included in the model is
        %       set by a simple heuristic: for each run, we include
        %       polynomials of degrees 0 through round(L/2) where L is the
        %       duration in minutes of the run (thus, higher degree
        %       polynomials are used for longer runs).
        n_poly = floor(((func_dims(4)*round(TR))/60)/2);
        tmp_data = detrend(tmp_data, n_poly);

        if ~pervoxel
            tmp_data = mean(tmp_data,2);
        end

        % add run constant to dm
        tmp_dm = [tmp_dm, ones(size(tmp_dm,1),1)];
        
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
    if size(betas,1)<batch_size || ~pervoxel
        batch_size = 1;
        self_idx = 1;
    else
        self_idx = logical(eye(batch_size));
    end
    for split = 1:n_splits
        fprintf('%d/%d...\n', split, n_splits)
        A_runs = A_splits(split,:);
        B_runs = B_splits(split,:);
        A_betas = mean(betas(:,which_conditions,A_runs),3);
        B_betas = mean(betas(:,which_conditions,B_runs),3);
        for vox_idx = 1:batch_size:size(A_betas,1)
            if vox_idx+batch_size>size(A_betas,1) && pervoxel
                vox_idx = size(A_betas,1)-batch_size;
            end
            
            % self_corrs = corr(A_betas(vox_idx,:)', B_betas(vox_idx,:)');
            tmp_corrs = corr(A_betas(vox_idx:vox_idx+batch_size-1,:)',...
                B_betas(vox_idx:vox_idx+batch_size-1,:)');
            self_corrs = tmp_corrs(self_idx);
            corrs(vox_idx:vox_idx+batch_size-1, split) = self_corrs;
        end
    end

    if ~pervoxel
        reliability = corrs;
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

