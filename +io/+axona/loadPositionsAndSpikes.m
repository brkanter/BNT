% Load position data for specified sessions
%
% Load position data from sessions contained in input argument. This is
% a wrapper around io.axona.getPos. The difference is that io.axona.getPos
% returns position only for one session, whereas loadPositionsAndSpikes works
% for several sessions.
%
%  USAGE
%     [positions, startIndices, spikes] = loadPositionsAndSpikes(sessions, sessionPath, tetrodes)
%     sessions          Cell vector of session names. Can be either full
%                       path or just the names. See below.
%     sessionPath       String. If not empty, then sessions should be just the plain
%                       session names. If empty, then sessions argument should
%                       contain the full path to sessions.
%     tetrodes          Vector of tetrode values.
%     positions         % Matrix Nx5, N - number of entries.
%                       columns:
%                       1 timestamps
%                       2 LED1 x values
%                       3 LED1 y values
%                       4 LED2 x values, also known as x2
%                       5 LED2 y values, also knows as y2
%     startIndices      Vector of indices that marks beginning of each session position data.
%                       See also helpers.initTrial.
%     spikes            Matrix Nx2, N - number of entries. 1 column stores timestamps, spike data.
%                       2 column contains tetrode number (integer).
%
function [positions, startIndices, spikes] = loadPositionsAndSpikes(sessions, sessionPath, tetrodes)

    numSessions = length(sessions);
    numSamples = 0;
    numSpikes = 0;

    startIndices = [];
    positions = [];

    for i = 1:numSessions
        if isempty(sessionPath)
            videoFile = strcat(sessions{i}, '.pos');
        else
            videoFile = fullfile(sessionPath, strcat(sessions{i}, '.pos'));
        end

        if exist(videoFile, 'file') == 0
            error('File %s doesn''t exists', videoFile);
        end

        fprintf('Loading video file "%s"...', videoFile);
        tpos = io.axona.getPos(videoFile);
        fprintf(' done\n');

        tposx = helpers.fixIsolatedData(tpos(:, bntConstants.PosX));
        tposy = helpers.fixIsolatedData(tpos(:, bntConstants.PosY));

        curSessionSamples = length(tposx);

        offset = 0;
        if i > 1
            startIndices(i) = numSamples + 1;
            offset = positions(end, bntConstants.PosT) + 0.02;
        else
            startIndices(i) = 1;
        end

        positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosT) = tpos(:, bntConstants.PosT) + offset;
        positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosX) = tposx;
        positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosY) = tposy;
        if size(tpos, 2) > 3
            tposx2 = helpers.fixIsolatedData(tpos(:, bntConstants.PosX2));
            tposy2 = helpers.fixIsolatedData(tpos(:, bntConstants.PosY2));

            positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosX2) = tposx2;
            positions(numSamples+1:numSamples+curSessionSamples, bntConstants.PosY2) = tposy2;
        end

        numSamples = numSamples + curSessionSamples;

        for t = 1:length(tetrodes)
            tetrode = tetrodes(t);

            if isempty(sessionPath)
                spikeFile = strcat(sessions{i}, sprintf('.%u', tetrode));
            else
                spikeFile = fullfile(sessionPath, strcat(sessions{i}, sprintf('.%u', tetrode)));
            end

            fprintf('Loading spike file "%s"...', spikeFile);
            spikeData = io.axona.importspikes(spikeFile);
            fprintf(' done\n');

            curNumSpikes = length(spikeData);

            spikes(numSpikes+1:numSpikes+curNumSpikes, 1) = spikeData + offset;
            spikes(numSpikes+1:numSpikes+curNumSpikes, 2) = tetrode;

            numSpikes = numSpikes + curNumSpikes;
        end
    end
end

