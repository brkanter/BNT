% Get name/number of the animal for current trial
%
% Animal name could be provided in an input file or extracted from
% recordings folder structure. If animal name was provided in the input
% file, then this name is always returned.
%
% Recordings are stored in folders that correspond to animal's name or number.
% This function returns part of the stored data path, which is believed
% to be animal's name.
% Consider these paths. They are arranged by increasing 'depth':
% * C:\work\recordings\<animal_name>\0101101602.set
% * C:\work\recordings\<animal_name>\trials\0101101601.set
% * C:\work\recordings\<animal_name>\box1\trials\0101101601.set
%
% To extract animal name from the first path, you have to set depth to 1.
% To extract animal name from the second path, you have to set depth to 2.
% And so on, for the third path you set depth to 3.
%
%  USAGE
%   name = data.getAnimalName(<trialNum>, <depth>)
%   trialNum    Optional number of a trial to use. If not provided, then the
%               current trial is used.
%   depth       Optional integer that describes depth at which name is recorded.
%               Default value is 1 which means the name of the folder that
%               contains the recording. See also description of the function above.
%               Depth must be greater than zero.
%               Depth has no meaning if animal name is provided in the
%               input file.
%   name        Name of the animal for the current trial. Can be empty.
%
function name = getAnimalName(trialNum, depth)
    global gBntData;
    global gCurrentTrial;

    if nargin == 1
        % since both parameters are optional we ca not be sure which one to use
        % when only single one is provided.
        % Default to use depth when only one parameter is given. This is how other code expects it to be.
        % In the future, function arguments should be changed or name-value pairs shold be used.
        depth = trialNum;
    end
    if nargin < 1
        depth = 1;
    end
    if nargin < 2
        trialNum = gCurrentTrial;
    end

    if isfield(gBntData{trialNum}.extraInfo, 'subjectId')
        name = gBntData{trialNum}.extraInfo.subjectId;
        return;
    end

    if ~helpers.isivector(depth, '>=0')
        error('BNT:arg', 'Incorrect argument ''depth'' (type ''help <a href="matlab:help data.getAnimalName">data.getAnimalName</a>'' for details).');
    end
    if depth <= 0
        depth = 1;
    end
    name = '';

    [currentPath, name] = helpers.fileparts(gBntData{trialNum}.path);
    if strcmpi(gBntData{trialNum}.system, bntConstants.RecSystem.Neuralynx) && depth >= 1
        depth = depth + 1;
    end
    for i = 1:depth-1
        [currentPath, name] = helpers.fileparts(currentPath);
    end
end
