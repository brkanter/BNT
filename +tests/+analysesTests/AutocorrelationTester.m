classdef AutocorrelationTester < tests.TestCaseWithData
    methods
        function this = AutocorrelationTester()
            this.copyRecordings = false;
        end
    end

    methods(Test)
        function noArgs(testCase)
            testCase.verifyError(@()analyses.autocorrelation(), 'MATLAB:minrhs');
        end

        function emptyArg(testCase)
            testCase.verifyEmpty(analyses.autocorrelation([]));
        end

        function vectorArg(testCase)
            expV = ones(1, 9);
            expV([1 end]) = 0;

            aCorr = analyses.autocorrelation(1:5);
            testCase.verifyEqual(aCorr, expV);

            aCorr = analyses.autocorrelation((1:5)');
            testCase.verifyEqual(aCorr, expV');
        end

        function nanMap(testCase)
            map = NaN(20);
            expV = zeros(35); % 20 + 0.8*20 - 1

            aCorr = analyses.autocorrelation(map);

            testCase.verifyEqual(aCorr, expV);
        end

        function allZerosMap(testCase)
            map = zeros(20);
            expV = zeros(35); % 20 + 0.8*20 - 1

            aCorr = analyses.autocorrelation(map);

            testCase.verifyEqual(aCorr, expV);
        end

        function correctSize(testCase)
            map = magic(20);
            sideLength = 20 + 0.8*20 - 1;
            expSize = [sideLength sideLength];

            aCorr = analyses.autocorrelation(map);
            testCase.verifyEqual(size(aCorr), expSize);

            %%
            map = magic(21);
            sideLength = round(21 + 0.8*21 - 1);
            expSize = [sideLength sideLength];

            aCorr = analyses.autocorrelation(map);
            testCase.verifyEqual(size(aCorr), expSize);

            %%
            map = randn(10, 20);
            map(map < 0) = map(map < 0) * -1;

            sideLength1 = round(10 + 0.8*10 - 1);
            sideLength2 = round(20 + 0.8*20 - 1);
            expSize = [sideLength1 sideLength2];

            aCorr = analyses.autocorrelation(map);
            testCase.verifyEqual(size(aCorr), expSize);
        end

        function realMap(testCase)
            dataFile = fullfile(testCase.DataFolder, 'aCorr.mat'); % aCorr and map variables
            load(dataFile);
            expV = aCorr; %#ok<NODEF>

            aCorr = analyses.autocorrelation(map.z);
            testCase.verifyEqual(aCorr, expV, 'AbsTol', 0.005);
        end
    end
end