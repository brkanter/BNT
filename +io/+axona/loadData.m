% Load Axona data for specified trial
%
function loadData(trialNum)
    global gBntData;

    if length(gBntData) < trialNum
        error('Invalid argument');
    end

    if helpers.isstring(gBntData{trialNum}.system, bntConstants.RecSystem.Axona, bntConstants.RecSystem.Virmen) == false
        error('Invalid recording system');
    end

    numSessions = length(gBntData{trialNum}.sessions);
    numSamples = 0;
    timeOffset = nan(1, numSessions);
    eegDataAll = {};
    numSpikes = 0;

    oldMatData = false;
    matPos = fullfile(gBntData{trialNum}.path, sprintf('%s_pos.mat', gBntData{trialNum}.basename));
    if exist(matPos, 'file') ~= 0
        tmp = load(matPos);

        if isfield(tmp, 'posx')
            oldMatData = true;
        end
    end

    tetrodes = unique(gBntData{trialNum}.units(:, 1), 'stable');

    if oldMatData
        % data is already converted, just load it
        tmp.posx = helpers.fixIsolatedData(tmp.posx);
        tmp.posy = helpers.fixIsolatedData(tmp.posy);

        if isfield(tmp, 'posx2')
            tmp.posx2 = helpers.fixIsolatedData(tmp.posx2);
            tmp.posy2 = helpers.fixIsolatedData(tmp.posy2);
            gBntData{trialNum}.positions = [tmp.post tmp.posx tmp.posy tmp.posx2 tmp.posy2];
        else
            gBntData{trialNum}.positions = [tmp.post tmp.posx tmp.posy];
        end
        clear tmp;

        numCells = size(gBntData{trialNum}.units, 1);
        for c = 1:numCells
            cellTsFile = fullfile(gBntData{trialNum}.path, sprintf('%s_T%uC%u.mat', ...
                gBntData{trialNum}.basename, gBntData{trialNum}.units(c, 1), ...
                gBntData{trialNum}.units(c, 2)));
            if exist(cellTsFile, 'file') ~= 0
                tmp = load(cellTsFile);

                curNumSpikes = length(tmp.cellTS);
                startIdx = numSpikes + 1;
                endIdx = numSpikes + curNumSpikes;

                gBntData{trialNum}.spikes(startIdx:endIdx, 1) = tmp.cellTS;
                gBntData{trialNum}.spikes(startIdx:endIdx, 2) = gBntData{trialNum}.units(c, 1);
                gBntData{trialNum}.spikes(startIdx:endIdx, 3) = gBntData{trialNum}.units(c, 2);

                numSpikes = endIdx;
            else
                warning('Loading converted data, but failed to find file %s', cellTsFile);
            end
        end
    else
        for s = 1:numSessions
            % Open setup file and read out the EEG information
            setFileName = strcat(gBntData{trialNum}.sessions{s}, '.set');
            if exist(setFileName, 'file') == 0
                fprintf('There is no .SET file!\n');
            end

            if strcmpi(gBntData{trialNum}.system, bntConstants.RecSystem.Virmen)
                videoFile = strcat(gBntData{trialNum}.sessions{s}, '.vr');
                if exist(videoFile, 'file') == 0
                    error('Failed to find VR position file.\nSearched for %s', videoFile);
                end
                fprintf('Loading VR file "%s"...', videoFile);
                vr_pos = dlmread(videoFile, ' ');
                fprintf(' done\n');
                tpost = vr_pos(:, 1);
                tposx = vr_pos(:, 2);
                tposy = vr_pos(:, 3);
                tposx2 = [];
                tposy2 = [];
                tpos = [tpost tposx tposy tposx2 tposy2];
            else
                videoFile = strcat(gBntData{trialNum}.sessions{s}, '.pos');
                if exist(videoFile, 'file') == 0
                    error('Failed to find position file.\nSearched for %s', videoFile);
                end

                fprintf('Loading video file "%s"...', videoFile);
                tpos = io.axona.getPos(videoFile);
                fprintf(' done\n');
            end

            tposx = helpers.fixIsolatedData(tpos(:, bntConstants.PosX));
            tposy = helpers.fixIsolatedData(tpos(:, bntConstants.PosY));

            curSessionSamples = length(tposx);

            offset = 0;
            if s > 1
                gBntData{trialNum}.startIndices(s) = numSamples + 1;
                offset = gBntData{trialNum}.positions(end, bntConstants.PosT) + 0.02;
            else
                gBntData{trialNum}.startIndices(s) = 1;
            end
            timeOffset(s) = offset;

            gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosT) = tpos(:, bntConstants.PosT) + offset;
            gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosX) = tposx;
            gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosY) = tposy;
            if size(tpos, 2) > 3
                tposx2 = helpers.fixIsolatedData(tpos(:, bntConstants.PosX2));
                tposy2 = helpers.fixIsolatedData(tpos(:, bntConstants.PosY2));

                gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosX2) = tposx2;
                gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosY2) = tposy2;
            end

            numSamples = numSamples + curSessionSamples;

            for i = 1:length(tetrodes)
                tetrode = tetrodes(i);
                spikeFile = strcat(gBntData{trialNum}.sessions{s}, sprintf('.%u', tetrode));

                fprintf('Loading spike file "%s"...', spikeFile);
                spikeData = io.axona.importspikes(spikeFile);
                fprintf(' done\n');

                curNumSpikes = length(spikeData);

                gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 1) = spikeData + timeOffset(s);
                gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 2) = tetrode;

                numSpikes = numSpikes + curNumSpikes;
            end
        end % loop over sessions

        numCutData = 0;
        for t = 1:length(tetrodes)
            tetrodeCutData = [];

            % use a copy, so if there is no cut file information present in a gBntData, then
            % we do not mess up with helpers.uniqueFilename
            cutFiles = gBntData{trialNum}.cuts;

            for cc = 1:size(cutFiles, 2)
                if ~isempty(cutFiles{t, cc}) && exist(cutFiles{t, cc}, 'file') ~= 0
                    fprintf('Loading cut file "%s"...', cutFiles{t, cc});
                    tmpCutData = io.axona.getCut(cutFiles{t, cc});
                    fprintf(' done\n');

                    % in case of combined sessions and a single cut file for them,
                    % indices in tmpCutData are linear, but they are not linear in gBntData.spikes.
                    % so accumulate all the spikes and put it into .spikes later
                    tetrodeCutData = cat(1, tetrodeCutData, tmpCutData);

                    curNumCutData = length(tmpCutData);
                    numCutData = numCutData + curNumCutData;
                end
            end
            if ~isempty(tetrodeCutData)
                tetrodeIndices = gBntData{trialNum}.spikes(:, 2) == tetrodes(t);
                numRealSpikes = length(find(tetrodeIndices));
                if numRealSpikes ~= length(tetrodeCutData)
                    error('BNT:badCuts', 'Cut file(s) provided for trial (%s), tetrode %u does not correspond to that trial. Trial has %u raw spikes, cut file contains %u labels.', ...
                        gBntData{trialNum}.sessions{1}, tetrodes(t), numRealSpikes, length(tetrodeCutData));
                end
                gBntData{trialNum}.spikes(tetrodeIndices, 3) = tetrodeCutData;

                tetrodeIndices = gBntData{trialNum}.units(:, 1) == tetrodes(t);
                tetrodeCells = gBntData{trialNum}.units(tetrodeIndices, 2);
                if isnan(tetrodeCells(1))
                    % this shall not be the case
                    warning('Please contact Vadim regarding this warning');
                    gBntData{trialNum}.units(tetrodeIndices, :) = [];
                    presentCells = unique(tetrodeCutData);
                    presentCells(presentCells == 0) = [];
                    presentCells = presentCells(:); % make it a column
                    tetrodeUnits = [tetrodes(t)*ones(length(presentCells), 1) presentCells];
                    gBntData{trialNum}.units = cat(1, gBntData{trialNum}.units, tetrodeUnits);
                end
            end
        end

        if numCutData ~= numSpikes
            msg = 'Length of loaded cut data doesn''t match length of the loaded spike data';
            warning(msg);
            fprintf('%s\n', msg);
        end
    end

    spikesToDelete = gBntData{trialNum}.spikes(:, 3) == 0;
    gBntData{trialNum}.spikes(spikesToDelete, :) = [];

    if isempty(gBntData{trialNum}.spikes)
        warning('BNT:noSpikes', 'There are no spikes for session %s', gBntData{trialNum}.basename);
    else
        [minSpike, ~] = nanmin(gBntData{trialNum}.spikes(:, 1));
        if ~isempty(minSpike)
            minTime = nanmin(gBntData{trialNum}.positions(:, bntConstants.PosT));
            if minSpike < minTime
                toRemove = gBntData{trialNum}.spikes(:, 1) < minTime;

                warning('BNT:earlySpike', 'Data contains %u spike times that are earlier than first position timestamp. These spikes will be removed.', length(find(toRemove)));
                gBntData{trialNum}.spikes(toRemove, :) = [];
            end
        end

        maxSpike = nanmax(gBntData{trialNum}.spikes(:, 1));
        if ~isempty(maxSpike)
            maxTime = nanmax(gBntData{trialNum}.positions(:, bntConstants.PosT));
            if maxSpike > maxTime
                toRemove = gBntData{trialNum}.spikes(:, 1) > maxTime;

                warning('BNT:lateSpike', 'Data contains %u spike times that occur after the last position timestamp. These spikes will be removed.', length(find(toRemove)));
                gBntData{trialNum}.spikes(toRemove, :) = [];
            end
        end
    end

