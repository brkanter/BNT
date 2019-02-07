% Tests for analyses.calcHeadDirection function
classdef CalcHeadDirectionTester < matlab.unittest.TestCase
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()analyses.calcHeadDirection(), 'MATLAB:minrhs');
        end

        function emptyArgument(testCase)
            testCase.verifyError(@()analyses.calcHeadDirection(), ?MException);
        end

        function smallDimArgument(testCase)
            testCase.verifyError(@()analyses.calcHeadDirection([0 1 2]), ?MException);
        end

        function zero(testCase)
            positions = [0 0 0 0 0];
            exp = 180;

            hd = analyses.calcHeadDirection(positions);
            testCase.verifyEqual(hd, exp);
        end

        function values(testCase)
            % positions(:, 2:3) - front LED
            % positions(:, 4:5) - back LED
            positions = [0 1 1 3 1;... % west direction
                         0 1 1 3 3;... % south-west
                         0 3 1 1 1;... % east direction
                         0 2 2 2 5;... % south direction
                         0 -2 -2 -5 1;... % south-east direction
                        ];

            exp = [180; 225; 0; 270; 315];

            hd = analyses.calcHeadDirection(positions);
            testCase.verifyEqual(hd, exp);
        end

        function bad2ndLed(testCase)
            positions = [0 1 1 nan nan; 0 0 6 3 3];
            exp = [nan; 135];

            hd = analyses.calcHeadDirection(positions);
            testCase.verifyEqual(hd, exp);
        end
    end
end