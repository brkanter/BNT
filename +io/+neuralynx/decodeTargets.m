% Decode target data
%

% Note: taken from Raymond's scripts as is.
function [dTargets, trackingColour] = decodeTargets(targets)
    % Number of samples
    numSamp = size(targets,2);

    % Allocate memory to the array. 9 fields per sample: X-coord, Y-coord and
    % 7 colour flag.
    % Colour flag: 3=luminance, 4=rawRed, 5=rawGreen, 6=rawBlue, 7=pureRed,
    % 8=pureGreen, 9=pureBlue.
    dTargets = int16(zeros(numSamp,50,9));

    for ii = 1:numSamp
        for jj = 1:50
            bitField = bitget(targets(jj,ii),1:32);
            if bitField(13)% Raw blue
                % Set the x-coord to the target
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                % Set the y-coord to the target
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,6) = 1;
            end
            if bitField(14) % Raw green
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,5) = 1;
            end
            if bitField(15) % Raw red
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,4) = 1;
            end
            if bitField(16) % Luminance
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,3) = 1;
            end
            if bitField(29) % Pure blue
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,9) = 1;
            end
            if bitField(30) % Puregreen
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,8) = 1;
            end
            if bitField(31) % Pure red
                ind = find(bitField(1:12));
                dTargets(ii,jj,1) = sum(2.^(ind-1));
                ind = find(bitField(17:28));
                dTargets(ii,jj,2) = sum(2.^(ind-1));
                dTargets(ii,jj,7) = 1;
            end
        end
    end

    % Find out what colours were used in the tracking
    trackingColour = zeros(1,7);
    if ~isempty(find(dTargets(:,:,3),1)) % Luminance
        trackingColour(1) = 1;
    end
    if ~isempty(find(dTargets(:,:,7),1)) % Pure Red
        trackingColour(2) = 1;
    end
    if ~isempty(find(dTargets(:,:,8),1)) % Pure Green
        trackingColour(3) = 1;
    end
    if ~isempty(find(dTargets(:,:,9),1)) % Pure Blue
        trackingColour(4) = 1;
    end
    if ~isempty(find(dTargets(:,:,4),1)) % Raw Red
        trackingColour(5) = 1;
    end
    if ~isempty(find(dTargets(:,:,5),1)) % Raw Green
        trackingColour(6) = 1;
    end
    if ~isempty(find(dTargets(:,:,6),1)) % Raw Blue
        trackingColour(7) = 1;
    end
end
