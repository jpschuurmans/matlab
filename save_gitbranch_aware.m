function varargout = save_gitbranch_aware(varargin)
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
    % matlabs save as function, I instead use this wrapper which reads the
    % branch name from the file and add it as a suffix to the saved file name.
    % This means that I can keep non-commited saved files separate from one
    % another without thinking. The only difference you would notice is in the
    % case of saving the entire workspace - in this case I can't avoid one
    % extra variable being saved along for the ride, namely the varargin that
    % exists by vitue of using this function at all. Luickly the varragin in is
    % merely a cell array only a few hundred bytes in size.
    %
    % All options passed into this wrapper function are passed to the standard
    % save function with only the save name altered.

    %% start actual function
    % in case we are trying to save all workspace variables, access them and
    % recreate them in this function's workspace (this might be a bad idea for
    % memory...)
    T = evalin('base','whos');
    for ii = 1:length(T)
        C_ =  evalin('base',[T(ii).name ';']);
        eval([T(ii).name,'=C_;']);
    end

    % read branch name
    git_branch_name = textscan(fopen('this_git_branch.txt'), '%q');
    git_branch_suffix = git_branch_name{1}{1};

    % add suffix to the filename and handle for file extension
    [filepath, filename, ext] = fileparts(varargin{1});
    varargin{1} = [filepath, filename, '_', git_branch_suffix, ext];

    % clear the vars that were not part of the original workspace
    clear T C_ ii git_branch_name git_branch_suffix filepath filename ext

    % pass the all the arguemetns to the real function
    [varargout{1:nargout}] = save( varargin{:} );
