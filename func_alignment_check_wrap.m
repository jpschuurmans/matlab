%% paths
addpath '/home/mattb/code/matlab/matlab'
data_dir = '~/projects/uclouvain/jolien_proj/';

func_name = 'sub-01_ses-01_task-paEcc_space-T1w_desc-preproc_bold.nii.gz',

% load a functional run
functional_ni = niftiread(sprintf('%s%s', data_dir, func_name));

% make a quick mask for testing
func_mean = squeeze(mean(functional_ni,4));
map_size = size(functional_ni);
map_size = map_size(1:3);
mask = zeros(map_size);
mask(:, 1:20, :) = 1;
mask(func_mean<-20000) = 0;

% make slightly misaligned copies of the functional data to simulate many runs
% store the runs in a data structure
func_data(1).data = functional_ni;
for run_idx = 2:12
    rand_shift = [randi(3)-2, randi(3)-2, randi(3)-2, 0];
    func_data(run_idx).data = circshift(functional_ni, rand_shift);
end

% make a badly aligned run
func_data(3).data = circshift(functional_ni, [3, 5, 0]);

% enter optional arguments into struture
clear func_alignment_check_params
func_alignment_check_params.mask = mask;
func_alignment_check_params.autoplot = 1;

pairwise_alignment = func_alignment_check(func_data, func_alignment_check_params);
