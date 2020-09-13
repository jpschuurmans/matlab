function models = makePRFmodels(masks, grid_density, sigmas, varargin)
    % documentation:
    % create gaussian pRF models that span a circular region centred at the
    % origin of <masks> and with a diameter of the width/height of <masks>. The
    % models can then be convolved with and HRF function.

    % mandory arguments
    % masks :           best to use the output of retstim2mask.m 3D logical
    %                   matrix (time, X, Y) where ones represent stimulation

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


