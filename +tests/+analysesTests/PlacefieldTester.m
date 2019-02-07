classdef PlacefieldTester < tests.TestCaseWithData
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.placefield(), 'MATLAB:minrhs');
        end

        function oneInTheMiddle(testCase)
            nBins = [30 30];

            expNumFields = 1;
            mu = [15 15];
            sigma = 7;
            expArea = 69;
            expMeanRate = 5059;

            map = helpers.gauss2d(mu, sigma, nBins);

            [~, fields] = analyses.placefield(map);

            numFields = length(fields);

            testCase.verifyEqual(expNumFields, numFields);

            meanRate = round(fields.meanRate * 10000);

            testCase.verifyEqual(expArea, fields.area);
            testCase.verifyEqual(expMeanRate, meanRate);
        end

        function emptyArguments(testCase)
            [fieldsMap, fields] = analyses.placefield([]);

            testCase.verifyEmpty(fieldsMap, 'fieldsMap is not empty');
            testCase.verifyEqual(length(fields), 0);

            testCase.verifyWarningFree(@()analyses.placefield([]));
        end

        function fieldBelow20(testCase)
            % 2 fields. Peak of the second peak is below of 0.20 * (globalPeak).
            % The function should detect two fields
            map = [2 3 5 5 5 5 3 2 2 3 3 3 3 2; ...
                 2 3 5 17 19 17 3 2 2 3 4 5 4 2; ...
                 2 3 5 19 20 19 3 2 2 3 5 6 5 2;...
                 2 3 5 17 19 17 3 2 2 3 4 5 4 2;...
                 2 3 5 5 5 5 3 2 2 3 3 3 3 2; ...
                 2 3 5 2 3 2 3 2 2 3 2 2 2 2;];

            [~, fields] = analyses.placefield(map, 'threshold', 0.2, 'minBins', 0, 'binWidth', 1, 'minPeak', 0);

            testCase.verifyEqual(length(fields), 2);
            testCase.verifyEqual(fields(1).peak, 20);
            testCase.verifyEqual(fields(1).size, 21);


            testCase.verifyEqual(fields(2).peak, 6);
            testCase.verifyEqual(fields(2).size, 9);
        end
        
        function severalBelow20(testCase)
            % 4 fields. Peaks of 3 of those are below of 0.20 * globalPeak.
            % The function should detect all fields. Those 3 fields should
            % have different peak firing rate.
            pt = [5 5; 20.5 9; 30 15; 12.5 22.5];
            map = helpers.gauss2d(pt, 5 * ones(size(pt, 1), 1), [35 35], [20 3.9 3.5 3 2]);
            [~, fields] = analyses.placefield(map, 'threshold', 0.2, 'minBins', 0, 'binWidth', 1, 'minPeak', 0);
            
            testCase.verifyEqual(length(fields), 4);
            testCase.verifyTrue(abs(fields(2).peak - fields(3).peak) > eps);
            testCase.verifyTrue(abs(fields(3).peak - fields(4).peak) > eps);
        end
        
        function minPeakVerification(testCase)
            pt = [5 5; 20.5 9; 30 15; 12.5 22.5];
            map = helpers.gauss2d(pt, 5 * ones(size(pt, 1), 1), [35 35], [20 6 10 3 2]);
            [~, fields] = analyses.placefield(map, 'threshold', 0.2, 'minBins', 0, 'binWidth', 1, 'minPeak', 9);
            
            testCase.verifyEqual(length(fields), 2);
            testCase.verifyEqual(round(fields(1).peak), 20);
            testCase.verifyEqual(round(fields(2).peak), 10);
        end
        
        function verifyMinBins(testCase)
            pt = [5 5; 20.5 9; 30 15; 12.5 22.5];
            map = helpers.gauss2d(pt, 5 * ones(size(pt, 1), 1), [35 35], [20 6 10 3 2]);
            [~, fields] = analyses.placefield(map, 'threshold', 0.2, 'minBins', 13, 'binWidth', 1, 'minPeak', 0);
            
            testCase.verifyEqual(length(fields), 3);
        end

        % test case when two peaks/fields are close toger, resulting in the duplicate field
        function duplicates(testCase)
            mapFile = fullfile(testCase.DataFolder, 'testmap.mat'); % contains variable rmap
            load(mapFile);

            [~, fields] = analyses.placefield(rmap, 'threshold', 0.2, 'minBins', 0, 'binWidth', 1, 'minPeak', 0);
            testCase.verifyEqual(length(fields), 3);
        end
        
        % test that posInd is not empty on a predefined rate map
        function notEmptyPosInd(testCase)
            dataFile = fullfile(testCase.DataFolder, 'field2pos.mat'); % contains: basicInfo, map, spikes, p, pos.
            load(dataFile);
            
            [~, fields] = analyses.placefield(map, 'threshold', p.fieldThreshold2D, ...
                'minBins', p.fieldMinBins, 'binWidth', p.binWidth, 'pos', pos, 'minPeak', p.fieldMinPeak);
            testCase.verifyNotEmpty(fields.posInd);            
        end

    end
end