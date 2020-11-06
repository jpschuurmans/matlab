function git_branch_name_suffix = get_git_branch_suffix()
    %% documentation:
    % This function looks for and returns if found the name of the git branch
    % that is checked out in the current directory. It works by searching from
    % the current directory up through successive parent directories (max=10)
    % until it finds the .git directory. Here it looks for a file called
    % 'this_git_branch.txt' which I habitually create in my git repositories
    % and which contains the branch name as it's first and only line. This line
    % is then returned as a string or if no such .git/.txt was found issues a
    % warning to that effect and returns an empty string.

    % find the directory containing the .git directory
    parent = '../';
    git_branch_name_suffix = '';
    warn_str = ['Did not find the file ''this_git_branch.txt'' in the',...
        'current directory. We will just use the normal matfile function.'];
    % check current dir and up to 10 above that
    for dir_height = 0:10
        % chain the parent dirs together
        search = repmat(parent, 1,dir_height);
        % if we find it look for the git branch file
        if exist([search, '.git'], 'dir')
            % read branch name and crete suffix
            if isfile([search, 'this_git_branch.txt'])
                git_branch_name = textscan(fopen([search,...
                    'this_git_branch.txt']), '%q');
                git_branch_name_suffix = ['_', git_branch_name{1}{1}];
            else
                warning(warn_str)
            end
            break
        end
    end
    if strcmp(git_branch_name_suffix, '')
        warning(warn_str)
    end
