% Save image on disc.
%
% Save image on disc in a desirable format.
%
%  USAGE
%
%    saveImage(figHandle, format, figFile, dpi)
%
%    figHandle          Figure handle, i.e. figure(1)
%    format             Format of an image file. Possible values:
%                       'bmp' 24 bit
%                       'png'
%                       'eps'
%                       'jpg'
%                       'tiff' 24 bit
%                       'fig' Matlab figure
%                       'pdf'
%                       'svg'
%    figFile            Full path to the output file. Can be without the extension, i.e.
%                       C:\data\file. If you provide extension, be sure it matches
%                       image format.
%    dpi                DPI settings for image, integer.
%
function saveImage(figHandle, format, figFile, dpi)
    if iscell(format)
        checkResults = cellfun(@(x) ~helpers.isstring(x, 'bmp', 'png', 'eps', 'jpg', 'tiff', 'fig', 'pdf', 'svg'), format);
        if any(checkResults)
            error('One of your image format values is invalid.');
        end
    else
        if ~helpers.isstring(format, 'bmp', 'png', 'eps', 'jpg', 'tiff', 'fig', 'pdf', 'svg')
            error('Invalid image format value.');
        end
    end

    warning('off', 'export_fig:transparency');

    % Make the background of the figure white
    set(figHandle, 'color', [1 1 1]);

    % if we have a dot as last character in the file name -> remove it
    % Dot will result in errors, because print functions expect format after dot.
    if figFile(end) == '.'
        figFile(end) = [];
    end
    visibilityChanged = false;

    strDpi = sprintf('-r%u', dpi);
    if iscell(format)
        needFig = strcmpi(format, 'fig');
        if any(needFig)
            visibility = get(figHandle, 'Visible');
            if strcmpi(visibility, 'off')
                % set visibility to on, otherwise users will not see a
                % figure when they open it
                set(figHandle, 'Visible', 'on');
                visibilityChanged = true;
            end
            saveas(figHandle, figFile, 'fig');
            format(needFig) = [];
        end

        needSvg = strcmpi(format, 'svg');
        if any(needSvg)
            dfmt = '-dsvg';
            print(figHandle, dfmt, figFile, strDpi);
            format(needSvg) = [];
            strDpi = sprintf('%s%u','-r', dpi);
        end

        dfmt = cellfun(@(x) strcat('-', x), format, 'uniformoutput', false);
        export_fig(figFile, '-a1', strDpi, dfmt{:});
    else
        dfmt = sprintf('-%s', format);
        if strcmpi(format, 'fig')
            visibility = get(figHandle, 'Visible');
            if strcmpi(visibility, 'off')
                % set visibility to on, otherwise users will not see a
                % figure when they open it
                set(figHandle, 'Visible', 'on');
                visibilityChanged = true;
            end
            saveas(figHandle, figFile, format);
            if visibilityChanged
                set(figHandle, 'Visible', 'off');
            end
            return
        end
        if helpers.isstring(format, 'svg')
            strDpi = sprintf('-r%u', dpi);
            dfmt = sprintf('-d%s', format);
            print(figHandle, dfmt, figFile, strDpi);
            return;
        end
        export_fig(figFile, '-a1', strDpi, dfmt);
    end
    if visibilityChanged
        set(figHandle, 'Visible', 'off');
    end
end
