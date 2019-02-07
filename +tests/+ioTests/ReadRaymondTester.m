classdef ReadRaymondTester < tests.TestCaseWithData
    
    methods
        % Constructor. Can be used as:
        % to = tests.ioTests.ReadRaymondTester();
        % to.run
        function this = ReadRaymondTester()
            % See tests.TestCaseWithData for this property
            this.usedInputFiles = {'input-sameSessionDiffTetrodes.txt'};
        end
    end

    methods (Test)
        function sameSessionDifferentCuts(testCase)
            inputfile = fullfile(testCase.DataFolder, 'input-sameSessionDiffTetrodes.txt');

            trials = testCase.verifyWarning(@()io.readRaymondInputFileMeta(inputfile),  'BNT:warn:identicalUnits');

            expLen = 1;
            expCells = 3;
            expTetrodes = 2;
            expCutSize = [2 1];

            numCells = size(trials{1}.units, 1);
            numTetrodes = size(trials{1}.units, 2);

            testCase.verifyEqual(length(trials), expLen);
            testCase.verifyEqual(numCells, expCells);
            testCase.verifyEqual(numTetrodes, expTetrodes);
            testCase.verifyEqual(size(trials{1}.cuts), expCutSize);
        end
    end
end