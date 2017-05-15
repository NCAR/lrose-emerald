function data = read_csv(filename,varargin)
% read_csv   Read a CSV file
%
% this differs from MATLAB's csv file reader in that it can handle text
% fields.  It can also handle ""'s around field values.
%
%  [d,format]  = read_csv(filename,'param1',value1,...)
%
% options:
%   field_name_line = 0; % line that has fieldnames.  If 0 (or less)
%     then the fieldnames will just be field01, etc,  Note that
%     this is relative to the beginning of the file (not skip_lines).
%     field_name_line should always be less than skip_lines.  Also, note
%     that usually you will want to skip this line as well by setting
%     skip_lines.  This line can be a commented line (comment string will be
%     removed).
%   skip_lines = 0; % number of lines to skip at the beginning when
%     reading the DATA.  
%   delim = ','; % delimiter for the csv.  Can be a string, the whole of which is
%     the delimiter.  Or it can be a cell array of strings, each of which are 
%     considered delimiters.  Do not use regular expressions.  For white space
%     use {' ','\b','\t'}
%   ignore_repeated_delims = 0; %  If 1, then will ignore repeated delimiters.
%     This is especially useful for whitespace delimited files.
%   comment_str = '';  If non-empty, this will skip all data lines that start
%     with this string.  Note that the field_name_line can start with the comment
%     string.  The leading comment strings will be ignored.
%   max_lines = [];  %If not empty, should be a number to specify the number of lines 
%     to read.
%   header_transform_fun = @(x) x; Function handle of function that will transform
%     fieldnames.  You can oreride this, providing your own function, that takes
%     a string as an input, and outputs a matlab valid field name.  The default is to
%     do nothing.  An example alternative is to use @strtrim to remove begining and
%     trailing whitespace in the case of space delimited data.
%
%   format = ''; The format string used by textscan.  If empty, read_csv will attempt 
%     to figure it out.  See textscan.  Providing this can be faster, and more 
%     repeatable, but less flexible.
%   assume_all_numbers = 0; % if 1, this will use a format of '%f's for each field.
%     This can substantially speed things up if you know ALL data in the file (besides
%     comments and headers) are numbers or NaN, Inf and also need no replace_expressions.
%   skip_non_numeric = 0; % Non-numeric columns can be ignored if this is turned to 1
%   replace_expressions = {}; % a cell array of 1x2 cellarrays.
%     example to convert NULL's to NaN's, and ^D's to nothing.
%     { {'NULL' 'NaN'} {char(4) ''} }
%
%   % Field Naming issues
%   name_transform_fun = @lower; Function handle of function that will transform
%     fieldnames.  You can oreride this, providing your own function, that takes
%     a string as an input, and outputs a matlab valid field name.  Another
%     common choice is simply to do nothing:    @(x) x
%   fieldname_strip_chars = '/-."'' (){}[]'; % characters to be stripped out of
%     field names when converted to a struct.
%   rename_map = struct; % Struct which specifies how to rename field names.  This
%     is performed after duplicates are handled.  the struct format is as follows:
%     rename_map.old_name = 'new_name';  For example:
%     ...,'rename_map',struct('old_name1','new_name1','old_name2','new_name2',...),...
%
%   verbose = 0; % if 1 or greater, the info is printed.  Larger numbers
%     output more info.
%
% examples:
%   space delimited, with header on line 1.
%   >> type csv_ex1.csv
%   >> d = read_csv('csv_ex1.csv','field_name_line',1,'skip_lines',1,'delim',{' ','\t'},'ignore_repeated_delims', 1);
%   space delimited, with header on line 2, with comments.
%   >> type csv_ex2.csv
%   >> d = read_csv('csv_ex2.csv','field_name_line',2,'skip_lines',2,'delim',{' ','\t'},'ignore_repeated_delims', 1,'comment_str','#');
%   comma delimited, with header on line 2, skipping bad stuff on line 1, with comments.
%   >> type csv_ex3.csv
%   >> d = read_csv('csv_ex3.csv','field_name_line',2,'skip_lines',2,'delim',',','comment_str','#');
%   space delimited, with header on line 2 that has (annoying) extra leading spaces, with comments.
%   >> type csv_ex3.csv
%   >> d = read_csv('csv_ex4.csv','field_name_line',2,'skip_lines',2,'delim',{' ','\t'},'ignore_repeated_delims', 1,'comment_str','#');

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 




%%% TODO add ability to use comments


field_name_line = 0;
skip_lines = 0;
delim = ',';
ignore_repeated_delims = 0;

