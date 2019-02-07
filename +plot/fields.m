% plot fields
function fields(fieldsStruct)
    % rowAxis = axisData(:, 1);
    % colAxis = axisData(:, 2);
    % rowAxis = 1:7;
    % colAxis = 1:6;
    nFields = length(fieldsStruct);

    isHold = ishold;
    if ~isHold
        hold on
    end
    for i = 1:nFields
        rowBins = fieldsStruct(i).row;
        colBins = fieldsStruct(i).col;
        % plot(colAxis(colBins), rowAxis(rowBins), 'w.');
        plot(colBins, rowBins, 'w.');
    end
    if ~isHold
        hold off
    end
end