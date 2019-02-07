function [CellClass, Distance] = CbClassify(Pha, Str)
% Function to classify unitentified cell as putative Cb+ and Cb-.
%
% Output of function is CellClass and Distance. CellClass = 1 means Cb+,
% CellClass = 0 means Cb-. Distance is the signed distance to the
% classification boundary.
%
% HOW TO USE - Example:
% Cell has Phase = 2.6, Strength = 0.45.
% To classify using Phase and Strength, call:
% [CellClass,Distance] = CbClassify(2.6,0.45)
%
% Function can also run on many cells, if they are passed as column vectors
% of e.g. Phases and Strengths. Example:
% [CellClass,Distance] = CbClassify([-3.0;2.7; 0.3],[O.5; 0.6; 0.1])
%
% Training set of identified Cb+ and Cb- cells are also available as an
% MS Excel sheet.
%
% _______________________________________ __
%
% This is a supplementary file to:
% Qiusong Tang*, Andrea Burgalossi*, Christian Laut Ebbesen*, Saikat Ray,
% Robert Naumann, Helene Schmidt, Dominik Spicher & Michael Brecht: Pyramidal and Stellate

% Cell-specificity of Grid and Border Representations in Layer 2 of Medial
% Entorhinal Cortex (2014).
%
% Affiliation:
% Bernstein Center for Computational Neuroscience
% Humboldt University of Berlin
% Philippstr. 13 Haus 6
% 10115 Berlin, Germany
%
% To whom correspondence should be addressed:
% andrea.burgalossi@bccn-berlin.de or michael.brecht@bccn-berlin.de
%
% You can redistribute it and/or modify it under the terms of the GNU
% General Public License as published by the Free Software Foundation.
%
% For the GNU General Public License, see <http://www.gnu.org/licenses/>.

%% Set the width of the guard zone for plotting
GuardZone = 0.1;

%% Load the Training data from identified recordings
loadFromDisc = true;
if loadFromDisc
    load('svmModel'); % variable svmStruct
else
    isCbPlus = [zeros(1, 22) ones(1, 9)]'; %#ok<*UNRCH>

    trainPhases = [1.23180000000000; 2.84190000000000; 1.58920000000000; 1.52430000000000; ...
        0.140370000000000; 2.36050000000000; -0.0628000000000000; 0.354300000000000; ...
        -1.06210000000000; -0.214200000000000; 1.08730000000000; -0.119960000000000; ...
        1.47140000000000; -0.313690000000000; 2.97240000000000; -1.22780000000000;  ...
        -1.04790000000000; 0.503910000000000; -0.692280000000000; 0.726910000000000; ...
        0.129940000000000; -2.58880000000000; -2.37750000000000; 2.70560000000000; ...
        -0.407180000000000; -2.58790000000000; 3.01640000000000; 2.44910000000000; ...
        2.99230000000000; 2.85600000000000; 2.41120000000000];

    trainStrength = [0.238000000000000; 0.840310000000000; 0.212710000000000; 0.468960000000000; ...
        0.447280000000000; 0.566630000000000; 0.157900000000000; 0.00730000000000000; ...
        0.338300000000000; 0.100400000000000; 0.158080000000000; 0.255220000000000; ...
        0.0817000000000000; 0.169220000000000; 0.194600000000000; 0.100700000000000; ...
        0.258960000000000; 0.265670000000000; 0.206230000000000; 0.167790000000000; ...
        0.159580000000000; 0.198700000000000; 0.284330000000000; 0.56983000000000; ...
        0.199520000000000; 0.253200000000000; 0.860950000000000; 0.748400000000000; ...
        0.580770000000000; 0.678460000000000; 0.21168000000000];

    % Calculate the training set for the classifier using phase and theta strength
    TrainingSet = [cos(trainPhases).*trainStrength, sin(trainPhases).*trainStrength];
    % Train the classifier
    svmStruct = svmtrain(TrainingSet, isCbPlus, 'kernel_function', 'rbf'); %#ok<*USENS>
end

%% Classify cells using Pha & Str

% Calculate the features of the cell to be classified
Cell = [cos(Pha).*Str sin(Pha).*Str];

% Classify the cell
CellClass = svmclassify(svmStruct, Cell); %#ok<*NODEF>

