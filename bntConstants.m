classdef (Sealed) bntConstants
    % bntConstants - Class to represent constants used in BNT.
    %
    % Properties of this class are BNT-related constants.
    %
    %  USAGE
    %   1. Check that arena is a box:
    %   data.getArenaShapeType() == bntConstants.ArenaShape.Box
    %

    properties (Constant = true)
        % Enumeration with types of arena
        ArenaShape = helpers.ArenaShape

        % Enumeration of recording systems
        RecSystem = helpers.RecSystem
        
        % Enumeration of clustering apps
        CutApp = helpers.CutApp;

        %% Columns in position matrix
        PosT = 1 % time
        PosX = 2 % LED 1 x and y
        PosY = 3
        PosX2 = 4 % LED2 x and y
        PosY2 = 5

        % Path of the default parameters file
        % You can use it as an argument in scripts, e.g.:
        %   scripts.screeningByTemplate('c:\work\input.txt', bntConstants.ParametersFile, 'c:\work\template.txt', 'c:\work\results')
        ParametersFile = fullfile(helpers.bntRoot, 'examples\bntSettings.m')
        
        %% List of possible extensions of cut-files created in MClust.
        % Should be used without preceding .
        MClustExtensions = {'t', 't32', 't64'};
    end
end

