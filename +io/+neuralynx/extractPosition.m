% Extract individual coordinates of each individual tracking diode.
%
% The red LEDs are assumed to be at the front, and the green LEDs are assumed
% to be at the back. If different colours are present, then this function
% will use the first two colours and assign their positions to frontX/frontY, backX/backY
% respectively.
%
%  USAGE
%   [fronX, frontY, backX, backY] = io.neuralynx.extractPosition(targets, tracking)
%   targets     See help of Nlx2MatVT.
%   tracking    Vector of presented tracking colours, length(tracking) == 7. Contents:
%               1 - Luminance, 3 in targets
%               2 - Pure Red, 7 in targets
%               3 - Pure Green, 8 in targets
%               4 - Pure Blue, 9 in targets
%               5 - Raw Red, 4 in targets
%               6 - Raw Green, 5 in targets
%               7 - Raw Blue, 6 in targets
%
%   frontX/Y, backX/Y   Vectors with position values
%
function [frontX, frontY, backX, backY] = extractPosition(targets, tracking)
    ind = find(tracking(2:end)); % do not use luminance
    tracking2targets = [7 8 9 4 5 6];

    frontInd = []; % Vector with one or two elements that correspond to colour index of fron LED.
                  % In case of two elements the respective positions are found by bit OR operation.
    backInd = [];
    
    onlyLuminance = all(tracking(2:end) == 0) && tracking(1) == 1;
    if onlyLuminance
        % this is a special case. We only have luminance data (could be infrared
        % LEDs). First target is always first LED, second target is always second LED.
        frontX = targets(:, 1, 1)';
        frontY = targets(:, 1, 2)';
        backX = targets(:, 2, 1)';
        backY = targets(:, 2, 2)';
        
        return;
    end

    if length(ind) < 2
        % Need at least two colours to get head direction
        frontX = NaN;
        frontY = NaN;
        backX = NaN;
        backY = NaN;
        return
    end
    
    if tracking(2)
        % pure red is present
        frontInd = 7;
    end
    if tracking(5)
        % raw red is present
        frontInd(end+1) = 4;
    end
    if isempty(frontInd)
        frontInd = tracking2targets(ind(1));
    end

    if tracking(3)
        % pure green is present
        backInd = 8;
    end
    if tracking(6)
        % raw green is present
        backInd(end+1) = 5;
    end
    if isempty(backInd)
        backInd = tracking2targets(ind(2));
    end

    % Number of samples in the data
    numSamp = size(targets, 1);

    % Allocate memory for the arrays
    frontX = zeros(1, numSamp);
    frontY = zeros(1, numSamp);
    backX = zeros(1, numSamp);
    backY = zeros(1, numSamp);

    for i = 1:numSamp
        % we need to find out non-zero elements in targets along 2nd dimension.
        % fronInd is either 1 or 2 elements, so we sum along the 3rd dimension.
        % This results in correct numbers in case length(fronInd) == 2, but in
        % case one element fronInd, this is also correct, since elements are not summarized.

        % Targets are sorted from largest (index 1) to smallest (index 50). We only take the
        % biggest element. The motivation behind this is that if we take mean/median of all
        % the targets, then we can be driven away by outliers.
        ind = find(sum(targets(i, :, frontInd), 3), 1);
        if ~isempty(ind)
            frontX(i) = (targets(i, ind, 1));
            frontY(i) = (targets(i, ind, 2));
        end

        ind = find(sum(targets(i, :, backInd), 3), 1);
        if ~isempty(ind)
            backX(i) = (targets(i, ind, 1));
            backY(i) = (targets(i, ind, 2));
        end
    end
end
