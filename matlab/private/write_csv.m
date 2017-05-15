function write_csv(filename,data,varargin)
% write_csv     a CSV/delimited writer that can handle strings!
%
% This function writes CSV/delimited files.  This differs from dlmwrite and csvwrite
% in that it can handle strings and that you can/must provide a format string
% similar to textscan.
%
% usage: write_csv(filename,data,varargin)
%  filename = string containing the filename to write to
%  data = Can be a struct or a 2D matrix
%    Struct: a struct containing fields to write out to the file.
%    fields should have the same number of elements.  Strings
%    are allowed to be stored in character arrays with first dimension
%    having being the "record" dimension.  Note that if a field (not a
%    2D char array) is a MxN matrix, then the data is unraveled by 
%    data.field(:).
%    2D Matrix: The columns in the 2D matrix will come out as columns in 
%    the text file when viewed normally.  Note that fieldnames will 
%    automatically be generated ('field_%03i') so you may want to either turn off 
%    'write_header' or else specify 'manual_header'.
%
% optional parameters:
%
% fld_order = NaN;  Can be NaN or else a cell array of fieldnames of data.  If NaN,
%                   then all fields in data are stored in the order they appear in
%                   in the structure.  If a cell array of fieldnames, then the order
%                   of the columns is dictated by the order.  
% write_header = 1; If 1, then the first row of the file contains the fieldnames.  If
%                   0, then no header is stored.
% manual_header = '';  If write_header is 1 and this field is not empty, then it will be
%                   used for the header line.
% delimiter = ',';  Delimiter to be used between fields.
% format = '';      If given, then the format should be a format string a la fprintf or a struct.  
%                   String option:
%                   There needs to be the same number of outputs (like %f or %s) for each column 
%                   to be written.  If not given (empty), then 'default_string_format' will be used 
%                   for cells and chararrays and 'default_numeric_format' is used for numeric data.  
%                   In general, good choices are %g for numbers and %s for strings.
%                   e.g. '%g%g%g%05i%s'  Note that the delimiters will be added before
%                   every '%' except for the first.  Note that delimiter can be set to
%                   '' and the format string can be used to put the delimiters in.
%                   e.g. '%g,%g,%g,%05i,"%s"'. 
%                   Struct option:
%                   A more useful form is this can be a struct with fields a subset of the fields 
%                   to be written out, and corresponding value a string format 
%                   (e.g. 'format',struct(time,'%0.8g')).  This form is useful for overriding 
%                   specific fields.  Any field not specified will use the default numeric/string
%                   format.
%                   Note that the delimiters will be added between.  Note that delimiter can be set to
%                   '' and the format strings can then contain the delimiter at the end (Except probably
%                   the last one. e.g. struct('a','%g,','b','%g,','c','%g,','d','%05i,','e','"%s"');
% assume_all_numbers = 0; [DEPRECATED - this is now auto-detected]  
%                   If 1, then all fields are assumed to be numbers which allow
%                   the data to be written more quickly.  
% append = 0;       If 1, then the data is appended to the file.  Otherwise, the data 
%                   inside the file is removed.
% safe_mode = 1;    If 1, and the file already exists and append is 0, then an error will
%                   be given to prevent from overwriting existing files.  If 0, and 
%                   append is 0, then existing files will be clobbered.  Data can always 
%                   appended.
% default_numeric_format = '%g'; change the default numeric format for numeric data
% default_string_format = '%s'; change the default string format for char arrays/cell arrays of strings
%
%  STORED PRECISION:
%   Generally, %g is used to save numbers which will typically store about 5 digits or precision.
%   This is typically enough for almost all applications.  However, if you need higher precision,
%   then you can up the precision though use of the 'format' option.  If needed, you can also/instead
%   change all the precisions for all numeric and/or string fields through use of 
%   default_numeric_format and default_string_format.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 



fld_order = NaN;

write_header = 1;
manual_header = '';

delimiter = ',';
format = '';

assume_all_numbers = 0;

append = 0;
safe_mode = 1; 

default_numeric_format = '%g';
default_string_format = '%s';

convert_nans = 0;
nan2val = '';

paramparse(varargin);

% arg check

% make sure a format is given is not assume_all_numbers
%if ~assume_all_numbers && isempty(format)
%  error('if assume_all_numbers is 0 then format must be given')
%end

if isnumeric(data)
  if ndims(data)==2
    flds = icellfun(num2cell(1:size(data,2)),@(x) sprintf('field_%03i',x));
  end
  data = cell2struct(num2cell(data,1),flds,2);
end

% check that there are fields to write
flds = fieldnames(data);
if length(flds)==0
  error('No data');
end

% if no fld_order given create a default
if isnumeric(fld_order) 
  fld_order = flds;
end

% if not do a quick check and maybe turn it on.
aan = 1;
for ll = 1:length(fld_order)
  if ~isnumeric(data.(fld_order{ll}))
    aan = 0;
    break;
  end
end
assume_all_numbers = aan;

% Need to determine the number of elements
% get numel from a cell or numeric field
% or get first dimension from a character array
ll = 1;
while 1
  if isnumeric(data.(fld_order{ll})) || iscell(data.(fld_order{ll}))
    len = numel(data.(flds{ll}));
    break
  elseif ischar(data.(fld_order{ll}))
    len = size(data.(flds{ll}),1);
    break
  end
  ll = ll + 1;
  if ll>length(fld_order)
    error('No appropriate fields found');
  end
end

% if the format is empty (and therefore assume_all_numbers == 1)
% default to '%g's
if isempty(format) && assume_all_numbers
  format = repmat({default_numeric_format},1,length(fld_order));
elseif isempty(format)
  % otherwise, if empty but not assume all numbers, then just figure it out
  % based on the type
  for ll = 1:length(fld_order)
    if isnumeric(data.(fld_order{ll})) || islogical(data.(fld_order{ll}))
      format{ll} = default_numeric_format;
    elseif iscell(data.(fld_order{ll})) || ischar(data.(fld_order{ll})) 
      format{ll} = default_string_format;
    end
  end
else
  % otherwise it is specified
  if ischar(format)
    % if it is a char, we just need to make sure the lengths match
    format = regexp(format,'%[^%]+','match');
    if length(format)~=length(fld_order)
      error('the format string must have the same number of elements as there are fields in ''data''');
    end
  else
    % must be a structure
    for ll = 1:length(fld_order)
      if isfield(format,fld_order{ll})
        % if the field is specified, use it, otherwise just use the default
        tmpformat{ll} = format.(fld_order{ll});
      elseif isnumeric(data.(fld_order{ll})) || islogical(data.(fld_order{ll}))
        tmpformat{ll} = default_numeric_format;
      elseif iscell(data.(fld_order{ll})) || ischar(data.(fld_order{ll})) 
        tmpformat{ll} = default_string_format;
      end
    end
    format = tmpformat;
    
  end
end

% splice together with the dlimiter and add the carriage return
format = [char2delimiter(format,delimiter) sprintf('\n')];

if assume_all_numbers
  % in this case, we can just make a double array to output the data.
  outdata = repmat(NaN,len,length(fld_order));

  % pull the data into outdata and populate the header
  for ll = 1:length(fld_order)
    if isfield(data,fld_order{ll}) && numel(data.(fld_order{ll}))==len
      outdata(:,ll) = data.(fld_order{ll});
      header{ll} = fld_order{ll};
    else
      warning(sprintf('''%s'' is being skipped because either it is not a field, or the number of elements is not the same as the rest of the data',fld_order{ll}));
      header{ll} = '';
    end
  end;

  % open the file
  fid = fileopen(filename,append,safe_mode);
  
  try
    % write the header
    if write_header
      if isempty(manual_header)
        fprintf(fid,'%s\n', char2delimiter(header,delimiter));
      else
        fprintf(fid,'%s\n', manual_header);
      end        
    end
    
    % write the data
    if convert_nans
      s = sprintf(format,outdata.');
      s = regexprep(s,sprintf('(%s|^|\n)NaN($|%s|\n)',delimiter,delimiter),sprintf('$1%s$2',nan2val));
      s = regexprep(s,sprintf('(%s|^|\n)NaN($|%s|\n)',delimiter,delimiter),sprintf('$1%s$2',nan2val));
      fprintf(fid,'%s',s);
    else
      fprintf(fid,format,outdata.');
    end
  catch ME
    % on error close the file
    fclose(fid);
    rethrow(ME);
  end
  fclose(fid);
else
  
  % if not all numbers, we need to deal with cell arrays
  outdata = repmat({''},len,length(fld_order));
  
  if len>0
    for ll = 1:length(fld_order)
      if isfield(data,fld_order{ll}) && (numel(data.(fld_order{ll}))==len || (ischar(data.(fld_order{ll})) && size(data.(fld_order{ll}),1)==len && length(size(data.(fld_order{ll})))==2))
        % if the data is viable (exists and correct size) then populate into the cell array
        if ischar(data.(fld_order{ll})) && size(data.(fld_order{ll}),1)==len && length(size(data.(fld_order{ll})))==2
          % char arrays need to be num2cell'ed into len elements
          outdata(:,ll) = num2cell(data.(fld_order{ll}),2);
        elseif iscell(data.(fld_order{ll}))
          % if is cell, then no num2cell is necessary
          outdata(:,ll) = data.(fld_order{ll});
        else
          % if numeric, then it needs to be broken into len elements
          outdata(:,ll) = num2cell(data.(fld_order{ll}));
        end
        header{ll} = fld_order{ll};
      else
        warning(sprintf('''%s'' is being skipped because either it is not a field, or the number of elements is not the same as the rest of the data',fld_order{ll}));
        header{ll} = '';
      end
    end;
  else
    outdata = [];
  end

  % open file
  fid = fileopen(filename,append,safe_mode);
  
  try
    % write header
    if write_header
      if isempty(manual_header)
        fprintf(fid,'%s\n', char2delimiter(header,delimiter));
      else
        fprintf(fid,'%s\n', manual_header);
      end        
    end
    
    if ~isempty(outdata)
      % write out the data
      outdata = outdata.';
      
      if convert_nans
        s = sprintf(format,outdata{:});
        s = regexprep(s,sprintf('(%s|^|\n)NaN($|%s|\n)',delimiter,delimiter),sprintf('$1%s$2',nan2val));
        s = regexprep(s,sprintf('(%s|^|\n)NaN($|%s|\n)',delimiter,delimiter),sprintf('$1%s$2',nan2val));
        fprintf(fid,'%s',s);
      else
        fprintf(fid,format,outdata{:});
      end
    end
  catch ME
    % on error, close file
    fclose(fid);
    rethrow(ME);
  end
  % close file
  fclose(fid);
end

return

function id = fileopen(fn,append,safe_mode)
% support function to open the file or error depending to append and safemode
if exist(fn,'file') && ~append && safe_mode
  error(sprintf('"%s" already exists',fn));
end
if append
  id = fopen(fn,'at');
else
  id = fopen(fn,'wt');
end  

function out = char2delimiter(s,delim)
out = sprintf(['%s' delim],s{:});
out = out(1:end-length(delim));
