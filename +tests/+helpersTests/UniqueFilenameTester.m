classdef UniqueFilenameTester < matlab.unittest.TestCase
    properties (Access = private)
        sessionData
    end

    methods
        function this = UniqueFilenameTester()
            this.sessionData.basename = 'basename';
            this.sessionData.path = 'C:\';
            this.sessionData.cuts = {'file.cut'};
            this.sessionData.units = [1 2];
        end
    end

    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()helpers.uniqueFilename(), 'MATLAB:minrhs');
        end

        function noArgumentsCut(testCase)
            testCase.verifyError(@()helpers.uniqueFilename(testCase.sessionData, 'cut'), 'MATLAB:minrhs');
        end

        function invalidKind(testCase)
            testCase.verifyError(@()helpers.uniqueFilename(testCase.sessionData, 'dfsdf343'), 'BNT:arg');
        end

        function invalidCutUnit(testCase)
            testCase.verifyError(@()helpers.uniqueFilename(testCase.sessionData, 'cut', 1), 'BNT:arg');
        end

        function cutName(testCase)
            name = helpers.uniqueFilename(testCase.sessionData, 'cut', [1 2]);
            expected = 'c:\basename_T1C2_9B722786AE2E030E5632707297039276.mat';
            testCase.verifyTrue(strcmpi(name, expected));
        end

        function posCleanScaleName(testCase)
            name = helpers.uniqueFilename(testCase.sessionData, 'posCleanScale');
            expected = 'c:\basename_posCleanScale.mat';
            testCase.verifyTrue(strcmpi(name, expected));
        end

        function posCleanName(testCase)
            name = helpers.uniqueFilename(testCase.sessionData, 'posClean');
            expected = 'c:\basename_posClean.mat';
            testCase.verifyTrue(strcmpi(name, expected));
        end

        function dataName(testCase)
            name = helpers.uniqueFilename(testCase.sessionData, 'data');
            expected = 'c:\basename_data_9B722786AE2E030E5632707297039276.mat';
            testCase.verifyTrue(strcmpi(name, expected));
        end
    end
end