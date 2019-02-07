% Load NeuraLynx data
%
function loadData(trialNum)
    global gBntData;

    if length(gBntData) < trialNum
        error('Invalid argument');
    end

    if strcmpi(gBntData{trialNum}.system, bntConstants.RecSystem.Neuralynx) == false
        error('Invalid recording system');
    end

    numSessions = length(gBntData{trialNum}.sessions);
    numSamples = 0;
    timeOffset = nan(1, numSessions);
    numSpikes = 0;

    for s = 1:numSessions
        videoFile = fullfile(gBntData{trialNum}.sessions{s}, 'VT1.Nvt');
        if exist(videoFile, 'file') == 0
            videoFile = fullfile(gBntData{trialNum}.path, 'VT1.Nvt');
            if exist(videoFile, 'file') == 0
                error('File %s doesn''t exists', videoFile);
            end
        end

        fprintf('Loading video file "%s"...', videoFile);
        [pos, targets] = io.neuralynx.readVideoData(videoFile);
        fprintf(' done\n');

        % check that timestamps are monotonic
        negativeDiff = diff(pos(:, bntConstants.PosT)) <= 0;
        if any(negativeDiff)
            % sometimes timestamps are not monotonic. Replace bad timestamps
            % with an average of it's neighbours.
            original_Fq = 1/mean(diff(pos(:, bntConstants.PosT)));
            badInd = find(negativeDiff);
            newT = arrayfun(@(x) mean(pos([x x+2], bntConstants.PosT)), badInd);
            pos(badInd+1, bntConstants.PosT) = newT;
            new_Fq = 1/mean(diff(pos(:, bntConstants.PosT)));
            if abs(original_Fq - new_Fq) > 0.001
                warning('BNT:io:timestamps', ['Trial %u (%s) contains incorrect position tracking timestamps.\n' ...
                    'They are not monotonically increasing. I tried to recreate bad timestamps, but the overall sampling frequency'...
                    ' of recording has changed.\nPlease double check that everything looks fine\n'], trialNum, gBntData{trialNum}.sessions{s});
            end
        end

        pos = helpers.fixIsolatedData(pos);

        curSessionSamples = length(pos(:, bntConstants.PosT));
        offset = 0;
        if s > 1
            gBntData{trialNum}.startIndices(s) = numSamples + 1;
            % actually we do not need to make an (additional) offset if position
            % samples are not zero-based. But it's OK since we shift spikes as well.
            offset = gBntData{trialNum}.positions(end, bntConstants.PosT) + gBntData{trialNum}.sampleTime;
        else
            gBntData{trialNum}.startIndices(s) = 1;
        end
        timeOffset(s) = offset;

        gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosT) = pos(:, bntConstants.PosT) + offset;
        gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosX) = pos(:, bntConstants.PosX);
        gBntData{trialNum}.positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosY) = pos(:, bntConstants.PosY);
        gBntData{trialNum}.nlx.targets(:, numSamples+1:numSamples+curSessionSamples) = targets;
        % we do not have second LED positions at the moment

        numSamples = numSamples + curSessionSamples;
    end % loop over sessions

    tetrodes = unique(gBntData{trialNum}.units(:, 1), 'stable');
    for i = 1:length(tetrodes)
        tetrode = tetrodes(i);
        selected = gBntData{trialNum}.units(:, 1) == tetrode;
        cells = gBntData{trialNum}.units(selected, 2);
        cellLinearInd = helpers.tetrodeCellLinearIndex(gBntData{trialNum}.units(selected, 1), gBntData{trialNum}.units(selected, 2));

        for c = 1:length(cells)
            curCell = cellLinearInd(c);
            curData = gBntData{trialNum}.cutHash(curCell);

            for j = 1:size(curData, 1)
                cutFileName = curData{j, 1};
                sessionId = curData{j, 3};
                fprintf('Loading spike file "%s"...', cutFileName);
                spikeData = io.neuralynx.readMclustSpikeFile(cutFileName);
                fprintf('done\n');

                curNumSpikes = length(spikeData);
                gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 1) = spikeData + timeOffset(sessionId);
                gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 2) = tetrode;
                gBntData{trialNum}.spikes(numSpikes+1:numSpikes+curNumSpikes, 3) = cells(c);

                numSpikes = numSpikes + curNumSpikes;
            end
        end
    end

    if isempty(gBntData{trialNum}.spikes)
        [~, sessionName] = helpers.fileparts(gBntData{trialNum}.sessions{1});
        warning('BNT:noSpikes', 'There are no spikes for trial %u (%s), session %s', trialNum, gBntData{trialNum}.path, sessionName);
    else
        [minSpike, ~] = nanmin(gBntData{trialNum}.spikes(:, 1));
        if ~isempty(minSpike)
            minTime = nanmin(gBntData{trialNum}.positions(:, bntConstants.PosT));
            if minSpike < minTime
                toRemove = gBntData{trialNum}.spikes(:, 1) < minTime;

                warning('BNT:earlySpike', 'Data contains %u spike times that are earlier than the first position timestamp. These spikes will be removed.', length(find(toRemove)));
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

    % convert EEG signals
    gBntData{trialNum}.lfpInfo = io.neuralynx.NeuralynxLfpInfo(gBntData{trialNum});
end
