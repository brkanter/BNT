classdef BorderCoverageCircularTester < matlab.unittest.TestCase
    methods(Test)

        function nanMap(testCase)
            fieldsMap = NaN(20, 360);
            coverage = analyses.borderCoverageCircular(fieldsMap);
            testCase.verifyEqual(coverage, 0);
        end

        function emptyMap(testCase)
            fieldsMap = [];
            coverage = analyses.borderCoverage(fieldsMap);
            testCase.verifyEqual(coverage, 0);
        end

        function unsupportedSize(testCase)
            fieldsMap = zeros(5, 400);
            testCase.verifyError(@() analyses.borderCoverageCircular(fieldsMap), 'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function invalidWalls(testCase)
            testCase.verifyError(@() analyses.borderCoverageCircular(zeros(4, 360), 'walls', []), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() analyses.borderCoverageCircular(zeros(4, 360), 'walls', [1]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() analyses.borderCoverageCircular(zeros(4, 360), 'walls', 'some'), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            testCase.verifyError(@() analyses.borderCoverageCircular(zeros(4, 360), 'walls', [1 2 3]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function perfectCoverage(testCase)
            mapPerfect = zeros(18, 360);
            mapPerfect(end, :) = randi(5, 1, 360);

            perfectFieldsMap = analyses.placefield(mapPerfect, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);

            coverage = analyses.borderCoverageCircular(perfectFieldsMap);
            testCase.verifyEqual(coverage, 1);
        end

        function someCoverage(testCase)
            map = zeros(18, 360);
            map(end, 1:50) = randi(5, 1, length(1:50));

            fieldsMap = analyses.placefield(map, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);

            coverage = analyses.borderCoverageCircular(fieldsMap);
            testCase.verifyEqual(coverage, 0.1389, 'AbsTol', 0.0005);
        end

        function coverageByWall(testCase)
            map = zeros(18, 360);
            map(end, 1:50) = randi(5, 1, length(1:50));
            fieldsMap = analyses.placefield(map, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);

            coverage = analyses.borderCoverageCircular(fieldsMap, 'walls', [1 50]);
            testCase.verifyEqual(coverage, 1);
        end

        function twoWalls(testCase)
            map = zeros(18, 360);
            map(end, 1:50) = randi(5, 1, length(1:50));
            fieldsMap = analyses.placefield(map, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);

            coverage = analyses.borderCoverageCircular(fieldsMap, 'walls', [1 50; 90 270]);
            testCase.verifyEqual(coverage, 1);
        end

        function coverageWithNan(testCase)
            map = zeros(18, 360);
            map(end, 1:50) = randi(5, 1, length(1:50));
            nanInd = randi(49, 1, 5) + 1;
            map(end, nanInd) = nan;
            fieldsMap = analyses.placefield(map, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);
            nanInd = isnan(map);
            fieldsMap(nanInd) = NaN;

            coverage = analyses.borderCoverageCircular(fieldsMap, 'walls', [1 50]);
            testCase.verifyEqual(coverage, 0.9, 'AbsTol', 0.0005);
        end

        function coverageWithSearchWidth(testCase)
            map = zeros(18, 360);
            map(end, 1:50) = randi(5, 1, length(1:50));
            nanInd = randi(49, 1, 5) + 1;
            map(end, nanInd) = nan;
            map(end-1, nanInd) = randi(5, 1, length(nanInd));
            % make field around NaN
            map(end-1, nanInd-1) = randi(5, 1, length(nanInd));
            map(end-1, nanInd+1) = randi(5, 1, length(nanInd));

            fieldsMap = analyses.placefield(map, 'threshold', 0.2, ...
                'minBins', 0, 'binWidth', 2.5, 'minPeak', 0);
            nanInd = isnan(map);
            fieldsMap(nanInd) = NaN;

            coverage = analyses.borderCoverageCircular(fieldsMap, 'walls', [1 50], 'searchWidth', 3);
            testCase.verifyEqual(coverage, 1);
        end
    end
end