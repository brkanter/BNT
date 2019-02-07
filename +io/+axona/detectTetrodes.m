function sessionData = detectTetrodes(sessionData)
    if helpers.isstring(sessionData.system, bntConstants.RecSystem.Axona, bntConstants.RecSystem.Virmen) == false
        error('Invalid recording system');
    end

    oldMatData = false;
    matPos = fullfile(sessionData.path, sprintf('%s_pos.mat', sessionData.basename));
    if exist(matPos, 'file') ~= 0
        tmp = load(matPos);

        if isfield(tmp, 'posx')
            oldMatData = true;
        end
    end

    if oldMatData
        error('BNT:unsupported', 'Loading old data from input files without Units keyword is not supported');
    end

    possibleTetrodes = 1:16;
    tetrodes = [];
    for i = 1:length(possibleTetrodes)
        candidate = possibleTetrodes(i);
        tFile = sprintf('%s.%u', sessionData.sessions{1}, candidate);
        if exist(tFile, 'file') == 0
            continue;
        end
        tetrodes = cat(1, tetrodes, candidate);
    end
    if ~isempty(tetrodes)
        units = [tetrodes nan(length(tetrodes), 1)];
        sessionData.units = units;
    end
end