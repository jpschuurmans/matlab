%% paths and definitions
addpath '/home/mattb/code/matlab/matlab'
image_dir = '~/projects/uclouvain/jolien_proj/exported_pa_ecc/';
% image_dir = '~/projects/uclouvain/jolien_proj/exported_bars/';
data_dir = '~/projects/uclouvain/jolien_proj/';
func_name = 'sub-01_ses-01_task-paEcc_space-T1w_desc-preproc_bold.nii.gz';
stat_name = 'tstat1.nii.gz';
pa_map_outname = 'pa_from_pRF';

% parameters
grid_density = 10;
sigmas = [4, 8, 12];
time_steps = 1000/(((6*42667)-450)/842);
% time_steps = 1000/(((16*20000)-450)/1044);

%% setup
% convert the .png screenshots to a 3D binary mask matrix
fprintf('processing masks...\n');
stimMasks = retstim2mask(image_dir);

% create model timecourse and pad to make the baseline
models = makePRFmodels(stimMasks, grid_density, sigmas);
pad = zeros(size(models.models,1), round(12*time_steps));
models.models = [pad, models.models, pad];

% convolve the model timecourses with HRF function
params.time_res = 'ms';
params.time_steps = time_steps;
dm_conv = hrf_conv(models.models', params);

% down sample dm_conv to the TR resolution
idxq = linspace(1, size(dm_conv,1), size(dm_conv,1)/(time_steps*2));
dm_conv = interp1(dm_conv, idxq, 'linear');
dm_conv = [dm_conv; zeros(3, size(dm_conv,2))];
models.models = dm_conv;

%% fit models
functional_ni = niftiread(sprintf('%s%s', data_dir, func_name));

% for testing
func_mean = squeeze(mean(functional_ni,4));
map_size = size(functional_ni);
map_size = map_size(1:3);
mask = zeros(map_size);
mask(:, 1:18, :) = 1;
mask(func_mean<-20000) = 0;

fit_pRFs_params.mask = mask;
fitted_models = fit_pRFs(functional_ni, models, fit_pRFs_params)

% convert X and Y coords to polar and eccentricity coords
[theta, rho] = cart2pol(fitted_models.X, fitted_models.Y);

%% write to nifti
% load map info
tstat_info_ni = niftiinfo(sprintf('%s%s', data_dir, stat_name));

% change name and
tstat_info_ni.Filename = [data_dir, pa_map_outname, '.nii'];
niftiwrite(single(theta), [data_dir, pa_map_outname], tstat_info_ni);

tstat_info_ni.Filename = [data_dir, ecc_map_outname, '.nii'];
niftiwrite(single(rho), [data_dir, ecc_map_outname], tstat_info_ni);

figure
for im_slice = 1:30
    subplot(5,6,im_slice)
    % imagesc(rot90(squeeze(func_mean(:, im_slice, :)))), axis image, colormap gray
    % imagesc(rot90(squeeze(fitted_models.Y(:, im_slice, :)))), axis image
    % imagesc(rot90(squeeze(rho(:, im_slice, :)))), axis image, caxis([min(rho(:)), max(rho(:))])
    imagesc(rot90(squeeze(theta(:, im_slice, :)))), axis image, caxis([min(theta(:)), max(theta(:))])
    % imagesc(rot90(squeeze(mask(:, im_slice, :)))), axis image, colormap gray
end

