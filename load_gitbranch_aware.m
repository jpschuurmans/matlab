function varargout = load_gitbranch_aware(varargin)
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
    % matlabs load function, I instead use this wrapper which reads the branch
    % name from the file and add it as a suffix to the saved file name.  This
    % means that I can keep non-commited saved files separate from one another
    % without thinking. The only difference you would notice is in the case of
    % saving the entire workspace - in this case I can't avoid one extra
    % variable being saved along for the ride, namely the varargin that exists
    % by vitue of using this function at all. Luickly the varragin in is merely
    % a cell array only a few hundred bytes in size.
    %
    % All options passed into this wrapper function are passed to the standard
    % load function with only the save name altered.

    %% start actual function

    % read branch name
    git_branch_name = textscan(fopen('this_git_branch.txt'), '%q');
    git_branch_suffix = git_branch_name{1}{1};

    % add suffix to the filename and handle for file extension
    [filepath, filename, ext] = fileparts(varargin{1});

    % if the name includes a filepath, append a slash
    if filepath
        filepath = [filepath, '/'];
    end

    varargin{1} = [filepath, filename, '_', git_branch_suffix, ext];

    % clear the vars that were not part of the original workspace
    clear git_branch_name git_branch_suffix filepath filename ext

    % pass the all the arguements to the real function
    load( varargin{:} );

    clear varargin

    % create the loaded variables in the workspace where the script was called
    T = whos;
    for ii = 1:length(T)
        C_ = eval([T(ii).name ';']);
        assignin('base', T(ii).name, C_)
    end

