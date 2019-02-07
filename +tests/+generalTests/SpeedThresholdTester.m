classdef SpeedThresholdTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()general.speedThreshold(), 'BNT:numArgs');
        end

        function emptyArguments(testCase)
            testCase.verifyError(@()general.speed([]), 'BNT:arg');
        end

        function lowSpeed(testCase)
            minSpeed = 2.5;
            minDistance = minSpeed * 0.02;

            sitX = minDistance .* rand(10, 1);
            sitY = minDistance .* rand(10, 1);

            xPoints = [2 3 4 5 6 7 8 9 8 7 6 5 5 5 5 4 3 3 3 3];
            yPoints = [1 2 3 4 5 6 7 8 8 8 8 8 7 6 5 5 5 6 7 8];

            x = [sitX' xPoints];
            y = [sitY' yPoints];

            lastT = 0.02 * (length(x) - 1);
            t = linspace(0, lastT, length(x));
            pos = [t', x', y'];

            % spikes = [0.003 0.11 0.13 0.21 0.26 0.48 0.52 0.58]';

            selected = general.speedThreshold(pos, minSpeed, 100);

            testCase.verifyEqual(selected', 1:9);
        end
    end
end