classdef ParseGeneralFileTester < tests.TestCaseWithData

    methods
        function this = ParseGeneralFileTester()
            this.doCleanUp = false;
            this.copyRecordings = false;
        end
    end

    methods(Test)
        function noArguments(testCase)
            testCase.verifyError(@()io.parseGeneralFile(), 'MATLAB:minrhs');
        end

        function emptyArguments(testCase)
            testCase.verifyError(@()io.parseGeneralFile([]), ?MException);
        end

        function blanksInTheBeginning(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-begin-blank.txt'));

            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);
        end

        function blankInHeader(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-blank-header.txt'));

            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);
        end

        function headerBlanksInValues(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-header-blanks-in-values.txt'));

            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);
        end

        function garbageBeforeHeader(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-garbage-before-header.txt')), 'BNT:noHeader');
        end

        function incompleteHeader(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-incomplete-header.txt')), 'BNT:inputFormat');
        end

        function wrongFormatName(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-wrong-format-name.txt')), 'BNT:inputFormat');
        end

        function wrongFormat(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-wrong-format.txt')), ?MException);
        end

        function extraBlanksSessions(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-extra-blanks-sessions.txt'));
            expSession = fullfile(testCase.DataFolder, '11138', '07040501');

            testCase.verifyTrue(strcmpi(expSession, trials{1}.sessions{1}));
            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);
        end

        function missedSessions(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-missed-sessions.txt')), ?MException);
        end

        function doubleUnits(testCase)
            warning('off', 'BNT:multipleUnits');
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-double-units.txt'));
            warning('on', 'BNT:multipleUnits');
            expSession = fullfile(testCase.DataFolder, '11138', '07040501');

            testCase.verifyTrue(strcmpi(expSession, trials{1}.sessions{1}));
            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);

            testCase.verifyWarning(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-double-units.txt')), 'BNT:multipleUnits');
        end

        function doubleShape(testCase)
            warning('off', 'BNT:multipleShape');
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-double-shape.txt'));
            warning('on', 'BNT:multipleShape');
            expSession = fullfile(testCase.DataFolder, '11138', '07040501');

            testCase.verifyTrue(strcmpi(expSession, trials{1}.sessions{1}));
            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);

            testCase.verifyWarning(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-double-shape.txt')), 'BNT:multipleShape');
        end

        function emptyFile(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'empty-file.txt')), ?MException);
        end

        function garbageFile(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'garbage-file.txt')), ?MException);
        end

        function badShape(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-bad-shape.txt')), 'BNT:badShape');
        end

        function badUnits(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-bad-units.txt')), ?MException);

            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-bad-units1.txt'));
            expSession = fullfile(testCase.DataFolder, '11138', '07040501');

            testCase.verifyTrue(strcmpi(expSession, trials{1}.sessions{1}));
            testCase.verifyEqual(length(trials), 1);
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{1}.extraInfo.shape.type, 1);
            testCase.verifyEqual(trials{1}.extraInfo.shape.value, 150);
        end

        function badCuts(testCase)
            testCase.verifyError(@()io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-bad-cuts.txt')), 'BNT:badCuts');
        end

        function cutsNewLine(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, ...
                'input-cuts-new-line.txt'));
            testCase.verifyNotEmpty(trials{1}.cuts);
        end
        
        function sessionsWrongDelimiter(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'sessions-wrong-delimiter.txt'));
            expSession = '<DataFolder>\11138\07040501; <DataFolder>\11138\07040502';

            testCase.verifyTrue(strcmpi(expSession, trials{1}.sessions{1}));
        end

        function sessionsMultiple(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'sessions-multiple.txt'));
            expSessions = {fullfile('<DataFolder>', '11138', '07040501'); ...
                fullfile('<DataFolder>', '11138', '07040502'); ...
                fullfile('<DataFolder>', '11138', '07040503'); ...
            };

            testCase.verifyTrue(strcmpi(expSessions{1, 1}, trials{1}.sessions{1, 1}));
            testCase.verifyTrue(strcmpi(expSessions{2, 1}, trials{1}.sessions{2, 1}));
            testCase.verifyTrue(strcmpi(expSessions{3, 1}, trials{1}.sessions{3, 1}));
        end

        function cutsMultiple(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'cuts-multiple.txt'));
            expCuts = {'file1_tetrode1' 'file2_tetrode1'; 'file_tetrode2', []};

            testCase.verifyEqual(size(trials{1}.cuts), [2 2]);
            testCase.verifyTrue(strcmpi(expCuts{1, 1}, trials{1}.cuts{1, 1}));
            testCase.verifyTrue(strcmpi(expCuts{1, 2}, trials{1}.cuts{1, 2}));
            testCase.verifyTrue(strcmpi(expCuts{2, 1}, trials{1}.cuts{2, 1}));
        end

        function Version0_2_keywords(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-0.2.txt'));

            testCase.verifyTrue(isfield(trials{1}.extraInfo, 'calibration'));
            testCase.verifyTrue(strcmpi(trials{1}.extraInfo.calibration.file, 'calibrationFile'));

            testCase.verifyTrue(isfield(trials{1}.extraInfo, 'innerSize'));
            testCase.verifyTrue(strcmpi(trials{1}.extraInfo.innerSize.rec, fullfile(testCase.DataFolder, 'innerSize')));

            testCase.verifyTrue(isfield(trials{1}.extraInfo, 'outerSize'));
            testCase.verifyTrue(strcmpi(trials{1}.extraInfo.outerSize.rec, fullfile(testCase.DataFolder, 'outerSize')));
        end
        
        function Version0_2_units_no_semicolon(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-units-no-semicolon.txt'));
            
            testCase.verifyEqual(trials{1}.units, [1 2]);
            testCase.verifyEqual(trials{2}.units, [1 2; 3 1; 3 4]);
        end
        
        function inheritanceModeSwitch(testCase)
            trials = io.parseGeneralFile(fullfile(testCase.DataFolder, 'input-inheritance-mode-switch.txt'));
            
            testCase.verifyEqual(length(trials), 7);
            testCase.verifyEqual(trials{1}.units(1), 10);
            testCase.verifyTrue(isnan(trials{1}.units(2)));
            
            testCase.verifyEqual(trials{2}.units, [4 3]);
            testCase.verifyEqual(trials{3}.units, [4 3]);
            testCase.verifyEqual(trials{4}.units, [4 3]);
            testCase.verifyEqual(trials{5}.units, [4 3]);
            
            testCase.verifyEmpty(trials{6}.units);
            testCase.verifyEmpty(trials{7}.units);
        end
        
        function Version0_4_functions(testCase)
            inputfile = fullfile(testCase.DataFolder, 'input-0.4.txt');
            trials = io.parseGeneralFile(inputfile);
            
            testCase.verifyEqual(trials{1}.units(1), 1);
            testCase.verifyTrue(isnan(trials{1}.units(2)));

            testCase.verifyEqual(trials{2}.units(1), 1);
            testCase.verifyTrue(isnan(trials{2}.units(2)));
            testCase.verifySubstring(trials{2}.sessions{1}, '11138\07040501');
            
            testCase.verifyEqual(trials{3}.units(:, 1), [1;2]);
            testCase.verifyTrue(all(isnan(trials{3}.units(:, 2))));
            testCase.verifyEqual(size(trials{3}.cuts), [1 1]);
        end
    end
end