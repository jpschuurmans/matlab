function DM = make_dm(Labels, varargin)
    % Make DM
    % Returns a Design Matrix in volume resolution
    % Things should be given in ms resolution. If not, I will convert them.

    % Labels = shows the block order. Zeros will be omitted form the design. E.g.

    % Labels = [1     2     1     0     2     2     1     0     3     3     1];
    % So you could set ISI = 0 and use certain blocks set to zeros to make a custom baseline.
    % For instance if you had a back-to-back block design, with a baseline (the same length as
    % one block) every 5 blocks. [~ 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5 ~]; where ~ = first/last
    % baseline.


    First_Baseline = 12000; % assume 12 sec baseline
    Last_Baseline = 12000; % assume 12 sec baseline
    BlockLength = 12000; % assume 12 sec blocks
    ISI = 12000; % assume 12 secs between blocks
    TR = 1000; % assume TR is 1000
    time_res = 'vols';

    %% Params

    % if an additional_info variable has been provided, overwrite the above variables to correspond to the
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

    %% Check if we have millisecond resolution. If not, convert it.
    if TR < 500 || BlockLength < 500 || ISI < 500 || First_Baseline < 500 || Last_Baseline < 500
        warning('It seems that some parameters were given in volumes rather than ms: they will be converted to ms when creating a DM, then TRs will be extracted...')
    end
    if TR < 500
        tmpTR = TR;
        TR = TR*1000;
    else
        tmpTR = TR/1000; % if they give TR in ms, but other things in volumes (which would be weird and dumb),
        % we need to convert using a TR in seconds.
    end
    if BlockLength < 500
        BlockLength = BlockLength*1000*tmpTR;
    end
    if ISI < 500
        ISI = ISI*1000*tmpTR;
    end
    if First_Baseline < 500
        First_Baseline = First_Baseline*1000*tmpTR;
    end
    if Last_Baseline < 500
        Last_Baseline = Last_Baseline*1000*tmpTR;
    end

    % Labels needs to be a column vector. If not, change it.
    if size(Labels,2)>size(Labels,1)
        Labels = Labels';
    end

    %% Create DM (initally in ms resolution)
    NPreds = numel(unique(Labels));

    empty_labels = 0; % if some conditions need to be omitted from the DM (coded as zero)
    if min(Labels) == 0
        Labels = Labels + 1; % pretend that these zeros are ones
        empty_labels = 1; % remember we need to remove the first predictor
    end

    DM = zeros(numel(Labels), NPreds);
    DM(sub2ind(size(DM), 1:numel(Labels), Labels')) = 1;

    if empty_labels % remove first predictor if it was coding for omitted conditions
        DM(:,1) = [];
        NPreds = NPreds - 1;
    end

    DM = DM(:);
    DM = [repmat(DM,1,BlockLength), zeros(length(DM), ISI)];
    DM = DM';
    DM = DM(:);
    DM = reshape(DM, [], NPreds);
    DM = [zeros(First_Baseline, NPreds); DM; zeros(Last_Baseline, NPreds)];

