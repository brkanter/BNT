function [positions, kalmanResults] = doKalmanProcessing(positions, sessIdx)
    global gBntData;
    global gCurrentTrial;

    if nargin < 2
        sessIdx = 1;
    end

    kalmanFile = helpers.uniqueFilename(gBntData{gCurrentTrial}, 'pos');
    % here is a small hack because the knowledge of kalmanFile is used
    [filePath, fileName] = helpers.fileparts(kalmanFile);
    id = strfind(fileName, '_');
    fileName(id:end) = [];
    kalmanFile = fullfile(filePath, sprintf('%s_kalman%02u.mat', fileName, sessIdx));

    Fs = gBntData{gCurrentTrial}.videoSamplingRate;

    % if exist(kalmanFile, 'file')
    %     delete(kalmanFile);
    % end

    if exist(kalmanFile, 'file')
        load(kalmanFile); % structure kalmanResults
        positions(:, bntConstants.PosX) = kalmanResults.x;
        positions(:, bntConstants.PosY) = kalmanResults.y;
    else
        % Taken from Emilio's code as it was there.
        kalmanParameters = [50 .02 .01 100 2 .1 10];

        kalmanR = kalmanParameters(4) * eye(2);
        kalmanQ = zeros(6);
        kalmanQ(1, 1) = kalmanParameters(1);
        kalmanQ(2, 2) = kalmanParameters(2);
        kalmanQ(3, 3) = kalmanParameters(3);
        kalmanQ(4, 4) = kalmanParameters(1);
        kalmanQ(5, 5) = kalmanParameters(2);
        kalmanQ(6, 6) = kalmanParameters(3);

        out = kalman2D(positions(:, [bntConstants.PosX bntConstants.PosY])', kalmanQ, kalmanR);
        positions(:, bntConstants.PosX) = out(1, :);
        positions(:, bntConstants.PosY) = out(4, :);

        kalmanResults.t = positions(:, 1);
        kalmanResults.x = out(1, :)';
        kalmanResults.y = out(4, :)';
        kalmanResults.v_x = Fs * out(2, :)';
        kalmanResults.v_y = Fs * out(5, :)';
        kalmanResults.a_x = Fs^2 * out(3, :)';
        kalmanResults.a_y = Fs^2 * out(6, :)';
        kalmanResults.a = sqrt(kalmanResults.a_x.^2 + kalmanResults.a_y.^2);
        kalmanResults.v = sqrt(kalmanResults.v_x.^2 + kalmanResults.v_y.^2);

        save(kalmanFile, 'kalmanResults');
    end
end