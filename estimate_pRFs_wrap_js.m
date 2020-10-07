clear all
%% paths
addpath '/home/jschuurmans/Documents/02_recurrentSF_3T/analysis/matlab'

image_dirs = {'/home/jschuurmans/Documents/02_recurrentSF_3T/Stimuli/exported_pa_ecc',
'/home/jschuurmans/Documents/02_recurrentSF_3T/Stimuli/exported_bars',
'/home/jschuurmans/Documents/02_recurrentSF_3T/Stimuli/exported_bars'};

input_dir = '/home/jschuurmans/Documents/02_recurrentSF_3T/Data_BIDS/fmriprep/sub-01/ses-01/func/';
output_dir = '/home/jschuurmans/Documents/02_recurrentSF_3T/Data_BIDS/v1/sub-01/'; 

func_names = {'sub-01_ses-01_task-paEcc_space-T1w_desc-preproc_bold.nii.gz',
'sub-01_ses-01_task-prfBars_run-1_space-T1w_desc-preproc_bold.nii.gz',
'sub-01_ses-01_task-prfBars_run-2_space-T1w_desc-preproc_bold.nii.gz'};

stat_map_name = 'sub-01_fake_tstat_map_retino.nii.gz';
pa_map_outname = 'pa_from_pRF_paecc_bars_bars';
ecc_map_outname = 'ecc_from_pRF_paecc_bars_bars';
prf_size_map_outname = 'prf_size_from_pRF_paecc_bars_bars';
rsq_map_outname = 'rsq_from_pRF_paecc_bars_bars';

screen_height_pix = 1080;
screen_height_cm = 39;
screen_distance_cm = 200;

%% parameters
% if we pretend the screen was lower resolution, all the computations are less
% expensive and we don't lose much precision (it's no as if we can reliably
% estimate the pRF location down to the pixel level)
down_sample_model_space = screen_height_pix/4;

% number of pixels (in downsized space) bewteen neighbouring pRF models
grid_density = 5;

% sigmas in visual degrees to try as models
% I think we need a logarithmic scaling here...
% sigmas = [0.05 : 0.05 : 0.8];
% sigmas = [0.8:0.1:2];
sigmas = [4,8,12];

% specifc to pa-ecc run and the 2 bar runs
time_steps = [1000/(((6*42667)-450)/842),...
    1000/(((16*20000)-450)/1044),...
    1000/(((16*20000)-450)/1044)];

%% start
pixperVA = pixperVisAng(screen_height_pix, screen_height_cm, screen_distance_cm);
r_pixperVA = pixperVA/(screen_height_pix/down_sample_model_space);
sigmas = sigmas * r_pixperVA;

nruns = size(func_names,1);
multi_func_ni = [];
combined_models.models = [];
multi_run_dm = [];
identity_nruns = eye(nruns);
nvols = zeros(nruns,1);
for run_idx = 1:nruns
    fprintf('processing run %d...\n', run_idx);
    time_step = time_steps(run_idx);
    image_dir = image_dirs{run_idx};

    % load functional data and concaternate in along time dimension
    functional_ni = niftiread(sprintf('%s%s', input_dir, func_names{run_idx}));
    multi_func_ni = cat(4, multi_func_ni, functional_ni);
    nvols(run_idx) = size(functional_ni,4);

    % build up the global run confounds design matrix
    multi_run_dm = [multi_run_dm;...
        kron(identity_nruns(run_idx,:), ones(nvols(run_idx,1),1))];

    % check for duplicate directories to avoid doing work multiple times
    if run_idx > 1 && strcmp(image_dir, image_dirs{run_idx-1}) &&...
            nvols(run_idx) == nvols(run_idx-1)
        combined_models.models = cat(1, combined_models.models, models.models);
        continue
    end

    % convert the .png screenshots to a 3D binary mask matrix
    clear retstim2mask_params
    retstim2mask_params.resize = down_sample_model_space;
    stimMasks = retstim2mask(image_dir, retstim2mask_params);

    % create model timecourse and pad to make the baseline
    models = makePRFmodels(stimMasks, grid_density, sigmas);
    pad = zeros(size(models.models,1), round(12*time_step));
    models.models = [pad, models.models, pad];

    % convolve the model timecourses with HRF function
    clear dm_conv_params
    dm_conv_params.time_res = 'ms';
    dm_conv_params.time_step = time_step;
    dm_conv = hrf_conv(models.models', dm_conv_params);

    % down sample dm_conv to the TR resolution
    idxq = linspace(1, size(dm_conv,1), size(dm_conv,1)/(time_step*2));
    dm_conv = interp1(dm_conv, idxq, 'linear');
    dm_conv = [dm_conv; zeros(nvols(run_idx)-size(dm_conv,1), size(dm_conv,2))];
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
% put the data into a volumes x voxels matrix
multi_func_ni = permute(multi_func_ni, [4, 1, 2 3]);
multi_func_ni = reshape(multi_func_ni, size(multi_func_ni,1), []);
% estimate the voxel run means, make the model, subract it off
run_counfounds = multi_run_dm \ double(multi_func_ni);
confound_model = multi_run_dm * run_counfounds;
resid = double(multi_func_ni) - confound_model;
% put the data back into it's original 4D shape
multi_func_ni = reshape(resid, [sum(nvols), map_size]);
multi_func_ni = permute(multi_func_ni, [2, 3, 4 1]);

%% fit models
fprintf('fitting pRFs...\n');
clear fit_pRFs_params
fit_pRFs_params.mask = mask;
fitted_models = fit_pRFs(multi_func_ni, combined_models, fit_pRFs_params);

% convert X and Y coords to polar and eccentricity coords
[theta, rho] = cart2pol(fitted_models.X-retstim2mask_params.resize/2,...
    fitted_models.Y-retstim2mask_params.resize/2);

% convert theta into degrees (1-180 from upper to lower visual field)
theta = rad2deg(theta)+180;
theta = changem(round(theta), [91:180, fliplr(1:180), 1:90], [1:360]);

fprintf('writing nifti maps...\n');
%% write to nifti
% load map info as template
tstat_info_ni = niftiinfo(sprintf('%s%s', input_dir, stat_map_name));
tstat_info_ni.ImageSize = map_size;
% write polar angle map
tstat_info_ni.Filename = [output_dir, pa_map_outname, '.nii'];
niftiwrite(single(theta), [output_dir, pa_map_outname], tstat_info_ni);
% write eccentricity map
tstat_info_ni.Filename = [output_dir, ecc_map_outname, '.nii'];
niftiwrite(single(rho), [output_dir, ecc_map_outname], tstat_info_ni);
% write prf_size map
tstat_info_ni.Filename = [output_dir, prf_size_map_outname, '.nii'];
niftiwrite(single(fitted_models.sigma), [output_dir, prf_size_map_outname], tstat_info_ni);
% write r_squared map
tstat_info_ni.Filename = [output_dir, rsq_map_outname, '.nii'];
niftiwrite(single(fitted_models.r_squared), [output_dir, rsq_map_outname], tstat_info_ni);
