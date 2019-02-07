% Display matched triangles of two maps
%
function matchedTriangles(map1, map2, matchedPoints1, matchedPoints2, matchedTriangles1, matchedTriangles2)

    [offset1, offset2] = plot.matchedPoints(map1, map2, matchedPoints1, matchedPoints2);
    
    wasHeld = ishold; % store the state for 'hold' before changing it
    hold('on');

    for i = 1:length(matchedTriangles1)
        triangle1 = matchedTriangles1{i};
        triangle2 = matchedTriangles2{i};

        triangle1 = bsxfun(@plus, triangle1, offset1);
        triangle2 = bsxfun(@plus, triangle2, offset2);

        drawPolygon(triangle1, '-r', 'LineWidth', 2);
        drawPolygon(triangle2, '-r', 'LineWidth', 2);
    end

    if ~wasHeld
        hold('off'); % restore original states of hold
    end
end