function [offset1, offset2] = matchedPoints(map1, map2, matchedPoints1, matchedPoints2, drawLines)
    if isempty(matchedPoints1) || isempty(matchedPoints2)
        return;
    end
    if nargin < 5
        drawLines = true;
    end
    
    paddedSize = [max(size(map1, 1), size(map2, 1)), max(size(map1, 2), size(map2, 2))];
    map1_pad = [paddedSize(1) - size(map1, 1), paddedSize(2) - size(map1, 2)];
    map2_pad = [paddedSize(1) - size(map2, 1), paddedSize(2) - size(map2, 2)];
    I1pre = round(map1_pad/2);
    I2pre = round(map2_pad/2);

    I1 = padarray(map1, I1pre, 0, 'pre');
    I2 = padarray(map2, I2pre, 0, 'pre');
    I1 = padarray(I1, map1_pad-I1pre, 0, 'post');
    I2 = padarray(I2, map2_pad-I2pre, 0, 'post');

    imgOverlay = imfuse(I1, I2, 'montage');
    plot.colorMap(imgOverlay);

    wasHeld = ishold; % store the state for 'hold' before changing it
    hold('on');

    offset1 = fliplr(I1pre);
    offset2 = fliplr(I2pre);
    offset2 = offset2 + fliplr([0 size(I1, 2)]);

    pts1 = bsxfun(@plus, matchedPoints1, offset1);
    pts2 = bsxfun(@plus, matchedPoints2, offset2);

    plot(pts1(:, 1), pts1(:, 2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    plot(pts2(:, 1), pts2(:, 2), 'g+', 'MarkerSize', 10, 'LineWidth', 2);

    if drawLines
        lineX = [pts1(:, 1)'; pts2(:, 1)'];
        numPts = numel(lineX);
        lineX = [lineX; NaN(1, numPts/2)];

        lineY = [pts1(:,2)'; pts2(:,2)'];
        lineY = [lineY; NaN(1, numPts/2)];

        plot(lineX(:), lineY(:), 'y-', 'LineWidth', 2); % line
    end

    if ~wasHeld
        hold('off'); % restore original states of hold
    end
end