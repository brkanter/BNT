classdef TestCaseWithData < matlab.unittest.TestCase
    %TestCaseWithData Usage of BNT test data in Matlab TestCase class

    properties (Access = protected)
        DataFolder  % Folder where data for this Testcase is stored
        doCleanUp   % Flag which determines whether we should clear test data on exit. Could be used during debuging. Default is True.
        usedInputFiles % cell array of input files that are used in this test. Must be set in subclassing constructor!
        testName    % name of a caller test
        copyRecordings % Specify if we should copy recording folder if there is a personal data folder.
                       % Default is True. So that the unit test folder is a mix of [Personal +
                       % recordings + input files]
    end

    methods
        function this = TestCaseWithData()
            st = dbstack(1);
            [~, this.testName] = fileparts(st.file);
            
            this.DataFolder = fullfile(tempdir, sprintf('bnt-tst-%s', this.testName));
            this.doCleanUp = true;
            this.usedInputFiles = {};
            this.copyRecordings = true;
        end
    end

    % Methods run before and after all test functions
    methods(TestClassSetup)
        function prepareData(testCase)
            helpers.mkfolder(testCase.DataFolder);
            
            % check the existance of a folder with name testCase.testName.
            % If it exists, then copy only this folder and nothing else.
            
            fprintf('Copying downloaded data...');
            testPersonalFolder = fullfile(tests.dataFolder, testCase.testName);
            if exist(testPersonalFolder, 'dir') ~= 0
                copyfile(fullfile(testPersonalFolder, '*'), testCase.DataFolder);
            end
            copyfile(fullfile(tests.dataFolder, 'input*.txt'), testCase.DataFolder);
            
            if testCase.copyRecordings
                copyfile(fullfile(tests.dataFolder, 'recordings'), testCase.DataFolder);
            end
            fprintf('done\n');

            % adjust paths in input files
            allTxt = dir(fullfile(testCase.DataFolder, '*.txt'));
            for i = 1:length(allTxt)
                % check that this is an input file
                % if ~ismember(allTxt(i).name, testCase.usedInputFiles)
                %     continue;
                % end
                if isempty(strfind(allTxt(i).name, 'input'))
                    continue;
                end
                inputFile = fullfile(testCase.DataFolder, allTxt(i).name);
                fileCont = fileread(inputFile);
                newCont = strrep(fileCont, '<dataFolder>', testCase.DataFolder);
                fid = data.safefopen(inputFile, 'w');
                fprintf(fid, '%s', newCont);
                clear fid;
            end
        end
    end

    % Methods that run after all test functions
    methods(TestClassTeardown)
        function cleanDataFolder(testCase)
            if testCase.doCleanUp
                rmdir(testCase.DataFolder, 's');
            end
        end
    end
end