verbose = 0;
%unix_read_pipe = '';
fieldname_strip_chars = '/-."'' (){}[]%;=+';
comment_str = '';

%version = 1;
replace_expressions = {};
skip_non_numeric = 0;
rename_map = struct;

max_lines = [];
format = '';
assume_all_numbers = 0;

header_transform_fun = @(x) x;
name_transform_fun = @lower;

paramparse(varargin);

if verbose
  fprintf('Getting the number of fields from first data line: ');
end
fid = fopen(filename,'rt');

for ll = 1:skip_lines
  dummy = fgetl(fid);
end

dat = fgetl(fid);
fclose(fid);

if isnumeric(dat)
  count = NaN;
else
  count = length(regexp(dat,delim))+1;
end

if verbose
  fprintf('%i\n',count);
end

if field_name_line>0
  if verbose
    fprintf('Getting the field names from field_name_line\n');
  end
  fid = fopen(filename,'rt');
  
  for ll = 1:field_name_line-1
    dummy = fgetl(fid);
  end
  
  header = fgetl(fid);
  fclose(fid);
  
  if verbose>1
    fprintf('raw header: %s\n',header);
  end
  % if there is a comment string, remove leading comments strings from header
  if ~isempty(comment_str)
    tmp = strtrim(header);
    inds = strfind(tmp,comment_str);
    while length(inds)>0 && inds(1)==1
      tmp = tmp(length(comment_str)+1:end);
      inds = strfind(tmp,comment_str);
    end
    header = tmp;

    if verbose>1
      fprintf('comment removed header: %s\n',header);
    end

  end

  % create a delimiter regexp string to break on
  if iscell(delim)
    tmpdlm = sprintf('%s|',delim{:});
    tmpdlm = ['(' tmpdlm(1:end-1) ')'];
    if ignore_repeated_delims
      tmpdlm = [tmpdlm '+'];
    end
  else
    tmpdlm = delim;
    if ignore_repeated_delims
      tmpdlm = ['(' tmpdlm ')+'];
    end
  end
  
  header = regexp(header_transform_fun(header),tmpdlm,'split');

  for ll = 1:length(header)
    if isempty(strip(header{ll},fieldname_strip_chars))
      header{ll} = sprintf('field_%02i',ll);
    else
      header{ll} = strip(name_transform_fun(header{ll}),fieldname_strip_chars);
    end;  
  end
else
  header = icellfun(num2cell(1:count),@(x) sprintf('field_%02i',x));
end

header = handle_dups(header);
for ll = 1:length(header)
  if isfield(rename_map,header{ll})
    header{ll} = rename_map.(header{ll});
  end
end

if verbose>1
  fprintf('Fields:\n');
  fprintf('  %s\n',header{:});
end

% Deal with case where there is no data.  Just return an empty struct of some kind
if isnan(count)
  if length(header)>1
    data = cell2struct(cell(size(header(:))),header(:),1);
  else
    data = struct;
  end
  return
end

% set up function call
if isempty(max_lines)
  max_lines = {};
else
  max_lines = {max_lines};
end

if assume_all_numbers
  format = repmat('%f',1,length(header));
end

if isempty(format)
  string = repmat('%q',1,length(header));
else
  string = format;
end

if ~isempty(comment_str)
  comment_str = {'CommentStyle',comment_str};
else
  comment_str = {};
end

fid = fopen(filename,'rt');
tmpdata = textscan(fid,string,max_lines{:},'ReturnOnError',0,...
                   'delimiter',delim,'headerlines',skip_lines,'emptyvalue',NaN,...
                   comment_str{:},'MultipleDelimsAsOne',ignore_repeated_delims);
fclose(fid);

% if needed, diagnose whether data can be turned into numeric type
if isempty(format)
  num_lines = length(tmpdata{1});
  for ll = 1:length(header)
    str = [sprintf('%s\n',tmpdata{ll}{1:end-1}) tmpdata{ll}{end}];
    for kk = 1:length(replace_expressions)
      str = strrep(str,replace_expressions{kk}{:});
    end
    tmp = sscanf(str,'%f');
    if abs(length(tmp)-num_lines)>0
      if verbose
        fprintf('  Only able to read %i lines as numbers\n',length(tmp));
        if verbose>1
          tmpc = regexp(o,sprintf('\n'),'split');
          inds = (-1:1) +length(tmp);
          inds = inds(inds>=1 & inds<=length(tmpc));
          fprintf('  %s\n',tmpc{inds});
        end
        if skip_non_numeric
          fprintf('  Skipping cell array\n');
        else
          fprintf('  Saving as cell array\n');
        end
      end
      if skip_non_numeric
        continue
      else
        data.(header{ll}) = tmpdata{ll};
      end
    else
      if verbose>1
        fprintf('  Saving as double\n');
      end
      data.(header{ll}) = tmp;
    end
  end
