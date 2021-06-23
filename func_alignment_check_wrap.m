clear
%% paths
addpath '/home/jschuurmans/Documents/02_recurrentSF_3T/analysis/matlab'
%data_dir = '~/projects/uclouvain/jolien_proj/';
sub = 'sub-17';

path = ['/home/jschuurmans/Documents/02_recurrentSF_3T/data-bids/derivatives/fmriprep/' sub '/ses-0*/func/' sub '_ses-0*_task-*_bold.nii.gz'];
directories = dir(path);

for run_ii = 1:length(directories)
    %fprintf('loading run %d\n',run_ii)
    % load a functional run
    functional_ni = niftiread(sprintf('%s/%s', directories(run_ii).folder,directories(run_ii).name ));
    fprintf('loading run %d - size %s\n',run_ii, num2str(size(functional_ni)))
    func_data(run_ii).data = functional_ni;
    
end
keyboard
% make a quick mask for testing
func_mean = squeeze(mean(functional_ni,4));
map_size = size(functional_ni);
map_size = map_size(1:3);
mask = zeros(map_size);
mask(:, 1:20, :) = 1;
mask(func_mean<-20000) = 0;

% enter optional arguments into struture
clear func_alignment_check_params
func_alignment_check_params.mask = mask;
func_alignment_check_params.autoplot = 1;

pairwise_alignment = func_alignment_check(func_data, func_alignment_check_params);
