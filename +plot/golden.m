% Change the aspect ratio of a plot with a single parameter
%
% This function is from speed-score code of Emilio Kropff.
%
% n = 1 (or no value): aspect ratio is the golden ratio
function golden(ax, n)
    if ~exist('ax', 'var')
        ax = gca;
    end
    if ~exist('n', 'var')
        n = 1;
    end
    axLimits = axis;
    daspect(ax, [(axLimits(2)-axLimits(1)) (axLimits(4)-axLimits(3))*1.618/n 1]);
end