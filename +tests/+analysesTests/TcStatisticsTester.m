classdef TcStatisticsTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.tcStatistics(), 'MATLAB:minrhs');
        end

        function emptyTc(testCase)
            tcStat = analyses.tcStatistics([], []);
            c = struct2cell(tcStat);
            allValues = cell2mat(c);

            testCase.verifyTrue(all(isnan(allValues)));
        end

        function values(testCase)
            freqValues = [0 6 9 13 15 22 17 12 8 3 0 0]';
            binWidth = 30;
            numBins = ceil(360/binWidth);
            alpha = (0:numBins-1) * binWidth + 180/numBins;

            tc(:, 1) = alpha;
            tc(:, 2) = freqValues;
            percentile = 50;

            expR = 0.5506;
            expMean = 162;
            expStd = 0.9480;
            [expPeakRate, peakInd] = max(freqValues);
            expMeanRate = mean(freqValues);
            expPeakDirection = alpha(peakInd);

            tcStat = analyses.tcStatistics(tc, binWidth, percentile);

            testCase.verifyEqual(roundn(tcStat.r, -4), expR);
            testCase.verifyEqual(round(tcStat.mean), expMean);
            testCase.verifyEqual(roundn(tcStat.std, -4), expStd);
            testCase.verifyEqual(tcStat.peakRate, expPeakRate);
            testCase.verifyEqual(tcStat.peakDirection, expPeakDirection);
            testCase.verifyEqual(tcStat.meanRate, expMeanRate);
        end

        function valuesWithNan(testCase)
            freqValues = [0 nan 9 13 15 22 17 12 8 3 0 0]';
            binWidth = 30;
            numBins = ceil(360/binWidth);
            alpha = (0:numBins-1) * binWidth + 180/numBins;

            tc(:, 1) = alpha;
            tc(:, 2) = freqValues;

            percentile = 50;

            expR = 0.6135;
            expMean = 167;
            expStd = 0.8792;
            [expPeakRate, peakInd] = max(freqValues);
            expMeanRate = nanmean(freqValues);
            expPeakDirection = alpha(peakInd);

            tcStat = analyses.tcStatistics(tc, binWidth, percentile);

            testCase.verifyEqual(roundn(tcStat.r, -4), expR);
            testCase.verifyEqual(round(tcStat.mean), expMean);
            testCase.verifyEqual(roundn(tcStat.std, -4), expStd);
            testCase.verifyEqual(tcStat.peakRate, expPeakRate);
            testCase.verifyEqual(tcStat.peakDirection, expPeakDirection);
            testCase.verifyEqual(tcStat.meanRate, expMeanRate);
        end
    end
end