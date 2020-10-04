function varargout = matfile_gitbranch_aware(varargin)
    %% documentation:
    % When working with multiple branches in git, any non commited files will
    % appear in your system when switching branches. Often I don't want to
    % commit .mat files, and so it's annoying to have to watch that I don't
    % overwrite them as I run code in different branches. One git-based
    % solution is to use the worktree command, but I find that solution to be a
    % bit too involved.
    %
    % Instead, for each branch I simply create and commit a file called
    % 'this_git_branch.txt' which contains the branch name. Then when using
    % matlabs matfile function, I instead use this wrapper which reads the
    % branch name from the file and add it as a suffix to the saved file name.
    % This means that I can keep non-commited saved files separate from one
    % another without thinking. The only difference you would notice is in the
    % case of saving the entire workspace - in this case I can't avoid one
    % extra variable being saved along for the ride, namely the varargin that
    % exists by vitue of using this function at all. Luickly the varragin in is
    % merely a cell array only a few hundred bytes in size.
    %
    % All options passed into this wrapper function are passed to the standard
    % matfile function with only the save name altered.

    %% start actual function
    % find the directory containing the .git directory
    git_branch_name_suffix = get_git_branch_suffix();

    % add suffix to the filename and handle for file extension
    varargin{1} = add_filename_suffix(varargin{1}, git_branch_name_suffix);

    % clear the vars that were not part of the original workspace
    clear git_branch_name_suffix

    % pass the all the arguemetns to the real function
    [varargout{1:nargout}] = matfile( varargin{:} );
