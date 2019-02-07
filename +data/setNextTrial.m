% Proceed to the next loaded trial
%
% Call this function to switch to the next trial. Next trial will become a current one.
% 'Current' trial is used when you retrieve data from internal storage.
%
%  SEE
%   See also data.getPositions
%
function setNextTrial()
    global gCurrentTrial;
    global gBntData;

    if gCurrentTrial < length(gBntData)
        gCurrentTrial = gCurrentTrial + 1;
    else
        fprintf('Reached last trial\n');
    end
end
