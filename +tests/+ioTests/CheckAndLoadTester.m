classdef CheckAndLoadTester < tests.TestCaseWithData
    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()io.checkAndLoad(), 'MATLAB:minrhs');
        end
        
        function dataRelocation(testCase)
            global gBntData;
            inputfile = fullfile(testCase.DataFolder, 'input-data-relocation.txt');
            data.loadSessions(inputfile);
            
            firstTrials = gBntData;
            
            foldersToMove{1} = fullfile(testCase.DataFolder, '2016-02-11_12-36-36');
            foldersToMove{2} = fullfile(testCase.DataFolder, 'Rat_03_20720', '20150605');
            destinationFolder = fullfile(testCase.DataFolder, 'relocatedData');
            helpers.mkfolder(destinationFolder);
            
            for i = 1:length(foldersToMove)
                movefile(foldersToMove{i}, destinationFolder);
            end
            
            relocatedInput = fullfile(testCase.DataFolder, 'input-data-relocated.txt');
            data.loadSessions(relocatedInput);
            
            secondTrials = gBntData;
            
            testCase.verifyEqual(firstTrials{1}.cuts, secondTrials{1}.cuts);
            
            [~, a] = helpers.fileparts(firstTrials{1}.sessions{1});
            [~, b] = helpers.fileparts(secondTrials{1}.sessions{1});
            testCase.verifyTrue(strcmpi(a, b));
            
            % check for double session name
            testCase.verifyEmpty(strfind(secondTrials{1}.sessions{1}, '2016-02-11_12-36-36\2016-02-11_12-36-36'));
            
            testCase.verifyTrue(strcmpi(secondTrials{2}.cuts{1}, fullfile(secondTrials{2}.path, ...
                sprintf('%s_4.cut', secondTrials{2}.basename))));
            
            a = strfind(secondTrials{2}.sessions{1}, '20150605\20150605');
            testCase.verifyLength(a, 1);
        end
    end
end