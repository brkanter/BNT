function sessionData = detectTetrodes(sessionData)
    if strcmpi(sessionData.system, bntConstants.RecSystem.Neuralynx) == false
        error('Invalid recording system');
    end
    
    possibleTetrodes = 1:16;
    tetrodes = [];
    if isdir(sessionData.sessions{1})
        workDir = sessionData.sessions{1};
    else
        workDir = sessionData.path;
    end
    
    for i = 1:length(possibleTetrodes)
        candidate = possibleTetrodes(i);
        tetrodeExists = false(2, 1);
        tFile = sprintf('%s/TT%u.ntt', workDir, candidate);
        tetrodeExists(1) = exist(tFile, 'file') ~= 0;
        
        tFile = sprintf('%s/Sc%u.ntt', workDir, candidate);
        tetrodeExists(2) = exist(tFile, 'file') ~= 0;
        
        if any(tetrodeExists)
            tetrodes = cat(1, tetrodes, candidate);
        end
    end
    if isempty(tetrodes)
        warning('BNT:tetrodeDetection', 'Tried to detect NeuraLynx tetrodes, but found none. Check your input file and data. You probably should not use Units autodetection.');
    else
        units = [tetrodes nan(length(tetrodes), 1)];
        sessionData.units = units;
    end    
end