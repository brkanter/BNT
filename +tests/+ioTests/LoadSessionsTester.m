classdef LoadSessionsTester < tests.TestCaseWithData

    properties (Access=private)
        % Full path of an input file that is used in tests. This propery
        % is used in method teardown code. See clearCache.
        inputFile = '';
    end
    
    methods
        function this = LoadSessionsTester()
            this.doCleanUp = true;
        end
    end
    
    methods(TestMethodTeardown)
        function clearCache(testCase)
            if ~isempty(testCase.inputFile) && exist(testCase.inputFile, 'file') ~= 0
                helpers.deleteCache(testCase.inputFile);
                testCase.inputFile = '';
            end
        end
    end

    methods(Test)
        function LoadRaymondInputFile(testCase)
            global gBntData;

            inputfile = fullfile(testCase.DataFolder, 'input-raymond.txt');
            convertedInput = fullfile(testCase.DataFolder, 'input-raymond.cfg');

            expectedTrialsNum = 4;

            data.loadSessions(inputfile, '', false);

            convertedRes = exist(convertedInput, 'file');
            testCase.verifyNotEqual(convertedRes, 0);

            testCase.verifyEqual(length(gBntData), expectedTrialsNum);
            testCase.verifyEqual(gBntData{1}.units, [7 1; 7 2]);
            testCase.verifyEqual(gBntData{2}.units, [7 1]);
            testCase.verifyEqual(gBntData{3}.units, [1 2]);
            testCase.verifyEqual(gBntData{4}.units, [6 2; 7 1]);

            helpers.deleteCache(convertedInput);
            delete(convertedInput);
        end

        function LoadAndReplaceRaymond(testCase)
            inputfile = fullfile(testCase.DataFolder, 'input-raymond.txt');
            backupFile = fullfile(testCase.DataFolder, 'input-raymond.txt.bak');

            str = fileread(inputfile);
            data.loadSessions(inputfile);
            str_backup = fileread(backupFile);

            testCase.verifyEqual(exist(backupFile, 'file'), 2);
            testCase.verifyTrue(strcmp(str, str_backup));
            testCase.inputFile = inputfile;
        end

        function LoadAndConvertGeneral0_1(testCase)
            inputfile = fullfile(testCase.DataFolder, 'inputLight-singleCut.txt');
            backupFile = fullfile(testCase.DataFolder, 'inputLight-singleCut_0_1.txt');

            str = fileread(inputfile);

            warning('off', 'BNT:earlySpike');
            data.loadSessions(inputfile);
            warning('on', 'BNT:earlySpike');

            str_backup = fileread(backupFile);

            testCase.verifyEqual(exist(backupFile, 'file'), 2);
            testCase.verifyTrue(strcmp(str, str_backup));
            testCase.inputFile = inputfile;
        end

        function unitToCutRelation(testCase)
            global gBntData;

            inputfile = fullfile(testCase.DataFolder, 'input-check_tetrode_cut_order.txt');
            data.loadSessions(inputfile, '', false);
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-check_tetrode_cut_order.cfg');

            expTrialNum = 3;
            testCase.verifyEqual(length(gBntData), expTrialNum);

            for i = 2:3
                [~, sessionName] = fileparts(gBntData{i}.sessions{1});

                tetrodes = unique(gBntData{i}.units(:, 1), 'stable');
                for j = 1:length(tetrodes)
                    nameInd = strfind(gBntData{i}.cuts{j}, sessionName);
                    testCase.verifyNotEmpty(nameInd);

                    searchInd = nameInd + length(sessionName);

                    tetrode = tetrodes(j);
                    testCase.verifyNotEmpty(strfind(gBntData{i}.cuts{j}(searchInd:end), num2str(tetrode)));
                end
            end
        end

        function noAdditionalCuts(testCase)
            global gBntData;

            inputfile = fullfile(testCase.DataFolder, 'input-Pippen_check_cuts.txt');
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-Pippen_check_cuts.cfg');

            data.loadSessions(inputfile, '', false);
            testCase.verifyEqual(length(gBntData), 1);
            testCase.verifyEqual(size(gBntData{1}.cuts, 1), 3);
            % helpers.deleteCache(inputfile);
        end

        % information about the first part of the file is present
        function neuralynxCutPatternFirst(testCase)
            global gBntData;

            testCase.inputFile = fullfile(testCase.DataFolder, 'input-neuralynxCutPatternFirst.txt');

            warning('off', 'BNT:earlySpike');
            data.loadSessions(testCase.inputFile, '', false);
            warning('on', 'BNT:earlySpike');

            expTrialNum = 1;
            expNumSessions  = 2;
            expNumCut = 2;
            expUnits = [3 1; 1 2];

            testCase.verifyEqual(length(gBntData), expTrialNum);
            testCase.verifyEqual(length(gBntData{1}.sessions), expNumSessions);
            testCase.verifyEqual(size(gBntData{1}.cuts, 1), expNumCut);
            testCase.verifyEqual(gBntData{1}.units, expUnits);
            testCase.verifyEqual(size(gBntData{1}.spikes), [23029 3]); % Cut files have 23030 spikes, but we remove one early spike
        end

        % TODO: test loading of input file with no session, but other info.

        % test loading of NeuraLynx data without cut information
        % First trial contains ambiguous cut files: AA3_TT12_1.t and TT12_1.t.
        % However, only TT12_1.t is loaded since we search by first two numeric values.
        function neuralynxNoCut(testCase)
            global gBntData;

            testCase.inputFile = fullfile(testCase.DataFolder, 'input-neuralynxNoCut.txt');

            testCase.verifyWarningFree(@()data.loadSessions(testCase.inputFile, '', false));

            testCase.verifyEqual(length(gBntData), 2);
            testCase.verifyNotEmpty(gBntData{1}.spikes);
            testCase.verifyNotEmpty(gBntData{2}.spikes);
        end
        
        function neuralynxMultipleSessionNoCut(testCase)
            global gBntData;
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-neuralynxNoCut-multiplePattern.txt');

            testCase.verifyWarningFree(@()data.loadSessions(testCase.inputFile, '', false));
            
            secondSessionStart = gBntData{1}.startIndices(2);
            % verify that the first spike happens during the first session
            testCase.verifyTrue(gBntData{1}.spikes(1, 1) < gBntData{1}.positions(secondSessionStart-1, 1));
        end

        function neuralynxCutPattern(testCase)
            global gBntData;

            testCase.inputFile = fullfile(testCase.DataFolder, 'inputLight-CutPattern.txt');
            warning('off', 'BNT:earlySpike');
            testCase.verifyWarningFree(@()data.loadSessions(testCase.inputFile, '', false));
            warning('on', 'BNT:earlySpike');

            testCase.verifyEqual(length(gBntData), 1);
            testCase.verifyNotEmpty(gBntData{1}.spikes);
            testCase.verifyEqual(size(gBntData{1}.spikes), [23029 3]); % the same size as in neuralynxCutPatternFirst
            testCase.verifyEqual(size(gBntData{1}.cuts, 1), 2);
        end

        % test cut file name pattern that applies to all units
        function neuralynxSingleCutMultipleUnits(testCase)
            global gBntData;

            testCase.inputFile = fullfile(testCase.DataFolder, 'inputLight-singleCut.txt');
            warning('off', 'BNT:earlySpike');
            testCase.verifyWarningFree(@()data.loadSessions(testCase.inputFile, '', false));
            warning('on', 'BNT:earlySpike');

            testCase.verifyEqual(length(gBntData), 1);
            testCase.verifyNotEmpty(gBntData{1}.spikes);
            testCase.verifyEqual(size(gBntData{1}.spikes), [23029 3]); % the same size as in neuralynxCutPatternFirst
            testCase.verifyEqual(size(gBntData{1}.cuts), [2 1]);
        end

        % test loading of cut files from an arbitary directory
        function neuralynxCutDifferentDir(testCase)
            global gBntData;

            testCase.inputFile = fullfile(testCase.DataFolder, 'inputLight-cut-different-dir.txt');
            warning('off', 'BNT:earlySpike');
            testCase.verifyWarningFree(@()data.loadSessions(testCase.inputFile, '', false));
            warning('on', 'BNT:earlySpike');

            testCase.verifyEqual(length(gBntData), 1);
            testCase.verifyNotEmpty(gBntData{1}.spikes);
            testCase.verifyEqual(size(gBntData{1}.spikes), [23029 3]); % the same size as in neuralynxCutPatternFirst
            testCase.verifyEqual(size(gBntData{1}.cuts), [2 1]);
        end

        % Load Raymond's input file where one session has two input files. Since I do not have
        % a real data for this case, the second cut file is invalid.
        % Code should be able to load data without exceptions, warning is possible.
        function multipleCuts(testCase)
            inputfile = fullfile(testCase.DataFolder, 'input-multiple-cuts.txt');
            % Do not use tear down code, it will fail
            verifyError(testCase, @() data.loadSessions(inputfile, '', false), 'BNT:badCuts');
        end

        % Test loading of axona data without cut file information
        function axonaNoCuts(testCase)
            global gBntData;

            testCase.inputFile = fullfile(testCase.DataFolder, 'input-axona-no-cuts.txt');
            data.loadSessions(testCase.inputFile, '', false);

            testCase.verifyEqual(length(gBntData), 1);
            testCase.verifyEqual(size(gBntData{1}.cuts), [1 1]);
            
            % sort spikes according to cell number
            [~, sortInd] = sort(gBntData{1}.spikes(:, 3));
            gBntData{1}.spikes = gBntData{1}.spikes(sortInd, :);

            % file with spikes variable, that contains correct spikes for no-cuts input file
            load(fullfile(testCase.DataFolder, 'data-axona-no-cuts.mat'));
            % sort according to cell number
            [~, sortInd] = sort(spikes(:, 3)); %#ok<NODEF>
            spikes = spikes(sortInd, :);
            testCase.verifyEqual(gBntData{1}.spikes, spikes);
        end
        
        % Test loading of data when there are combined sessions, multiple
        % tetrodes, but a single cut file per tetrode.
        function combinedSessionsMultipleTetrodes(testCase)
            global gBntData;
            
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-cmb-sessions-multiple-tetrodes.txt');
            data.loadSessions(testCase.inputFile, '', false);
            
            expNumberOfSpikes = [5980 7230 4296 759 1969 7067];
            numberOfSpikes = zeros(size(expNumberOfSpikes));
            
            units = gBntData{1}.units;
            for i = 1:size(units, 1)
                spikes = data.getSpikeTimes(units(i, :));
                numberOfSpikes(i) = numel(spikes);
            end
            
            testCase.verifyEqual(expNumberOfSpikes, numberOfSpikes);
        end
        
        function neuralynxIncorrectCutPattern(testCase)
            inputfile = fullfile(testCase.DataFolder, 'input-incorrect-cut-pattern.txt');
            testCase.verifyWarning(@() data.loadSessions(inputfile, '', false), 'BNT:noSpikes');
        end
        
        function inheritanceModeSwitch(testCase)
            global gBntData;
            
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-inheritance-mode-switch.txt');
            data.loadSessions(testCase.inputFile, '', false);
            
            testCase.verifyEqual(length(gBntData), 7);
            testCase.verifyEqual(size(gBntData{1}.units, 1), 6);
            testCase.verifyTrue(~isempty(gBntData{6}.units));
            testCase.verifyTrue(~isempty(gBntData{7}.units));
        end
        
        function TwoTetrodesOneCut(testCase)
            global gBntData;
            
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-two-tetrodes-one-cut.txt');
            data.loadSessions(testCase.inputFile, '', false);
            
            tetrodes = unique(gBntData{1}.units(:, 1));
            testCase.verifyEqual(tetrodes(:), [1;3]);
            testCase.verifyEqual(size(gBntData{1}.cuts), [2 1]);
            testCase.verifyEqual(size(gBntData{1}.spikes), [3689 3]);
        end
        
        % Test situation when loading Axona data, cut file is defined, but
        % the data folder contains an additional .t file
        function axonaCutButMixedCuts(testCase)
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-axona-multiple-cut-apps.txt');
            testCase.verifyWarningFree(@()data.loadSessions(testCase.inputFile, '', false));
        end
        
        function neuralynxMixedCuts(testCase)
            testCase.inputFile = fullfile(testCase.DataFolder, 'input-neuralynx-multiple-cut-apps.txt');
            % test that there were no errors. Warnings are OK.
            data.loadSessions(testCase.inputFile, '', false);
        end
    end
end