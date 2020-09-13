function dm = dm_conv_hrf(dm, nvols, tr, varargin)
    % mandory arguments
    % dm : design matrix in millesecond resolution
    % nvols : how many volums will be in the data?
    % tr : TR is milleseconds

    % default values for vars not set in varargin

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

    % start the actual fuction

    % specift hrf
    t = 1:0.001:20; % 1 to 20 secs in millisecond steps
    hrf = gampdf(t,6) + -.5*gampdf(t,10); % hrf model
    hrf = hrf/max(hrf); % scale hrf to have max amplitude of 1
    hrf = hrf';

    % convolve
    dm = conv2(dm, hrf);

    % extract a timepoint per tr
    dm = dm(round(tr/2):tr:tr.*nvols,:);

    % scale to max height == 1;
    dm  = dm./max(dm(:));

