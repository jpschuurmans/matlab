clear
%% paths
addpath '/home/jschuurmans/Documents/02_recurrentSF_3T/analysis/matlab'
path_out = '/home/jschuurmans/Documents/02_recurrentSF_3T/data-bids/derivatives/fmriprep/sub-17/ses-01/';
path = '/home/jschuurmans/Documents/02_recurrentSF_3T/data-bids/derivatives/fmriprep/sub-17/ses-01/func/sub-17_ses-01_task-main_run-*_bold.nii.gz';
directories = dir(path);
path_info = '/home/jschuurmans/Documents/02_recurrentSF_3T/data-bids/derivatives/fmriprep/sub-17/ses-02/func/sub-17_ses-02_task-main_run-*_bold.nii.gz';
directories_info = dir(path_info);
info_ni_NEW = niftiinfo(sprintf('%s/%s', directories_info(2).folder,directories_info(2).name ));
info_ni_NEW2 = niftiinfo(sprintf('%s/%s', directories_info(3).folder,directories_info(3).name ));

for run_ii = 1:length(directories)
    % load a functional run
    functional_ni = niftiread(sprintf('%s/%s', directories(run_ii).folder,directories(run_ii).name ));
    fprintf('loading run %d - size %s\n',run_ii, num2str(size(functional_ni)))

    info_ni = niftiinfo(sprintf('%s/%s', directories(run_ii).folder,directories(run_ii).name ));

    F = griddedInterpolant(double(functional_ni));
    [RL,AP,SI,T] = size(functional_ni);
    new_RL = (0:77/60:RL)';
    new_AP = (0:102/80:AP)';
    new_SI = (1:SI)';
    new_T = (1:T)';
    new_func_nii = int16(F({new_RL,new_AP,new_SI,new_T}));
    fprintf('loading run %d - size %s\n',run_ii, num2str(size(new_func_nii)))

    % write polar angle map
    outname = ['run-', num2str(run_ii),'.nii'];
    info_ni.Filename = [path_out, outname];
    info_ni.ImageSize = info_ni_NEW.ImageSize;
    info_ni.PixelDimensions = info_ni_NEW.PixelDimensions;
    info_ni.raw.dim = info_ni_NEW.raw.dim;
    info_ni.raw.pixdim = info_ni_NEW.raw.pixdim;
    info_ni.raw.dim = info_ni_NEW.raw.dim;
    info_ni.raw.qoffset_x = info_ni_NEW.raw.qoffset_x;
    info_ni.raw.qoffset_y = info_ni_NEW.raw.qoffset_y;
    info_ni.raw.qoffset_z = info_ni_NEW.raw.qoffset_z;
    info_ni.raw.srow_x = info_ni_NEW.raw.srow_x;
    info_ni.raw.srow_y = info_ni_NEW.raw.srow_y;
    info_ni.raw.srow_z = info_ni_NEW.raw.srow_z;
    info_ni.Filesize = info_ni_NEW.Filesize;
    
    niftiwrite(new_func_nii, [path_out, outname], info_ni);

end




