function pairwise_alignment = func_alignment_check(func_data, varargin)
    %% documentation:
    % Takes in a structure containing the 4D run timeseries. Each run is
    % averaged across volumes, and the pairwise corrlation (in a ROI if a mask
    % was provided) is computed between the (avareage) pixel intensities of all
    % runs.

    % mandory arguments:
    % func_data : structure with field 'data' containing 4D timeseries:
    %
    %   func_data(1).data = 4D run 1 timeseries
    %   func_data(2).data = 4D run 2 timeseries
    %       .
    %       .
    %   func_data(n).data = 4D run n timeseries

    % default values for vars not set in varargin: such values can be overided
    % by providing a structure as the last argument of the function with
    % fieldnames identical to the variable names e.g.
    % params.variable1 = <value>
    % params.variable2 = <value>

    % mask will default to the wholebrain if not provided the results are best
    % when a mask is provided which is confined to inside the brain and which
    % includs a sufficient variety of tissue types (so there is some reliable
    % variation to correlate)

    % time dimension is assumed to be the 4th unless otherwise specified
    time_dim = 4;

    % create a figure showing the correlation
    autoplot = 0;

    %% overide optional arguments
    % if varagin variables have been provided, overwrite the above default
    % values with provided values
    if ~isempty(varargin)
        if size(fieldnames(varargin{1}), 1) ~= 0
            vars_in_fields = fieldnames(varargin{1});
            for i = 1:numel(vars_in_fields)
                if ~exist(vars_in_fields{i}, 'var')
                    error(['one or more of varargins does not correspond ',...
                        'exactly to any variable name used in the function'])
                end
            end
            additional_params = varargin{1};
            for additional_params_index = 1:size(fieldnames(varargin{1}), 1)
                eval([vars_in_fields{additional_params_index},...
                    ' = additional_params.',...
                    vars_in_fields{additional_params_index}, ';'])
            end
        end
    end

    %% start the actual fuction
    func_size = size(func_data(1).data);
    func_size(time_dim) = [];

    % if no mask specified, create an all ones (wholebrain mask)
    if ~exist(mask)
        mask = ones(func_size);
    end

    % preallocate for memory
    func = zeros(numel(mask), size(func_data,1));
    for run_idx = 1:size(func_data,1)
        % extract functional data
        tmp_data = func_data(run_idx).data;
        % average over time dimension
        mean_vol = mean(tmp_data, time_dim)
        % store rusult
        func(run_idx, :) = tmp_data(:);
    end

    % compute the correlation
    pairwise_alignment = corr(func);

    % make a plot if asked
    if autoplot
        figure,
        imagesc(pairwise_alignment)
        colormap gray
        caxis([0.8 1])
    end
