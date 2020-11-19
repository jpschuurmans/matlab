input_path = '/home/mattb/projects/uclouvain/jolien_proj/z';
output_path = '/home/mattb/projects/uclouvain/jolien_proj/';
output_nifti_name = 'sub-01_mainExp_runs_reliability'; % don't add .nii

for run_idx = 1:5
    %% load functional data
    data = niftiread(sprintf('%ssub-01_ses-02_task-mainExp_run-%d_space-T1w_desc-preproc_bold.nii.gz', input_path, run_idx));
    func(run_idx).data = data;

    %% make dm
    logfile = tdfread(sprintf('%ssub-01_ses-02_task-mainExp_run-0%d_events.tsv', input_path, run_idx));

    % grab relevant fields
    onsets = logfile.onset;
    durations = logfile.duration/1000;
    trial_type = logfile.trial_type;

    % index of any row without n/a in it
    tmp = cellstr(trial_type);
    keep = find(~strcmp('n/a', tmp));

    conditions = unique(tmp, 'rows');
    % remove any row with n/a in it
    tmp = cellstr(conditions);
    remove = find(strcmp('n/a', tmp));
    conditions(remove,:) = [];
    conditions(2,:) = [];

    % pre allocate
    dm = zeros(round(onsets(end)), size(conditions,1)+1);

    checkerboard = 0;
    % go through each line of the logs we kept, and put a 1 in the correct column
    for i = 1:size(keep, 1)

        % row indicies
        start_idx = max(round(onsets(keep(i))), 1);
        if i == size(keep, 1)
            end_idx = start_idx + max(round(durations(keep(i))), 1);
        else
            end_idx = max(round(onsets(keep(i+1))), 1);
        end

        % column indicies
        condition = cellstr(trial_type(keep(i),:));

        % deal with checkerboard_None duplication
        if ~strcmp(condition{1}, 'checkerboard_None')
            condition = find(strcmp(condition{1}, conditions));
        else
            % first time do nothing different
            if checkerboard == 0;
                checkerboard = 1;
                condition = find(strcmp(condition{1}, conditions));
            else
                % if we've done the first one, put the second one in it's own col
                condition = size(dm,2);
            end
        end

        % fill in the design matrix
        dm(start_idx:end_idx, condition) = 1;
    end

    % convolve dm with hrf
    clear hrf_conv_params
    hrf_conv_params.time_res = 'vols';
    hrf_conv_params.TR = 2000';
    dm = hrf_conv(dm, hrf_conv_params);

    % the checkerboard conditions appear in the first and last columns...
    % put the first column to the last column: [2:N, 1]
    dm = circshift(dm, 1, 2);

    % we could add various dm confounds at this point

    % store dm in structure
    func(run_idx).dm = dm;
end

%% load mask
mask = niftiread(sprintf('%ssub-01_V1patch.nii', input_path));

%% run reliability function
clear internal_reliability_params
internal_reliability_params.mask = mask; % ROI
internal_reliability_params.pervoxel = 0; % get the ROI average reliability
internal_reliability_params.n_conditions = 1:24; % don't care about checkboards
reliability = internal_reliability(func, internal_reliability_params);

if isstruct(reliability)
    %% write reliability map
    niftiwrite(reliability.mean_map, sprintf('%s%s_mean.nii', output_path, output_nifti_name));
    niftiwrite(reliability.std_map, sprintf('%s%s_mean.nii', output_path, output_nifti_name));
end