% Calculate the distance to the classification boundary
SampleScaleShift = bsxfun(@plus, Cell, svmStruct.ScaleData.shift);
CellScaled = bsxfun(@times, SampleScaleShift, svmStruct.ScaleData.scaleFactor);
sv = svmStruct.SupportVectors;
alphaHat = svmStruct.Alpha;
bias = svmStruct.Bias;
kfun = svmStruct.KernelFunction;
kfunargs = svmStruct.KernelFunctionArgs;
Distance = kfun(sv, CellScaled, kfunargs{:})' * alphaHat(:) + bias;

% % Colors for plotting
% Black = [0 0 0];
% DarkGrey = 0.6602 * ones(1, 3);
% PaleGreen = [.5938 .9833 .5938];
% Red = [1 0 0];
% Gold = [1 .8398 0];
% White = [1 1 1];
% 
% figure();
% set(gcf, 'PaperUnits', 'centimeters');
% xSize = 15; ySize = 15;
% xLeft = (21 - xSize)/2;
% yTop = (30 - ySize)/2;
% set(gcf, 'paperposition', [xLeft yTop xSize ySize]);
% X = 100;
% Y = 100;
% set(gcf, 'Position', [X Y xSize*50 ySize*50]);
% set(gca, 'TickDir', 'out');
% hold on;
% 
% % make a big matrix to plot the area
% rangesMax = [1.1 1.1];
% rangesMin = -1 * rangesMax;
% xRange = linspace(rangesMin(1), rangesMax(1), 1000);
% yRange = linspace(rangesMin(2), rangesMax(2), 1000);
% [xx, yy] = meshgrid(xRange, yRange);
% gridSamples = [xx(:), yy(:)];
% 
% % classify the big matrix
% gridLabels = svmclassify(svmStruct, gridSamples);
% xDisp = reshape(xx, 1000, 1000);
% yDisp = reshape(yy, 1000, 1000);
% 
% % Calculate the distance to the classification boundary
% SampleScaleShift = bsxfun(@plus, gridSamples, svmStruct.ScaleData.shift);
% CellScaled = bsxfun(@times, SampleScaleShift, svmStruct.ScaleData.scaleFactor);
% MapDistance = kfun(sv, CellScaled, kfunargs{:})' * alphaHat(:) + bias;
% 
% % set the color map for guard zone plotting here
% guardLogic = abs(MapDistance) < GuardZone | sqrt(sum(gridSamples.^2, 2)) > 1;
% gridLabels(guardLogic) = 0.5;
% labelDispGuard = reshape(gridLabels, 1000, 1000);
% 
% % plot the matrix using labelDisp as colormap
% [ch, ch] = contourf(xDisp, yDisp, labelDispGuard);
% set(ch, 'edgecolor', 'none');
% set(gcf, 'colormap', [DarkGrey; White; PaleGreen]);
% 
% plot([rangesMin(1) rangesMax(1)], [0 0], '-k');
% plot([0 0], [rangesMin(1) rangesMax(1)], '-k');
% axis square;
% 
% % add sun
% th = 0:0.005:2*pi;
% for i = 0.2:0.2:0.8
%     plot(i*cos(th), i*sin(th), ':k');
% end
% plot(cos(th), sin(th), 'k');
% 
% % Plot the non-ident cell and color them
% for i = 1:size(Cell, 1)
%     h = scatter(Cell(i, 1), Cell(i, 2), 90);
%     faceColor = Gold;
%     if Distance(i) > 0
%         faceColor = Gold;
%     elseif Distance(i) < 0
%         faceColor = Red;
%     end
% 
%     if abs(Distance(i)) < GuardZone
%         faceColor = White;
%     end
% 
%     set(h, 'MarkerEdge', Black, ...
%         'MarkerFaceColor', faceColor, ...
%         'LineWidth', 1);
% end
% 
% % Add axis labels
% xlabel('$\cos(\phi) \times S$', 'interpreter', 'latex', 'fontsize', 20);
% ylabel('$\sin(\phi) \times S$', 'interpreter', 'latex', 'fontsize', 20);
% 
% xlim([rangesMin(1) rangesMax(1)]);
% ylim([rangesMin(1) rangesMax(1)]);
% 
% axis square;

end
