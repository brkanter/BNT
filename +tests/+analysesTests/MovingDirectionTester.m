classdef MovingDirectionTester < matlab.unittest.TestCase
    methods(Test)

        function Angle45_wind1_noNan(testCase)
            pos(:, 2) = 11:20;
            pos(:, 3) = 11:20;

            expMd = ones(1, 10)' * 45;
            expMd([1 end]) = nan;

            md = analyses.movingDirection(pos);
            testCase.verifyEqual(md, expMd);
        end

        function Angle45_wind1_nan(testCase)
            pos(:, 2) = 11:20;
            pos(:, 3) = 11:20;
            pos(3:5, 2) = nan;

            expMd = nan(1, 10)';
            expMd(7:9) = 45;

            md = analyses.movingDirection(pos);
            testCase.verifyEqual(md, expMd);
        end

        function Angle45_wind2_nan(testCase)
            pos(:, 2) = 11:20;
            pos(:, 3) = 11:20;
            pos(3:5, 2) = nan;

            expMd = nan(1, 10)';
            expMd(8) = 45;

            md = analyses.movingDirection(pos, 'windowPoints', [2 2]);
            testCase.verifyEqual(md, expMd);
        end

        function Angle45_wind12_nan(testCase)
            pos(:, 2) = 11:20;
            pos(:, 3) = 11:20;
            pos(3:5, 2) = nan;

            expMd = nan(1, 10)';
            expMd(7:8) = 45;

            md = analyses.movingDirection(pos, 'windowPoints', [1 2]);
            testCase.verifyEqual(md, expMd);
        end

        function changeDirection(testCase)
            pos(:, 2) = 11:20;
            pos(:, 3) = 11:20;
            pos(3:5, 2) = nan;
            pos(11:20, 2) = 21:30;
            pos(11:20, 3) = 19:-1:10;
            pos(15:17, 3) = 16;

            expMd = nan(1, 20)';
            expMd(7:9) = 45;
            expMd(10) = 0;
            expMd(11:13) = 315;
            expMd(14) = mod(atan2d(pos(15, 3) - pos(13, 3), pos(15, 2) - pos(13, 2)), 360);
            expMd(15:16) = 0;
            expMd(17) = mod(atan2d(pos(18, 3) - pos(16, 3), pos(18, 2) - pos(16, 2)), 360);
            expMd(18) = mod(atan2d(pos(19, 3) - pos(17, 3), pos(19, 2) - pos(17, 2)), 360);
            expMd(19) = 315;

            md = analyses.movingDirection(pos);
            testCase.verifyEqual(md, expMd);
        end

        function north(testCase)
            pos(:, 3) = 11:20;
            pos(:, 2) = 10;

            expMd = ones(1, 10)' * 90;
            expMd([1 end]) = nan;
            md = analyses.movingDirection(pos);

            testCase.verifyEqual(md, expMd);
        end

        function northWest(testCase)
            pos(:, 3) = 1:10;
            pos(:, 2) = (0:-1:-9) + 10;

            expMd = ones(1, 10)' * 135;
            expMd([1 end]) = nan;
            md = analyses.movingDirection(pos);

            testCase.verifyEqual(md, expMd);
        end

        function west(testCase)
            pos(:, 2) = (0:-1:-9) + 10;
            pos(:, 3) = 10;

            expMd = ones(1, 10)' * 180;
            expMd([1 end]) = nan;
            md = analyses.movingDirection(pos);

            testCase.verifyEqual(md, expMd);
        end

        function southWest(testCase)
            pos(:, 2) = (0:-1:-9) + 10;
            pos(:, 3) = (0:-1:-9) + 10;

            expMd = ones(1, 10)' * 225;
            expMd([1 end]) = nan;
            md = analyses.movingDirection(pos);

            testCase.verifyEqual(md, expMd);
        end

        function south(testCase)
            pos(:, 3) = 10:-1:1;
            pos(:, 2) = 10;

            expMd = ones(1, 10)' * 270;
            expMd([1 end]) = nan;
            md = analyses.movingDirection(pos);

            testCase.verifyEqual(md, expMd);

        end

        function step2(testCase)
            pos(:, 3) = 10:-1:1;
            pos(:, 2) = 10;

            expMd2 = nan(1, 10)';
            expMd2(2:2:9) = 270;
            expNewPos = pos;
            expNewPos(1:2:9, 2:3) = nan;
            expNewPos(end, 2:3) = nan;


            [md, newPos] = analyses.movingDirection(pos, 'step', 2);
            testCase.verifyEqual(md, expMd2);
            testCase.verifyEqual(newPos, expNewPos);
        end

        function noArguments(testCase)
            testCase.verifyError(@()analyses.movingDirection(), 'MATLAB:minrhs');
        end

        function emptyPos(testCase)
            testCase.verifyError(@() analyses.movingDirection([]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end

        function wrongPosDims(testCase)
            testCase.verifyError(@() analyses.movingDirection(1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            md = analyses.movingDirection([1 1 1 1 1]);
            testCase.verifyEqual(md, [nan nan]);

            testCase.verifyError(@() analyses.movingDirection([1 1]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end
        
        function wrongWindowPoints(testCase)
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', [1 2 3]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', [0 2]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', [-1 -1]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', [1 -1]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', nan), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', [nan nan]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'windowPoints', [0 0]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end
        
        function wrongStep(testCase)
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'step', 0), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'step', [0 0]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'step', [1 1]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');

            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'step', nan), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'step', [nan nan]), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
            
            testCase.verifyError(@() analyses.movingDirection([1 1 1 1 1], 'step', -1), ...
                'MATLAB:InputParser:ArgumentFailedValidation');
        end
    end
end
