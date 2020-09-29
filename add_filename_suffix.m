function filename_with_suffix = add_filename_suffix(orig_filename, suffix)
    %% documentation:
    % adds a suffix to the filename and handles the case where a path is
    % included in the given name and also where there is a file extension. The
    % suffix will be added after the '.' in the example below:
    %
    %   path/to/directory/file.ext
    %
    % mandory arguments:
    % arg : suffix is a string such as '_suffix'
    %
    % arg : orig_filename is a string that may include a path, filename with
    %       and extension

    %% start the actual function
    % split orig_filename into parts
    [filepath, filename, ext] = fileparts(orig_filename);

    % if the name includes a filepath, append a slash
    if filepath
        filepath = [filepath, '/'];
    end

    % add suffix to filename
    filename_with_suffix = [filepath, filename, suffix, ext];