else
  % otherwise just copy the data in.
  for ll = 1:length(header)
    data.(header{ll}) = tmpdata{ll};
  end  
end
  
function x = strip(x,chars)

for l = 1:length(chars)
  x = strrep(x,chars(l),'');
end;

function h = handle_dups(h)
% this just tries to deal with duplicates by renaming them.  The user should really 
% just try to deal with this in the query, but this is a good fallback.  User should
% beware that duplicate handling is brittle.

% find the unique field names 'u' and find the mapping from h to 'u'
[u,~,h_inds] = unique(h);
% now, count how many each u has
ct = hist(h_inds,1:length(u));

% find the problems
nonunique = find(ct>1);
% loop over the problem fields
for ll = 1:length(nonunique)
  % find the inds in h that correspond to nonunique(ll)
  inds = find(strcmp(u{nonunique(ll)},h));
  for kk = 2:length(inds)
    new_fld = sprintf('%s_%02i',h{inds(kk)},kk);
    if ~strcmp(new_fld,h)
      warning(sprintf('Renaming "%s"[%i] to "%s"',h{inds(kk)},kk,new_fld));
      h{inds(kk)} = new_fld;
    else
      error('Duplicate field.  Attempt to rename "%s" failed because there is already "%s".',h{inds(kk)},new_fld);
    end
  end
end
return


