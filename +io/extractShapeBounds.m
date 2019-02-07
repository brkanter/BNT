% Get arena dimensions from LEDs recorded in arena corners
%
% This function can be used to get arena inner and outer dimensions. One
% can take one or multiple LEDs, place them in arena corners and record.
% As a results, there will be point clusters. This function can fit different
% models (only square for now) to these clusters and output the dimensions of
% fitted models.
%
% NB! The function supports NeuraLynx only!
%
%  USAGE
%   [points, width, height] = io.extractShapeBounds(recording, arenaShape, <cameraParams>)
%   recording       Path to the folder where VT1.nvt file is located
%   arenaShape      Arena shape given as a value of the bntConstants.ArenaShape.
%   cameraParams    optional camera calibration parameters. If provided, then
%                   tracked points are additionally undistorted.
%   points          X/Y coordinates of fitted shape.
%   width           Width of fitted shape.
%   height          Height of fitted shape.
%
function [points, width, height] = extractShapeBounds(recording, arenaShape, cameraParams)
    if nargin < 3
        cameraParams = [];
    end
    pos = io.neuralynx.readVideoData(fullfile(recording, 'VT1.nvt'));
    goodInd = ~isnan(pos(:, 2));
    X = pos(goodInd, 2:3);
    if ~isempty(cameraParams)
        X = helpers.undistortPoints(X, cameraParams);
    end

    switch arenaShape
        case bntConstants.ArenaShape.Circle
            error('Not supported');
        case bntConstants.ArenaShape.Track
            error('Not supported');
        case bntConstants.ArenaShape.Box
            c_rect = general.fitSquare(X);
            height = max(c_rect(:, 2)) - min(c_rect(:, 2));
            width = max(c_rect(:, 1)) - min(c_rect(:, 1));
            if height < 50 || width < 50
                error('BNT:badArenaBound', 'Failed to extract arena bounds from provided information (%s).\nCheck that all LEDs were visible.', recording);
            end

        otherwise
            error('Unknown arena shape');
    end
    points = c_rect;
end