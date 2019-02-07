% Return list of LFP channels assigned to current trial
%
function channels = getLfpChannels()
    global gBntData;
    global gCurrentTrial;

    channels = gBntData{gCurrentTrial}.lfpChannels;
end