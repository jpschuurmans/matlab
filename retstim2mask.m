function stimMasks = retstim2mask(image_dir, varargin)
    % documentation:
    % loads in all images of a specified format from a specified directory and
    % outputs a 3D logical matrix <stimMasks> in which (time, X, Y) where ones
    % represent stimulation

    % mandory arguments
    % image_dir : where are the images you want to convert into <stimMasks>?

    % default values for vars not set in varargin
    fmt = 'png'; % what format are the images?
    resize = 270; % how many pixels do you want the width and height to be?
    keyboard
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

    if ~strcmp(image_dir(end), '/')
        image_dir = [image_dir, '/'];
    end
    if ~strcmp(fmt(1), '.')
        fmt = ['.', fmt];
    end

    %% start the actual fuction
    files = dir(sprintf('%s*%s', image_dir, fmt));

    stimMasks = logical(zeros(size(files,1), resize, resize));
    for file_idx = 1:size(files,1)
        tmp = imread(sprintf('%s%s', image_dir, files(file_idx).name));
        tmp = rgb2gray(tmp);

        % take the middle square region
        imsize = size(tmp);
        side_remove = (imsize(2)-imsize(1))/2;
        tmp = tmp(:, side_remove:side_remove+imsize(1)-1);

        % convert to binary masks
        % tmp = changem(tmp, [0 1 1], [127, 0, 255]);
        tmp(tmp==0)=1;
        tmp(tmp==255)=1;
        tmp(tmp==127)=0;

        % resize
        tmp = imresize(tmp, [resize, resize]);

        stimMasks(file_idx, :, :) = tmp;
    end
