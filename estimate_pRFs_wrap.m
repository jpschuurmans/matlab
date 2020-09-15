%% paths
addpath '/home/mattb/code/matlab/matlab'

image_dirs = {'~/projects/uclouvain/jolien_proj/exported_pa_ecc/',
'~/projects/uclouvain/jolien_proj/exported_bars/',
'~/projects/uclouvain/jolien_proj/exported_bars/'};

data_dir = '~/projects/uclouvain/jolien_proj/';

func_names = {'sub-01_ses-01_task-paEcc_space-T1w_desc-preproc_bold.nii.gz',
'sub-01_ses-01_task-prfBars_run-1_space-T1w_desc-preproc_bold.nii.gz',
'sub-01_ses-01_task-prfBars_run-2_space-T1w_desc-preproc_bold.nii.gz'};

stat_map_name = 'tstat1.nii.gz';
pa_map_outname = 'pa_from_pRF_paecc_bars_bars';
ecc_map_outname = 'ecc_from_pRF_paecc_bars_bars';

% parameters
grid_density = 10;
sigmas = [4, 8, 12];
time_steps = [1000/(((6*42667)-450)/842),...
    1000/(((16*20000)-450)/1044),...
    1000/(((16*20000)-450)/1044)];

multi_run_dm = [];
for run_idx = 1:size(func_names,1)
    fprintf('processing run %d...\n', run_idx);
    time_step = time_steps(run_idx);
    image_dir = image_dirs{run_idx};

    % load functional data and concaternate in along time dimension
    functional_ni = niftiread(sprintf('%s%s', data_dir, func_names{run_idx}));
    multi_func = cat(4, multi_func, functional_ni);

    % keep building global run confounds design matrix
    multi_run_dm = [multi_run_dm, zeros(size(multi_run_dm,1), 1)];
    current_run = [zeros(size(functional_ni,4), size(multi_run_dm,2)),...
        ones(size(functional_ni,4), 1)];
    multi_run_dm = [multi_run_dm; current_run];

    % check for duplicate directories to avoid doing work multiple times
    if run_idx > 1 && ~strcmp(image_dir, image_dirs{run_idx-1})
        combined_models.models = cat(1, combined_models.models, models.models);
        continue
    end

    % convert the .png screenshots to a 3D binary mask matrix
    stimMasks = retstim2mask(image_dir);

    % create model timecourse and pad to make the baseline
    models = makePRFmodels(stimMasks, grid_density, sigmas);
    pad = zeros(size(models.models,1), round(12*time_step));
    models.models = [pad, models.models, pad];

    % convolve the model timecourses with HRF function
    params.time_res = 'ms';
    params.time_step = time_step;
    dm_conv = hrf_conv(models.models', params);

    % down sample dm_conv to the TR resolution
    idxq = linspace(1, size(dm_conv,1), size(dm_conv,1)/(time_step*2));
    dm_conv = interp1(dm_conv, idxq, 'linear');
    dm_conv = [dm_conv; zeros(1, size(dm_conv,2))];
    models.models = dm_conv;

    % concaternate models so far
    combined_models.models = cat(1, combined_models.models, models.models);
    combined_models.params = models.params;
end

% for testing
func_mean = squeeze(mean(functional_ni,4));
map_size = size(functional_ni);
map_size = map_size(1:3);
mask = zeros(map_size);
mask(:, 1:20, :) = 1;
mask(func_mean<-20000) = 0;

% remove global run confounds using glm
run_counfounds = multi_func \ multi_run_dm;
multi_func = multi_func - multi_run_dm * run_counfounds;

%% fit models
fit_pRFs_params.mask = mask;
fitted_models = fit_pRFs(multi_func, combined_models, fit_pRFs_params)

% convert X and Y coords to polar and eccentricity coords
[theta, rho] = cart2pol(fitted_models.X, fitted_models.Y);

%% write to nifti
% load map info as template
tstat_info_ni = niftiinfo(sprintf('%s%s', data_dir, stat_map_name));
tstat_info_ni.ImageSize = map_size;
% write polar angle map
tstat_info_ni.Filename = [data_dir, pa_map_outname, '.nii'];
niftiwrite(single(theta), [data_dir, pa_map_outname], tstat_info_ni);
% write eccentricity map
tstat_info_ni.Filename = [data_dir, ecc_map_outname, '.nii'];
niftiwrite(single(rho), [data_dir, ecc_map_outname], tstat_info_ni);

figure
for im_slice = 1:30
    subplot(5,6,im_slice)
    % imagesc(rot90(squeeze(func_mean(:, im_slice, :)))), axis image, colormap gray
    imagesc(rot90(squeeze(fitted_models.X(:, im_slice, :)))), axis image
    % imagesc(rot90(squeeze(rho(:, im_slice, :)))), axis image, caxis([min(rho(:)), max(rho(:))])
    % imagesc(rot90(squeeze(theta(:, im_slice, :)))), axis image, caxis([min(theta(:)), max(theta(:))])
    % imagesc(rot90(squeeze(mask(:, im_slice, :)))), axis image, colormap gray, caxis([0 1])
end