%     %% let's calculate cells cut hashes
%     hashOpt.Method = 'MD5';
%     hashOpt.Input = 'file';
%     for t = 1:length(tetrodes)
%         tetrodeIndices = gBntData{trialNum}.units(:, 1) == tetrodes(t);
%         tetrodeCells = gBntData{trialNum}.units(tetrodeIndices, :);
% 
%         cellLinearInd = helpers.tetrodeCellLinearIndex(tetrodeCells(:, 1), tetrodeCells(:, 2));
%         for s = 1:size(cutFiles, 2)
%             if isempty(cutFiles{t, s})
%                 continue;
%             end
%             cutFile = cutFiles{t, s};
%             if exist(cutFile, 'file') == 0
%                 continue;
%             end
%             fileHash = DataHash(cutFile, hashOpt);
%             for c = 1:length(cellLinearInd)
%                 curCell = cellLinearInd(c);
%                 newEntry = {cutFile fileHash s};
% 
%                 if gBntData{trialNum}.cutHash.isKey(curCell)
%                     curData = gBntData{trialNum}.cutHash(curCell);
%                     curData = cat(1, curData, newEntry);
%                     gBntData{trialNum}.cutHash(curCell) = curData;
%                 else
%                     gBntData{trialNum}.cutHash(curCell) = newEntry;
%                 end
%             end
%         end
%     end

    %% process EEG
    lfpInfo = [];
    if ~oldMatData
        lfpInfo = io.axona.AxonaLfpInfo(gBntData{trialNum});
    end

    gBntData{trialNum}.eegData = eegDataAll;
    gBntData{trialNum}.lfpInfo = lfpInfo;
end
