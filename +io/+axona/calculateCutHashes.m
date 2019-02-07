function sessionData = calculateCutHashes(sessionData)
    %% let's calculate cells cut hashes
    hashOpt.Method = 'MD5';
    hashOpt.Input = 'file';
    
    tetrodes = unique(sessionData.units(:, 1), 'stable');
    cutFiles = sessionData.cuts;
    
    for t = 1:length(tetrodes)
        tetrodeIndices = sessionData.units(:, 1) == tetrodes(t);
        tetrodeCells = sessionData.units(tetrodeIndices, :);

        cellLinearInd = helpers.tetrodeCellLinearIndex(tetrodeCells(:, 1), tetrodeCells(:, 2));
        for s = 1:size(cutFiles, 2)
            if isempty(cutFiles{t, s})
                continue;
            end
            cutFile = cutFiles{t, s};
            if exist(cutFile, 'file') == 0
                continue;
            end
            fileHash = DataHash(cutFile, hashOpt);
            for c = 1:length(cellLinearInd)
                curCell = cellLinearInd(c);
                newEntry = {cutFile fileHash s};

                if sessionData.cutHash.isKey(curCell)
                    curData = sessionData.cutHash(curCell);
                    curData = cat(1, curData, newEntry);
                    sessionData.cutHash(curCell) = curData;
                else
                    sessionData.cutHash(curCell) = newEntry;
                end
            end
        end
    end
end