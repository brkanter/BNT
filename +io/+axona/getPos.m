% Read Axona position samples
%
% This function reads position samples from Axona .pos file and outputs
% it as individual X/Y coordinates for two LEDs. The functions handles
% different tracking modes and adjusts data for the limits of the tracking
% window. If more thatn 95 % of samples are untracked, then empty arrays
% are returned.
%
%  USAGE
%   positions = io.axona.getPos(filename)
%   filename        Path to .pos data file.
%   positions       Nx3 or Nx5 matrix in form [t x y], [t x y x2 y2], where X/Y
%                   are coordinates of first/second LED.
%
function positions = getPos(posfile)

    [post, coordinates, fileHeader] = io.axona.importvideotracker(posfile);

    % Check the number of columns in the tracker
    N = size(coordinates, 2);

    if N == 4
        % some old recordings contain zeros in the end of file
        badCoordinates = coordinates(:, 1) == 0 & coordinates(:, 2) == 0 ...
            & coordinates(:, 1) == 0 & coordinates(:, 3) == 0;
        post(badCoordinates) = [];
        coordinates(badCoordinates, :) = [];
    end

    if N > 4
        % Get the number of valid samples for the 4 tracking colours
        colours = zeros(4, 1);
        numRed = sum(~isnan(coordinates(:, 1)));
        if numRed > 0
            colours(1) = 1;
        end
        numGreen = sum(~isnan(coordinates(:, 3)));
        if numGreen > 0
            colours(2) = 1;
        end
        numBlue = sum(~isnan(coordinates(:, 5)));
        if numBlue > 0
            colours(3) = 1;
        end
        numBoW = sum(~isnan(coordinates(:, 7)));
        if numBoW > 0
            colours(4) = 1;
        end

        if sum(colours) == 0
            disp('Error: No valid position samples in the position file')
            posx = [];
            posy = [];
            posx2 = [];
            posy2 = [];
            return
        end

        if sum(colours) == 1
            % 1 tracking colour used for tracking
            if colours(1) == 1
                posx = coordinates(:, 1) + fileHeader.window_min_x;
                posy = coordinates(:, 2) + fileHeader.window_min_y;
            end
            if colours(2) == 1
                posx = coordinates(:, 3) + fileHeader.window_min_x;
                posy = coordinates(:, 4) + fileHeader.window_min_y;
            end
            if colours(3) == 1
                posx = coordinates(:, 5) + fileHeader.window_min_x;
                posy = coordinates(:, 6) + fileHeader.window_min_y;
            end
            if colours(4) == 1
                posx = coordinates(:, 7) + fileHeader.window_min_x;
                posy = coordinates(:, 8) + fileHeader.window_min_y;
            end
            % Set the length of the arrays according to the number of timestamps
            numPos = length(posx);
            numPost = length(post);
            if numPos ~= numPost
                posx = posx(1:numPost);
                posy = posy(1:numPost);
            end

            % Make empty arrays for the second set of coordinates to have
            % something to return
            posx2 = [];
            posy2 = [];
        else
            % More than 1 tracking colour used for tracking.
            if colours(1) == 1
                posx = coordinates(:, 1) + fileHeader.window_min_x;
                posy = coordinates(:, 2) + fileHeader.window_min_y;
                if colours(2) == 1
                    posx2 = coordinates(:, 3) + fileHeader.window_min_x;
                    posy2 = coordinates(:, 4) + fileHeader.window_min_y;
                elseif colours(3) == 1
                    posx2 = coordinates(:, 5) + fileHeader.window_min_x;
                    posy2 = coordinates(:, 6) + fileHeader.window_min_y;
                elseif colours(4) == 1
                    posx2 = coordinates(:, 7) + fileHeader.window_min_x;
                    posy2 = coordinates(:, 8) + fileHeader.window_min_y;
                end
            elseif colours(2) == 1
                posx = coordinates(:, 3) + fileHeader.window_min_x;
                posy = coordinates(:, 4) + fileHeader.window_min_y;
                if colours(3) == 1
                    posx2 = coordinates(:, 5) + fileHeader.window_min_x;
                    posy2 = coordinates(:, 6) + fileHeader.window_min_y;
                elseif colours(4) == 1
                    posx2 = coordinates(:, 7) + fileHeader.window_min_x;
                    posy2 = coordinates(:, 8) + fileHeader.window_min_y;
                end
            elseif colours(3) == 1
                posx = coordinates(:, 5) + fileHeader.window_min_x;
                posy = coordinates(:, 6) + fileHeader.window_min_y;
                posx2 = coordinates(:, 7) + fileHeader.window_min_x;
                posy2 = coordinates(:, 8) + fileHeader.window_min_y;
            end
        end
    end
    if N == 4 % 2-spot recording
        % First set of coordinates
        posx = coordinates(:, 1) + fileHeader.window_min_x;
        posy = coordinates(:, 2) + fileHeader.window_min_y;
        % Second set of coordinates
        posx2 = coordinates(:, 3) + fileHeader.window_min_x;
        posy2 = coordinates(:, 4) + fileHeader.window_min_y;

%         % swap LEDs
%         led_pos(:, 1, 1) = posx;
%         led_pos(:, 1, 2) = posy;
%         led_pos(:, 2, 1) = posx2;
%         led_pos(:, 2, 2) = posy2;
%         led_pix = [tracker(:).numpix1; tracker(:).numpix2]';
%
%         swap_list = led_swap_filter(led_pos, led_pix);
%         c = [posx(swap_list) posy(swap_list)];
%         posx(swap_list) = posx2(swap_list);
%         posy(swap_list) = posy2(swap_list);
%         posx2(swap_list) = c(:, 1);
%         posy2(swap_list) = c(:, 2);

        % Set the length of the arrays according to the number of timestamps
        numSamp = length(post);
        posx = posx(1:numSamp);
        posy = posy(1:numSamp);
        posx2 = posx2(1:numSamp);
        posy2 = posy2(1:numSamp);
    end

    % Make sure timestamps start at zero
    post = post - post(1);

    P = length(post);
    numNans = sum(isnan(posx2));
    if numNans > 0.95 * P
        posx2 = [];
        posy2 = [];
    end

    positions = [post posx posy posx2 posy2];
end
