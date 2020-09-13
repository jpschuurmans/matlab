function found = regexpdir(pattern, varargin)
    % mandory arguments
    % pattern : regexp pattern as a string (I wonder how I'll deal with ' and ")

    % default values for vars not set in varargin
    path = ''; % where to search for files
    ext = ''; % looking for files with a particular ext? (maybe I should just deal with this in the pattern - but this way loads less in initially)

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
    % you may be wondering what the bloody hell is going on with all these try/catch statements... for some reason, the match output below (which is a cell array) sometimes needs to be indexed like match{1} and sometimes match will just be the string... so I'm covering all bases in a hacky way.

    files = dir(sprintf('%s/*%s', path, ext));
    found = {};
    count = 0;
    for idx = 1:size(files, 1);
        match = regexp(files(idx).name, pattern, 'match');
        try
            if ~isempty(match{1})
                count = count + 1;
                try
                    found{count} = match{1}{1};
                catch
                    found{count} = match{1};
                end
            end
        catch
            if ~isempty(match)
                count = count + 1;
                try
                    found{count} = match{1};
                catch
                    found{count} = match{1}{1};
                end

            end
        end
    end

