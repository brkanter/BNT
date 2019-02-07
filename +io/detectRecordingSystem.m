% Determine if trial data had been recorded with Axona or Neuralynx
%
% This function takes information about the data and finds out which
% recording system had been used to collect the data. In case of
% multiple/merged sessions, it is assumed that they are were recorded
% using the same system. The function modifies the input data, adds
% new information to it and returns it.
%
%  USAGE
%   trialData = io.detectRecordingSystem(trialData)
%   trialData     Structure with information about the trial. This
%                 is a structure initialized by helpers.initTrial.
%
function trialData = detectRecordingSystem(trialData)
    % Find out if this is Axona or NeuraLynx data
    % In case of multiple sessions, assume that combined sessions have been recorded using the same system.
    % Thus, check only the first session.
    setCandidate = sprintf('%s.set', trialData.sessions{1});
    if ~isempty(dir(setCandidate))
        % check if this is a Virmen virtual reality, which comes alongside of Axona
        virmenCandidate = sprintf('%s*.vr', trialData.sessions{1});
        isVirmen = ~isempty(dir(virmenCandidate));
        if isVirmen
            setVirmen();
        else
            setAxona();
        end
        return;
    end

    if ~isempty(dir(fullfile(trialData.sessions{1}, '*.nvt')))
        setNeuraLynx;
    end

    %% check if it is in old dbMaker format
    matFile = sprintf('%s_pos.mat', trialData.sessions{1});
    if exist(matFile, 'file') ~= 0
        tt = load(matFile);
        if isfield(tt, 'recSystem')
            if strcmpi(tt.recSystem, 'Axona')
                setAxona();
            else
                setNeuraLynx();
            end
        end
    end

    function setAxona()
        trialData.system = bntConstants.RecSystem.Axona;
        trialData.sampleTime = 0.02; % 50 Hz
        trialData.videoSamplingRate = 50;
    end

    function setVirmen()
        trialData.system = bntConstants.RecSystem.Axona;
        trialData.sampleTime = 0.02; % 50 Hz
        trialData.videoSamplingRate = 50;
    end

    function setNeuraLynx()
        trialData.system = bntConstants.RecSystem.Neuralynx;
        trialData.sampleTime = 0.04; % 25 Hz
        trialData.videoSamplingRate = 25;
    end
end
