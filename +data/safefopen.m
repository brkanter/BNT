classdef safefopen < handle
    % safefopen - Class to work with files in a safe manner.
    %
    % Open a file handle and close it in the background when it is no longer in use.
    % Prevent access locks when user opens a file and then forget to close it or an exception occurs.
    %
    %  USAGE
    %   fid = data.safefopen(filename, 'w');
    %   fprintf(fid, '%u', 1);
    %
    % safefopen Methods: (which are wrappers over standard file functions like fwrite, fread, e.t.c.)
    %   fwrite
    %   fread
    %   fprintf
    %   fseek
    %   feof

    properties(Access = private)
        fid; % internal file handler.
    end
    properties(Access = public)
        name = ''; % name of the openned file
    end

    methods(Access=public)
        function this = safefopen(fileName, varargin)
            % Open file in a safe manner and return an object that could be further used to access the file.

            this.fid = fopen(fileName, varargin{:});
            if this.fid == -1
                error('Failed to open file %s', fileName);
            end
            this.name = fileName;
        end

        function fwrite(this, varargin)
            % Wrapper over fwrite. See also FWRITE.
            fwrite(this.fid, varargin{:});
        end

        function [A, count] = fread(this, varargin)
            % Wrapper over fread. See also FREAD.
            [A, count] = fread(this.fid, varargin{:});
        end

        function tline = fgetl(this)
            % Wrapper over fgetl. See also FGETL.
            tline = fgetl(this.fid);
        end

        function tline = fgets(this, varargin)
            % Wrapper over fgets. See also FGETS
            tline = fgets(this.fid, varargin{:});
        end

        function fprintf(this, varargin)
            % Wrapper over fprintf. See also FPRINTF.
            fprintf(this.fid, varargin{:});
        end

        function status = fseek(this, varargin)
            % Wrapper over fseek. See also FSEEK.
            status = fseek(this.fid, varargin{:});
        end

        function status = feof(this, varargin)
            % Wrapper over feof. See also FEOF.
            status = feof(this.fid, varargin{:});
        end

        function position = ftell(this, varargin)
            % Wrapper over ftell. See also FTELL.
            position = ftell(this.fid, varargin{:});
        end

        function status = fclose(this)
            if this.fid == -1
                return;
            end
            status = fclose(this.fid);
            if status == 0
                this.fid = -1;
                this.name = '';
            end
        end

        function [A, count] = fscanf(this, varargin)
            % Wrapper over fscanf. See also FSCANF.
            [A, count] = fscanf(this.fid, varargin{:});
        end

        function [C, position] = textscan(this, varargin)
            [C, position] = textscan(this.fid, varargin{:});
        end

        function [str, lineCounter] = readNextNonEmptyLine(this, lineCounter)
            % Read file until the next non empty line and return it
            %
            % This function reads the current line and if it is empty continues
            % to read the file until either non-empty line is read or the end of the
            % file is reached.
            % Line number could be tracked through the lineCounter argument.
            % lineCounter should be a number, which would be incremented each time
            % an any line is read.

            % We do not check if this.fid is valid or not. This is done to save
            % some processing time.

            str = fgetl(this.fid);
            lineCounter = lineCounter + 1;
            while isempty(str) && ischar(str)
                str = fgetl(this.fid);
                lineCounter = lineCounter + 1;
            end
        end

        function delete(this)
            % Destructor, which closes the internal file handle.
            if this.fid ~= -1
                fclose(this.fid);
            end
        end
    end

end
