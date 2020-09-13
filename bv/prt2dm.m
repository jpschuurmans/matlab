function out = prt2dm(prt, nvols, tr, varargin)

    conds = 1:prt.NrOfConditions;
    normal_dm = 1; % one predictor per condition
    single_trial_dm = 0; % one predictor per trial. If 1, labels will will also
    % be returned

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

    if tr < 100
        tr = tr*1000;
    end

    if strcmp(prt.ResolutionOfTime, 'Volumes')
        timeres = tr;
    elseif strcmp(prt.ResolutionOfTime, 'msec')
        timeres = 1;
    end

    nconds = size(conds,2);
    if normal_dm
        % make single trial dm
        out.dm = zeros(nvols*tr, nconds);
        count = 0;
        for condition = conds
            count = count + 1;
            for trial = 1:prt.Cond(condition).NrOfOnOffsets
                out.dm(prt.Cond(condition).OnOffsets(trial,1)*timeres:prt.Cond(condition).OnOffsets(trial,2)*timeres, conds(count)) = 1;
            end
        end
    end
    if single_trial_dm
        % make st_dm
        ntrials = 0;
        for condition = 1:nconds
            ntrials = ntrials + prt.Cond(condition).NrOfOnOffsets;
        end
        out.st_dm = zeros(nvols*tr, ntrials);
        count = 0;
        % for classification purposes, out put the condition labels as a vector
        % with one row per st_dm predictor
        out.labels = zeros(ntrials,1);
        for condition = 1:nconds
            for trial = 1:prt.Cond(condition).NrOfOnOffsets
                count = count + 1;
                out.labels(count) = condition;
                out.st_dm(prt.Cond(condition).OnOffsets(trial,1)*timeres:prt.Cond(condition).OnOffsets(trial,2)*timeres, count) = 1;
            end
        end
    end