% $$$ switch version
% $$$  case 1 %version that uses unix/awk/wc to work. % has problems with the end of cells
% $$$   [r,num_lines] = unix(sprintf('wc -l %s',filename));
% $$$   num_lines = sscanf(num_lines,'%i');
% $$$   num_lines = num_lines-skip_lines;
% $$$   if verbose
% $$$     fprintf('%i\n',num_lines);
% $$$   end
% $$$ 
% $$$   unix_read_pipe = strtrim(unix_read_pipe);
% $$$   if ~isempty(unix_read_pipe) &&  unix_read_pipe(1)~='|'
% $$$     unix_read_pipe = ['| ' unix_read_pipe];
% $$$   end  
% $$$   
% $$$   for ll = 1:count
% $$$     if verbose
% $$$       fprintf('Reading %s\n',header{ll});
% $$$     end
% $$$     [r,o] = unix(sprintf('awk -F, ''{print $%i}'' %s | tail -n +%i %s',ll,filename,skip_lines+1,unix_read_pipe));
% $$$     if verbose>1
% $$$       fprintf('  Determining if can convert to double\n');
% $$$     end
% $$$     tmp = sscanf(o,'%f');
% $$$     if abs(length(tmp)-num_lines)>1
% $$$       if verbose
% $$$         fprintf('  Only able to read %i lines as numbers\n',length(tmp));
% $$$         if verbose>1
% $$$           tmpc = regexp(o,sprintf('\n'),'split');
% $$$           inds = (-1:1) +length(tmp);
% $$$           inds = inds(inds>=1 & inds<=length(tmpc));
% $$$           fprintf('  %s\n',tmpc{inds});
% $$$         end
% $$$         fprintf('  Saving as cell array\n');
% $$$       end
% $$$       data.(header{ll}) = reshape(regexp(o,sprintf('\n'),'split'),[],1);
% $$$     else
% $$$       if verbose>1
% $$$         fprintf('  Saving as double\n');
% $$$       end
% $$$       data.(header{ll}) = tmp;
% $$$     end
% $$$   end
% $$$  case 2 % case that uses textscan, initially with %f, then adding %q as needed  DOES NOT WORK
% $$$   ok = 0;
% $$$   fid = fopen(filename,'rt');
% $$$   str = fscanf(fid,'%c');
% $$$   fclose(fid);
% $$$   string_num = [];
% $$$   for ll = 1:length(replace_expressions)
% $$$     str = strrep(str,replace_expressions{ll}{:});
% $$$   end
% $$$   while ~ok
% $$$     % Sets the format to all %f
% $$$     string = repmat('%f',1,length(header));
% $$$     % If a string was found in the previous run through the loop
% $$$     % replace the 'f' with an 's' at the correct location (2*string_num)
% $$$     %string(2*string_num) = 's'
% $$$     string(2*string_num) = 'q';
% $$$     % Try to read in the entire line, if a string is found it will be caught
% $$$     try   
% $$$       data = textscan(str,string,'ReturnOnError',0,...
% $$$                           'delimiter',delim,'headerlines',skip_lines,'emptyvalue',NaN);
% $$$       ok = 1;
% $$$       % Found a string
% $$$     catch
% $$$       % The error listed indicates the column ('field') of the string
% $$$       s = lasterr;
% $$$       ind = findstr('field',s);
% $$$       if isempty(ind)
% $$$         error(sprintf('Not sure why this crashed: %s',s));
% $$$       end;
% $$$       % string_num is an array indicating which columns had strings
% $$$       string_num(end+1) = sscanf(s((ind(1) + length('field')):end), ...
% $$$                                  '%i',1);
% $$$       fprintf('Found a string in column %i\n',string_num(end));
% $$$ 
% $$$     end;
% $$$   end;
% $$$   data = cell2struct(data,header,2);
% $$$  case 3 % case that uses textscan using %q, then tries to convert to %f
% $$$   ok = 0;
% $$$   fid = fopen(filename,'rt');
% $$$   string = repmat('%q',1,length(header));
% $$$   tmpdata = textscan(fid,string,'ReturnOnError',0,...
% $$$                   'delimiter',delim,'headerlines',skip_lines,'emptyvalue',NaN);
% $$$   fclose(fid);
% $$$   num_lines = length(tmpdata{1});
% $$$   for ll = 1:length(header)
% $$$     str = [sprintf('%s\n',tmpdata{ll}{1:end-1}) tmpdata{ll}{end}];
% $$$     for kk = 1:length(replace_expressions)
% $$$       str = strrep(str,replace_expressions{kk}{:});
% $$$     end
% $$$     tmp = sscanf(str,'%f');
% $$$     if abs(length(tmp)-num_lines)>1
% $$$       if verbose
% $$$         fprintf('  Only able to read %i lines as numbers\n',length(tmp));
% $$$         if verbose>1
% $$$           tmpc = regexp(o,sprintf('\n'),'split');
% $$$           inds = (-1:1) +length(tmp);
% $$$           inds = inds(inds>=1 & inds<=length(tmpc));
% $$$           fprintf('  %s\n',tmpc{inds});
% $$$         end
% $$$         fprintf('  Saving as cell array\n');
% $$$       end
% $$$       data.(header{ll}) = tmpdata{ll};
% $$$     else
% $$$       if verbose>1
% $$$         fprintf('  Saving as double\n');
% $$$       end
% $$$       data.(header{ll}) = tmp;
% $$$     end
% $$$   end
% $$$  case 4 % case that uses textscan like 3 except loads altogether
% $$$   % and then repeats for each field.  SLOW.
% $$$   ok = 0;
% $$$   fid = fopen(filename,'rt');
% $$$   tmpstr = fscanf(fid,'%c');
% $$$   fclose(fid);
% $$$   for kk = 1:length(replace_expressions)
% $$$     tmpstr = strrep(tmpstr,replace_expressions{kk}{:});
% $$$   end
% $$$ 
% $$$   for ll = 1:length(header)
% $$$     string = repmat('%*q',1,length(header));
% $$$     ind = (ll-1)*3+2;
% $$$     string = string([1:ind-1 ind+1:end]);
% $$$     tmpdata = textscan(tmpstr,string,'ReturnOnError',0,...
% $$$                        'delimiter',delim,'headerlines',skip_lines,'emptyvalue',NaN);
% $$$     tmpdata = tmpdata{1};
% $$$     num_lines = length(tmpdata);
% $$$     str = [sprintf('%s\n',tmpdata{1:end-1}) tmpdata{end}];
% $$$     tmp = sscanf(str,'%f');
% $$$     if abs(length(tmp)-num_lines)>1
% $$$       if verbose
% $$$         fprintf('  Only able to read %i lines as numbers\n',length(tmp));
% $$$         if verbose>1
% $$$           tmpc = regexp(o,sprintf('\n'),'split');
% $$$           inds = (-1:1) +length(tmp);
% $$$           inds = inds(inds>=1 & inds<=length(tmpc));
% $$$           fprintf('  %s\n',tmpc{inds});
% $$$         end
% $$$         fprintf('  Saving as cell array\n');
% $$$       end
% $$$       data.(header{ll}) = tmpdata;
% $$$     else
% $$$       if verbose>1
% $$$         fprintf('  Saving as double\n');
% $$$       end
% $$$       data.(header{ll}) = tmp;
% $$$     end
% $$$   end
% $$$ end;
