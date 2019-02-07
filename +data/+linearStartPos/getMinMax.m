% getMinMax - Get minimum and maximum value of starting positions.
%
function [min, max] = getMinMax()
    global gBntData;

    if ~isfield(gBntData{1}, 'maxStartPos') || ~isfield(gBntData{1}, 'minStartPos')
        error('Could not found min/max information in the loaded data. Check your data');
    end

    min = gBntData{1}.minStartPos;
    max = gBntData{1}.maxStartPos;
end
