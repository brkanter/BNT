function n = totalNumCells()
    global gCurrentTrial;
    curTrial = gCurrentTrial;

    n = 0;
    for i = 1:data.numTrials
        data.setTrial(i);
        n = n + size(data.getCells(), 1);
    end

    data.setTrial(curTrial);
end