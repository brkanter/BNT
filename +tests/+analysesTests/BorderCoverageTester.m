classdef BorderCoverageTester < matlab.unittest.TestCase
    methods(Test)

        function nanMap(testCase)
            fields.map = NaN(20);

            coverage = analyses.borderCoverage(fields);

            testCase.verifyEqual(coverage, 0);

            fields(2).map = NaN(20);
            coverage = analyses.borderCoverage(fields);

            testCase.verifyEqual(coverage, 0);
        end

        function zeroLength(testCase)
            fields = struct();
            fields(1) = [];

            coverage = analyses.borderCoverage(fields);

            testCase.verifyEqual(coverage, 0);
        end

        function perfectCoverage(testCase)
            map = helpers.gauss2d([3 1], 150, [50 50]);
            map = map + helpers.gauss2d([37 1], 150, [50 50]);

            [fieldsMap, fields] = analyses.placefield(map, 'threshold', 0.3, 'minBins', 2);

            coverage = analyses.borderCoverage(fields);

            testCase.verifyEqual(coverage, 1);
        end

        function someCoverage(testCase)
            map = helpers.gauss2d([37 1], 150, [50 50]);

            [fieldsMap, fields] = analyses.placefield(map, 'threshold', 0.3, 'minBins', 2);

            coverage = analyses.borderCoverage(fields);

            testCase.verifyEqual(coverage, 0.6600);
        end
    end
end