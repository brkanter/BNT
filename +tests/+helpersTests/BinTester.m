classdef BinTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()helpers.bin(), 'MATLAB:minrhs');
        end

        function onlyPosOutliers(testCase)
            x = 1:5;
            limits = [6 10];
            binWidth = 2;
            [bins, ~, edges] = helpers.bin(x, limits, binWidth);

            expEdges = [6. 8. 10];
            expBins = nan(1, length(x));
            testCase.verifyEqual(edges, expEdges, 'Edges are different');
            testCase.verifyEqual(bins, expBins, 'Bins are different');
        end

        function goodBinWidth(testCase)
            numSamples = 20;
            x = linspace(0, 10, numSamples);
            limits = [0 10];
            binWidth = 2;

            expNumBins = 5;
            expEdges = [0, 2. 4. 6. 8. 10];
            expBinCount = 4;

            [bins, ~, edges] = helpers.bin(x, limits, binWidth);
            numBins = length(edges) - 1;

            testCase.verifyEqual(numBins, expNumBins, 'Number of bins is different');
            testCase.verifyEqual(edges, expEdges, 'Edges are different');
            for i = 1:numBins
                binCount = length(find(bins == i));
                testCase.verifyEqual(binCount, expBinCount, sprintf('Wrong bin count for bin %u', i));
            end
        end

        function badBinWidth(testCase)
            numSamples = 20;
            x = linspace(0, 10, numSamples);
            limits = [0 10];
            binWidth = 3;

            expNumBins = 4;
            expEdges = [0, 3. 6. 9. 10];
            expBinCount = [6 6 6 2];

            [bins, numBins, edges] = helpers.bin(x, limits, binWidth);
            testCase.verifyEqual(numBins, expNumBins, 'Number of bins is different');
            testCase.verifyEqual(edges, expEdges, 'Edges are different');
            realBinCounts = zeros(1, numBins);
            for i = 1:numBins
                binCount = length(find(bins == i));
                realBinCounts(i) = binCount;
            end
            testCase.verifyEqual(realBinCounts, expBinCount, 'Wrong bin counts');
        end

        function negativePos(testCase)
            x = linspace(-5, 5, 10);
            limits = [-4 4];
            binWidth = 3;

            expEdges = [-4. -1. 2. 4];
            expNumBins = 3;
            expBinCount = [3 3 2];

            [bins, numBins, edges] = helpers.bin(x, limits, binWidth);
            realBinCounts = zeros(1, numBins);
            for i = 1:numBins
                binCount = length(find(bins == i));
                realBinCounts(i) = binCount;
            end
            testCase.verifyEqual(realBinCounts, expBinCount, 'Wrong bin counts');
            testCase.verifyEqual(numBins, expNumBins, 'Number of bins is different');
            testCase.verifyEqual(edges, expEdges, 'Edges are different');

            testCase.verifyEqual(length(find(isnan(bins))), 2);
        end
    end
end