% Save information about trials in input file with general structure
%
function saveGeneralInput(fileName, trials)
    fid = data.safefopen(fileName, 'w');
    ver = data.configVersion();

    fprintf(fid, 'Name: general; Version: %s\n', ver);

    for i = 1:length(trials)
        trial = trials{i};

        isAxona = helpers.isstring(trial.system, bntConstants.RecSystem.Axona, bntConstants.RecSystem.Virmen);

        fprintf(fid, 'Sessions ');
        fprintf(fid, '%s\n', trial.sessions{:});

        if ~isempty(trial.units)
            fprintf(fid, 'Units ');
            if ischar(trial.units)
                fprintf(fid, '%s\n', trial.units);
            else
                tetrodes = unique(trial.units(:, 1), 'stable');
                for j = 1:length(tetrodes)
                    selected = trial.units(:, 1) == tetrodes(j);
                    cells = sort(trial.units(selected, 2));
                    unitsStr = num2str(tetrodes(j));
                    unitsStr = strcat(unitsStr, sprintf(' %u', cells), ';');
                    fprintf(fid, '%s\n', unitsStr);
                end
            end
        end

        nonEmptyCuts = ~cellfun(@isempty, trial.cuts);
        if any(nonEmptyCuts)
            fprintf(fid, 'Cuts ');
            cutTetrodes = size(trial.cuts, 1);
            for t = 1:length(tetrodes)
                if t > cutTetrodes && ~isAxona
                    continue;
                end

                emptyInd = cellfun(@isempty, trial.cuts(t, :));
                if t > cutTetrodes || any(emptyInd)
                    for s = 1:length(trial.sessions)
                        if emptyInd(s) && isAxona
                            % construct cut file name for Axona. Might be
                            % unnecessary since we check different cut file name
                            % pattern during loading.
                            trial.cuts{t, s} = sprintf('%s_%u.cut', trial.sessions{s}, tetrodes(t));
                        end
                    end
                end

                cutsToSave = trial.cuts(t, ~emptyInd);
                cutsToSave = cellfun(@(x) strtrim(x), cutsToSave, 'UniformOutput', false);

                if length(cutsToSave) > 1
                    fprintf(fid, '%s,\n', cutsToSave{1:end-1});
                end
                fprintf(fid, '%s;\n', cutsToSave{end}); % print the last element with ;
            end
        end

        if isfield(trial.extraInfo, 'shape')
            fprintf(fid, '%s\n', trial.extraInfo.shape.descr);
        end

        if isfield(trial.extraInfo, 'calibration')
            fprintf(fid, 'Calibration %s\n', trial.extraInfo.calibration.file);
        end

        if isfield(trial.extraInfo, 'innerSize')
            fprintf(fid, 'InnerSize %s\n', trial.extraInfo.innerSize.rec);
        end

        if isfield(trial.extraInfo, 'outerSize')
            fprintf(fid, 'OuterSize %s\n', trial.extraInfo.outerSize.rec);
        end
        
        if isfield(trial, 'lfpChannels') && ~isempty(trial.lfpChannels)
            fprintf(fid, 'lfp ');
            lfpStr = sprintf('%d ', trial.lfpChannels);
            lfpStr(end) = []; % remove last ' '
            fprintf(fid, '%s\n', lfpStr);
        end

        fprintf(fid, '#\n');
    end
end
