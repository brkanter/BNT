classdef SpatialCrossCorrelationTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.spatialCrossCorrelation(), 'MATLAB:minrhs');
        end

        function oneMap(testCase)
            testCase.verifyError(@()analyses.spatialCrossCorrelation([]), 'MATLAB:minrhs');
        end

        function emptyMaps(testCase)
            v =  analyses.spatialCrossCorrelation([], []);
            testCase.verifyEqual(v, nan);
        end

        function wrongProcessBy(testCase)
            testCase.verifyError(@() analyses.spatialCrossCorrelation([], [], 'processBy', 'x'), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.spatialCrossCorrelation([], [], 'processBy', 1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.spatialCrossCorrelation([], [], 'processBy', nan), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function wrongOutput(testCase)
            testCase.verifyError(@() analyses.spatialCrossCorrelation([], [], 'output', 'x'), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.spatialCrossCorrelation([], [], 'output', 1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.spatialCrossCorrelation([], [], 'output', nan), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function oneEmptyMap(testCase)
            map1 = [];
            map2 = magic(5);

            testCase.verifyWarning(@(x) analyses.spatialCrossCorrelation(map1, map2), 'BNT:mapsSize');

            warning('off', 'BNT:mapsSize');
            cc = analyses.spatialCrossCorrelation(map1, map2);
            warning('on', 'BNT:mapsSize');
            testCase.verifyEqual(cc, nan);
        end

        function single(testCase)
            map1 = magic(6) + 10;
            map2 = magic(6);
            cc = analyses.spatialCrossCorrelation(map1, map2);
            testCase.verifyEqual(cc, 1);

            map1 = [...
                0.6948    0.7655    0.7094    0.1190    0.7513    0.5472
                0.3171    0.7952    0.7547    0.4984    0.2551    0.1386
                0.9502    0.1869    0.2760    0.9597    0.5060    0.1493
                0.0344    0.4898    0.6797    0.3404    0.6991    0.2575
                0.4387    0.4456    0.6551    0.5853    0.8909    0.8407
                0.3816    0.6463    0.1626    0.2238    0.9593    0.2543];

            cc = analyses.spatialCrossCorrelation(map1, map2);
            testCase.verifyEqual(roundn(cc, -4), 0.172);
        end

        function vector(testCase)
            map1 = magic(6) + 10;
            map2 = magic(6);
            expV_c = ones(1, 6);
            expV_r = expV_c';

            cc = analyses.spatialCrossCorrelation(map1, map2, 'output', 'vector');
            testCase.verifyEqual(cc, expV_c);

            cc = analyses.spatialCrossCorrelation(map1, map2, 'output', 'vector', 'processBy', 'r');
            testCase.verifyEqual(round(cc), expV_r);
        end
    end
end
