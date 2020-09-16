function mask = circmask(matSize, radius, varargin)
    % documentation:
    % Returns a 2D logical matrix with ones confined to a circle of specified
    % radius. The origin of the circle is in the centre of the matrix unless
    % the <location> is supplied in varargin

    % mandory arguments
    % matSize : vector containing number of rows / cols, respectively
    % radius :  radius of the circle in the returned matrix (must be at least
    %           half of smallest edge of <matSize>

    % default values for vars not set in varargin
    location = [round(matSize/2), round(matSize/2)]; %  vector containing
    %                                                   [x, y] coords of circle

    % if varagin variables have been provided, overwrite the above default values with
    % provided values
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

    % matrix dimensions
    N = matSize(1); M = matSize(2);

    % centre
    cx = location(1); cy = location(2);

    x = (1:N).'; y = 1:M;

    mask = (x-cx).^2 + (y-cy).^2 <= radius^2;

