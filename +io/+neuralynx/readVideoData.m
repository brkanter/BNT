% Reads position data from the video file (nvt) using the NeuraLynx import functions
%
% NeuraLynx stores average position of the LEDs. This function returns these average positions.
% However, positions of pixels abobe threshold are also stored by NeuraLynx. It is
% possible to decode these positions using targets. To get these positions in user-code
% one should call data.getPositions('average', 'off').
%
function [positions, targets] = readVideoData(videoFile)
    % Want  timestamps, posx, posy and targets
    fieldSelect = [1, 1, 1, 0, 1, 0];
    % Whether to get header from videoFile or not
    getHeader = 0;
    % Extract every record, see help of Nlx2MatVT for all possible modes
    extractMode = 1;

    % Get the data
    [post, posx, posy, targets] = io.neuralynx.Nlx2MatVT(videoFile, fieldSelect, getHeader, extractMode);

    % Convert timestamps from microseconds to seconds
    post = post/1e6;

    ind = find(posx == 0 & posy == 0);
    posx(ind) = NaN;
    posy(ind) = NaN;

    positions(:, bntConstants.PosT) = post;
    positions(:, bntConstants.PosX) = posx;
    positions(:, bntConstants.PosY) = posy;
end
