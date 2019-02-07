% Set specific trial indicated by a number
%
% Set specific trial given by a number n.
%
function setTrial(n)
    global gBntData;
    global gCurrentTrial;

    if n < 0
        error('Can not set negative trial');
    end

    if n > length(gBntData)
        error('Can not set trial to %d, there are not enough trials loaded', n);
    end

    gCurrentTrial = n;
end
