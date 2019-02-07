% Fix position timestamps for Axona system
%
% Timestamps could contain invalid values in the end of the recording session.
% Fix it by removing zeroes and sampling all data artificially.
function fixedPost = fixTimestamps(post)

    if post(end) ~= 0
        fixedPost = post;
        return;
    end

    first = post(1);
    N = length(post);

    % Find the number of zeros at the end of the file
    numZeros = 0;
    while 1
        if post(end-numZeros) == 0
            numZeros = numZeros + 1;
        else
            break;
        end
    end

    last = first + (N-1-numZeros) * 0.02;
    fixedPost = [first:0.02:last]';
end
