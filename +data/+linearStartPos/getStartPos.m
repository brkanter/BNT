function sp = getStartPos()
    global gBntData;
    global gCurrentTrial;

    sp = gBntData{gCurrentTrial}.startPos;
end
