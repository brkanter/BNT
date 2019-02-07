classdef AngularHeadVelocityTester < matlab.unittest.TestCase
    methods(Test)

        function noArguments(testCase)
            testCase.verifyError(@()analyses.angularHeadVelocity(), 'MATLAB:minrhs');
        end

        function emptyHd(testCase)
            testCase.verifyError(@() analyses.angularHeadVelocity([]), ...
                'MATLAB:badsubscript');
        end

        function wrongHdDims(testCase)
            testCase.verifyError(@() analyses.angularHeadVelocity([1]), ...
                'BNT:args:length');

            testCase.verifyError(@() analyses.angularHeadVelocity([1 1 1 1 1]), ...
                'BNT:args:length');

            testCase.verifyError(@() analyses.angularHeadVelocity([1 1]), ...
                'BNT:args:length');
        end

        function constantVelocity(testCase)
            numSamples = 5;
            stepInDegrees = 15;
            hd(:, 1) = 0:0.02:0.02*(numSamples-1);
            hd(:, 2) = (0:numSamples-1) * stepInDegrees;

            velocity = stepInDegrees / 0.02;
            expV = ones(numSamples, 1) * -velocity;
            expV(end) = nan;

            v = analyses.angularHeadVelocity(hd);
            testCase.verifyEqual(round(v), expV);
        end
    end
end
