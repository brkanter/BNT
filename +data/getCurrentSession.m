% Get information about current session.
%
%  USAGE
%
%    GetCurrentSession
%    GetCurrentSession('verbose')  % detailed output
%
%    info = GetCurrentSession  % return info (do not display)
%
% Copyright (C) 2008-2011 by Michaël Zugaro
%               2013 by Vadim Frolov

% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
function varargout = getCurrentSession(verbose)

global gBntData;
global gCurrentTrial;

info = [];

verbose = nargin >= 1 && strcmpi(verbose, 'verbose');

% Initialization
if isempty(gBntData),
	disp('No session loaded');
	return
end

% info.type = gBntData{gCurrentTrial}.type;
info.basename = gBntData{gCurrentTrial}.basename;
info.path = gBntData{gCurrentTrial}.path;
% info.tetrode = gBntData{gCurrentTrial}.tetrode;
info.units = gBntData{gCurrentTrial}.units;

if nargout > 0,
	varargout{1} = info;
	return
end

fprintf('Current trial number is %d\n', gCurrentTrial);

disp('Session');
% disp(['  Type                           ' info.type]);
disp(['  Name                           ' info.basename]);
disp(['  Disk Path                      ' info.path]);

% separator;
% disp('Spikes');
% disp(['  Tetrode                        ' num2str(info.tetrode)]);
% disp(['  Units                          ' num2str(info.units)]);

% separator;
% disp('Channels');
% disp(['  Number of Channels             ' int2str(gBntData{gCurrentTrial}.nChannels)]);
% disp(['  Wide-Band Sampling Rate        ' num2str(gBntData{gCurrentTrial}.rates.wideband)]);
% disp(['  LFP Sampling Rate              ' num2str(gBntData{gCurrentTrial}.rates.lfp)]);

% separator;
% disp('Positions');
% disp(['  Sampling Rate                  ' num2str(gBntData{gCurrentTrial}.rates.video)]);
% disp(['  Image Size (pixels)            ' int2str(gBntData{gCurrentTrial}.maxX) 'x' int2str(gBntData{gCurrentTrial}.maxY)]);
% n = size(gBntData{gCurrentTrial}.positions,1);
% disp(['  Number of Position Samples     ' int2str(n)]);
% if n ~= 0,
% 	disp(['  Number of Undetected Samples   ' int2str(sum(gBntData{gCurrentTrial}.positions(:,1)==-1))]);
% end

% separator;
% disp('Spikes');
% nGroups = gBntData{gCurrentTrial}.spikeGroups.nGroups;
% disp(['  Number of Spike Groups         ' int2str(nGroups)]);
% if verbose,
% 	for i = 1:nGroups,
% 		if i < 10, white1 = ' '; else white1 = ''; end
% 		clusters = gBntData{gCurrentTrial}.spikes(gBntData{gCurrentTrial}.spikes(:,2)==i,3);
% 		nClusters = length(unique(clusters));
% 		for j = 1:nClusters,
% 			if j < 10, white2 = ' '; else white2 = ''; end
% 			if j == 1, n = [white1 int2str(i) '.']; else n = '   ';end
% 			disp([' ' n ' Spikes in cluster ' white2 int2str(j) '        ' int2str(sum(clusters==j))]);
% 		end
% 	end
% end

separator;

function separator

%  disp('-------------------------------------------------------------------------------------------------------');
disp(' ');
