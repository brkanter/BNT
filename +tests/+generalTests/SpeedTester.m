classdef SpeedTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()general.speed(), 'BNT:numArgs');
        end

        function emptyArguments(testCase)
            testCase.verifyError(@()general.speed([]), 'BNT:arg');
        end

        function constant2D(testCase)
            t = 0:0.02:0.18;
            x = 1:length(t);
            y = x;

            v = general.speed([t', x', y']);

            v = round(v * 100);

            % test v is constant
            testCase.verifyEqual(length(unique(v)), 1);

            testCase.verifyEqual(length(v), length(t));
        end

        function linear(testCase)
            x = [2 3 4 5 6 7 8 9 8 7 6 5 5 5 5 4 3 3 3 3];
            lastT = 0.02 * (length(x) - 1);
            t = linspace(0, lastT, length(x));
            pos = [t', x'];

            v = general.speed(pos);

            numZeros = length(find(v == 0));

            [n, bin] = histc(x, unique(x));
            multiple = find(n > 1);

            testCase.verifyEqual(length(multiple), numZeros);
        end
    end
end