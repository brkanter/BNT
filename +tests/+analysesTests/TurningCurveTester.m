classdef TurningCurveTester < matlab.unittest.TestCase
    methods(Access=public)
        function headDir = prepareRoundTrajectory(~, binWidthDeg, samplesPerBin)
            % prepare position samples that result in a histogram with equal bins

            if nargin < 3
                samplesPerBin = 3;
            end

            numBins = ceil(360/binWidthDeg);
            headDir = zeros(numBins * samplesPerBin, 1);
            headDirInd = 1;
            for i = 1:numBins
                rangeStart = (i-1)*binWidthDeg;
                rangeEnd = rangeStart + binWidthDeg;

                r = rangeStart + (rangeEnd - rangeStart) .* rand(1, samplesPerBin);
                headDir(headDirInd:headDirInd+samplesPerBin-1) = r;
                headDirInd = headDirInd + samplesPerBin;
            end
        end
    end

    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.turningCurve(), 'MATLAB:minrhs');
        end

        function mapWithValues(testCase)
%             headDirRad = deg2rad([10 11 12 13 17 20 21 25]);
%             spkRad = deg2rad([14 15 16 24 30 31]);

            binWidth = 45;
            numBins = ceil(360 / binWidth);
            headDir = (testCase.prepareRoundTrajectory(binWidth, 10));
            % we have the following intervals with corresponding spike counts:
            % 1 - 45 deg        , 6: [1 3 12 15 6 7]
            % 45 - 90 deg       , 2: [67 78]
            % 90 - 135 deg      , 1: [90]
            % 135 - 180 deg     , 1: [136]
            % 180 - 225 deg     , 1: [181]
            % 225 - 270 deg     , 2: [243 245]
            % 270 - 315 deg     , 1: [310]
            % 315 - 360 deg     , 1: [350]
            spkDir = ([1 3 12 15 6 7 67 78 91 136 181 243 245 310 350]); % hist is [6, 2, 1, 1, 1, 2, 1, 1]

            x = (0:numBins-1) * binWidth + 180/numBins;

            expTrajectory = ones(numBins, 1) * 10; % see headDir
            expMapAxis = x';
            expTc = [15 5 2.5 2.5 2.5 5 2.5 2.5]'; % hist of spkDir ./ 0.4. 0.4 because hist of headDir gives these
                                                  % values

            tc = analyses.turningCurve(spkDir, headDir, 0.04, 'smooth', 0, 'binWidth', binWidth);

            testCase.verifyEqual(tc(:, 1), expMapAxis, 'RelTol', 0.0001, 'Map axis is wrong');
            testCase.verifyEqual(tc(:, 2), expTc, 'RelTol', 0.0001, 'Turning curve values are wrong');
            testCase.verifyEqual(tc(:, 3), expTrajectory, 'RelTol', 0.0001, 'Trajectory values are wrong');
        end
        
        function highDensityMap(testCase)
            % let's try to simulate a map with somewhat more real values and binning
            binWidth = 3;
            numBins = ceil(360 / binWidth);
            headDir = (testCase.prepareRoundTrajectory(binWidth, 20));
            x = (0:numBins-1) * binWidth + 180/numBins;
            spkDir = repmat(1:360, 1, 2); % constant firing around the circle, each bin contains 6 spikes
            spkDir = [spkDir repmat(125:135, 1, 3) 130:145 138:142 330:350];
            
            expMapAxis = x';
            expTc = ones(numBins, 1) * 5; % 5 = 6 spikes per bin / (20 * 0.06). 0.06 sampling time. 20 number of position samples per bin.
            expTc(42:49) = [7.5 12.5 14.1667 15. 10. 10. 9.1667 6.6667];
            expTc(111:117) = 7.5;

            tc = analyses.turningCurve(spkDir, headDir, 0.06, 'smooth', 0, 'binWidth', binWidth);

            testCase.verifyEqual(tc(:, 1), expMapAxis, 'RelTol', 0.0001, 'Map axis is wrong');
            testCase.verifyEqual(tc(:, 2), expTc, 'RelTol', 0.0001, 'Turning curve values are wrong');
        end
        
        function highDensitySmoothed(testCase)
            binWidth = 3;
            numBins = ceil(360 / binWidth);
            headDir = (testCase.prepareRoundTrajectory(binWidth, 20));
            x = (0:numBins-1) * binWidth + 180/numBins;
            spkDir = repmat(1:360, 1, 2); % constant firing around the circle, each bin contains 6 spikes
            spkDir = [spkDir repmat(125:135, 1, 3) 130:145 138:142 330:350];
            
            expMapAxis = x';
            expTc = ones(numBins, 1) * 5; % 5 = 6 spikes per bin / (20 * 0.06). 0.06 sampling time. 20 number of position samples per bin.
            expTc(38:53) = [5.0003 5.0121 5.1695 6.0518 8.352 11.3778 13.3191 13.1220 11.3851 9.8843 8.5909 6.9666 5.6511 5.1091 5.008 5.0002];
            expTc(107:120) = [5.0003 5.0114 5.1464 5.7513 6.7487 7.3536 7.4886 7.4993 7.4886 7.3536 6.7487 5.7513 5.1464 5.0118];

            tc = analyses.turningCurve(spkDir, headDir, 0.06, 'smooth', 1, 'binWidth', binWidth);

            testCase.verifyEqual(tc(:, 1), expMapAxis, 'RelTol', 0.0001, 'Map axis is wrong');
            testCase.verifyEqual(tc(:, 2), expTc, 'RelTol', 0.0001, 'Turning curve values are wrong');
        end

    end
end