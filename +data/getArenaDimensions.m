% Get recording arena dimensions for a current trial.
%
% Dimensions are provided by a user through input file, or calculated
% from actual data. Note that if calculated from data, dimensions won't
% be accurate. An animal seldom goes right to the boundaries of the arena.
% So if you have a linear track of 100 cm, then calculated length could be
% 97 cm.
%
%  USAGE
%   [xDim yDim] = data.getArenaDimensions();
%   xDim    Length of the arena in x dimension.
%   yDim    Length of the arena in y dimension.
%

% Copyright (c) 2013, Vadim Frolov <vadim.frolov@ntnu.no>
%
function [xDim, yDim] = getArenaDimensions()
    global gBntData;
    global gCurrentTrial;

    if exist('gBntData', 'var') == 0 || isempty(gBntData)
        error('You need to initialize BNT before calling this function.');
    end

    if isfield(gBntData{gCurrentTrial}.extraInfo, 'shape')
        % TODO: handle different arena shapes!

        switch gBntData{gCurrentTrial}.extraInfo.shape.type
            case bntConstants.ArenaShape.Box
                % box

                if length(gBntData{gCurrentTrial}.extraInfo.shape.value) == 1
                    xDim = gBntData{gCurrentTrial}.extraInfo.shape.value;
                    yDim = xDim;
                else
                    xDim = gBntData{gCurrentTrial}.extraInfo.shape.value(1);
                    yDim = gBntData{gCurrentTrial}.extraInfo.shape.value(2);
                end

            case bntConstants.ArenaShape.Track
                xDim = gBntData{gCurrentTrial}.extraInfo.shape.value;
                yDim = 0;

            otherwise
                if length(gBntData{gCurrentTrial}.extraInfo.shape.value) == 1
                    xDim = gBntData{gCurrentTrial}.extraInfo.shape.value;
                    yDim = xDim;
                else
                    xDim = gBntData{gCurrentTrial}.extraInfo.shape.value(1);
                    yDim = gBntData{gCurrentTrial}.extraInfo.shape.value(2);
                end
        end
    else
        if ~isfield(gBntData{gCurrentTrial}, 'positions')
            % positions are loaded lazily, so they might be not loaded yet.
            pos = data.getPositions();
        end
        positions = gBntData{gCurrentTrial}.positions;

        minX = nanmin(positions(:, bntConstants.PosX));
        maxX = nanmax(positions(:, bntConstants.PosX));
        minY = nanmin(positions(:, bntConstants.PosY));
        maxY = nanmax(positions(:, bntConstants.PosY));
        xDim = maxX - minX;
        yDim = maxY - minY;
    end
end
