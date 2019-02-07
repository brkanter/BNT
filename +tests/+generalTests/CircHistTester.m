classdef CircHistTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()general.circHist(), 'MATLAB:minrhs');
        end

        function simpleTest(testCase)
            spkRad = ([14 15 16 24 30 31]);
            binWidthRad = (3);

            expectedSpikes = zeros(1, 120);
            expectedSpikes(5:11) = [1 2 0 0 1 0 2];

            n = general.circHist(spkRad, binWidthRad);
            testCase.verifyEqual(n, expectedSpikes);
        end

        function above360(testCase)
            values = (360 + [14 15 16 24 30 31]);
            binWidthRad = (3);

            expectedSpikes = [1 2 0 0 1 0 2];

            n = general.circHist(values, binWidthRad);
            testCase.verifyEqual(n(5:11), expectedSpikes);
        end

        function emptyData(testCase)
            n = general.circHist([], (5));

            testCase.verifyTrue(all(n == 0));
        end

        function edges(testCase)
            values = ([0 1 2 3 25 26 359 360]);
            binWidthRad = (3);

            expected = zeros(1, 120);
            expected(1) = 4; % here go values 0 1 2 360
            expected(2) = 1; % value 3
            expected(9) = 2; % values 25 26
            expected(120) = 1; % value 359

            n = general.circHist(values, binWidthRad);

            testCase.verifyEqual(n, expected);
        end

        function precision(testCase)
            values = ([15. 14. 12. 14.999999999999998]);
            binWidthRad = (3);
            n = general.circHist(values, binWidthRad);
            n = n(4:6);

            expected = [0 3 1];

            testCase.verifyEqual(n, expected);
        end

        function towardsLeftEnd(testCase)
            values = ([15. 14. 12. 14.9999999999998]);
            binWidthRad = (3);
            n = general.circHist(values, binWidthRad);
            n = n(4:6);

            expected = [0 3 1];

            testCase.verifyEqual(n, expected);
        end

        function boundary(testCase)
            values = [1. 3. 6. 6.1];
            binWidth = (3);
            n = general.circHist(values, binWidth);
            n = n(1:4);

            expected = [1 1 2 0];

            testCase.verifyEqual(n, expected);
        end

        function negative(testCase)
            values = ([1 4 -4 -5 -3 -70]);
            binWidth = (4);

            n = general.circHist(values, binWidth);
            testCase.verifyEqual(n(1:3), [1 1 0]); % [1 4]
            testCase.verifyEqual(n(88:end), [0 1 2]); % [-5 -4 -3]
            testCase.verifyEqual(n(72:74), [0 1 0]); % [-70]
        end
    end
end