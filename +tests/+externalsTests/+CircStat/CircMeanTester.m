classdef CircMeanTester < matlab.unittest.TestCase
% Test calculation of mean angle.
% Tests are performed based on examples in book Biostatistical Analysis, 5 ed.
% by Jar.

    methods(Test)
        function alphaData(testCase)
            % test calculation based on population of angles
            % Example 26.2 from Biostatistical Analysis
            alpha = deg2rad([45 55 81 96 110 117 132 154])';

            expRes = 98.987751950396458;
            meanAngle = rad2deg(circ_mean(alpha));

            testCase.verifyEqual(meanAngle, expRes);
        end

        function grouppedData(testCase)
            % Example 26.5 from Boistatistical Analysis

            % data is distributed in 12 bins, bin width is 30 degrees
            freqValues = [0 6 9 13 15 22 17 12 8 3 0 0]';
            binWidth = 30;
            numBins = ceil(360/binWidth);

            alpha = (0:numBins-1) * binWidth + 180/numBins;
            alpha = deg2rad(alpha');

            meanAngle = ceil(rad2deg(circ_mean(alpha, freqValues)));
            testCase.verifyEqual(meanAngle, 162);
        end
    end
end