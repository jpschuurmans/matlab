function pixperVA = pixperVisAng(screen_height_pix, screen_height_cm, screen_distance_cm, varargin)
    % documentation:
    % Calculates number of screen pixels per 1 degre visual angle.

    % mandory arguments:
    % screen_height_pix : obvious

    % screen_height_cm : obvious

    % screen_distance_cm : obvious

    % default values for vars not set in varargin:

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
    screenVA = atand((screen_height_cm/2)/screen_distance_cm);
    pixperVA = (screen_height_pix/2)/screenVA;


