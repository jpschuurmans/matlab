function models = makePRFmodels(stimMasks, grid_density, sigmas, varargin)
    % documentation:
    % create gaussian pRF models that span a circular region centred at the
    % origin of <stimMasks> and with a diameter of the width/height of <stimMasks>. The
    % models can then be convolved with and HRF function.

    % mandory arguments
    % stimMasks :           best to use the output of retstim2mask.m which is a 3D
    %                   logical matrix (time, X, Y) where ones represent
    %                   stimulation

    % grid_density :    the pRFs will be centred on a grid with <grid_density>
    %                   rows/cols in between

    % sigmas :          a vector containing the pRF sizes to try. Each entry in
    %                   <sigmas> will set the stddev (in units of
    %                   <grid_density>) of a model.

    % default values for vars not set in varargin
    optional_arg1 = blah;

    % if varagin variables have been provided, overwrite the above default
    % values with provided values
    if ~isempty(varargin)
        if size(fieldnames(varargin{1}), 1) ~= 0

            vars_in_fields = fieldnames(varargin{1});
            for i = 1:numel(vars_in_fields)
                if ~exist(vars_in_fields{i}, 'var')
                    error('one or more of varargins does not correspond exactly to any variable name used in the function')
                end
            end
            additional_params = varargin{1};

            for additional_params_index = 1:size(fieldnames(varargin{1}), 1)
                eval([vars_in_fields{additional_params_index}, ' = additional_params.', vars_in_fields{additional_params_index}, ';'])
            end
        end
    end

    %% start the actual fuction
    spatiotemp_size = size(stimMasks);

    % define ROI in which we will make models
    matSize = [spatiotemp_size(2), spatiotemp_size(3)];
    radius = spatiotemp_size(2)/2 - max(sigmas)*2;
    roi = circmask(matSize, radius);

    % define gaussian models: one model per row
    x_coords = 1:grid_density:spatiotemp_size(2);
    y_coords = 1:grid_density:spatiotemp_size(3);

    % preallocate for memory
    gaussians = nan(length(x_coords)*length(y_coords)*length(sigmas),...
        spatiotemp_size(2)*spatiotemp_size(3)); model_params nan(size
    model_params = nan(size(gaussians,1), 3);

    model_count = 0;
    for sigma_idx = 1:length(sigmas)
        % define gaussian
        gauss = fspecial('gaussian',...
            [spatiotemp_size(2), spatiotemp_size(3)], sigmas(sigma_idx));

        % clip gaussian at 2 sigma (prevents wrap around in circshift)
        gaussian_clip = circmask(matSize, sigmas(sigma_idx)*2);
        gauss(~gaussian_clip) = 0;

        % start the pRF in the upper left corner of the matrix
        gauss = circshift(gauss, [-spatiotemp_size(2)/2,spatiotemp_size(3)/2]);
        for x = x_coords
            for y = y_coords
                if roi(x,y) % if model falls within roi
                    model_count = model_count + 1;
                    % systematically shift the pRF along the x and y axes
                    gauss_tmp = circshift(gauss, [x,y]);
                    % store the model
                    gaussians(model_count, :) = gauss_tmp(:);
                    % and the model params
                    model_params(model_count,:) = [x, y, sigmas(sigma_idx)];
                end
            end
        end
    end
    % remove out-of-roi models
    gaussians(max(isnan(gaussians),[],2),:) = [];
    model_params(max(isnan(model_params),[],2),:) = [];

    % stimMasks: vectorised pixel space x time
    stimMasks = reshape(stimMasks, spatiotemp_size(1), [])';

    % compute models
    % gaussian models * stimMasks = pRF_model timecourse (before convolution)
    models = gaussians * stimMasks;
