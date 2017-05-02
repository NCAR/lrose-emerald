function output = repr(x,varargin);
% repr   represent matlab objects as an eval'able string
%
% repr takes data and returns an eval'able string that will recreate
% the data.  This is useful for taking data and turning it into code,
% which can be handy for incorporating data into a file, perhaps after
% some editing.  This is also good for just examing the full depth of a
% cell or struct.
%
% usage
%   output = repr(x,'param1',value1,...)
%
% optional params:
%  prefix = 'x'; % used only if 'as_single_line' is set to 0.  This
%     is used to name the variable that will be created by eval'ing
%     the output.  e.g. 'prefix','myvar' will create ouput that sets
%     myvar equal to the input 'x'.
%  as_single_line = 0; if 0, output will be a multiline character
%     string.  If 1, then output will be a single line expression.
%     0 is more readable, and 1 is more compact.
%  max_array_size = inf; The size of the maximum array to expand.
%     If set to something finite, this will cause arrays larger to
%     be not expanded (and thus NO LONGER eval'able), and instead
%     give a string of the format [<size> <class> [<field list>]]
%     where [<field list>] is included if the object is a struct.
%     This is useful for using repr to display the contents of
%     a struct with large arrays, which don't need to be shown.
%  unhandled_types = 'warning'; % can be 'error' or 'warning' or 'none'.  This
%     tells repr what to do if an unhandled type is found.
%  comment_nonevals = 0; % adds a comment to lines that are non-eval'able
%     only works when as_single_line is 0. (Otherwise comment would 
%     kill the rest of the line).

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
  prefix = 'x';
  as_single_line = 0;
  max_array_size = inf;
  unhandled_types = 'warning';
  comment_nonevals = 0;
  
  paramparse(varargin);
  
  params = varstruct({},{'x','varargin'});

  
  output = repr_i(x,params);
  
end

function output = repr_i(x,params,varargin)
  
  params = paramparses(params,varargin);
  
  prefix = params.prefix;
  as_single_line = params.as_single_line;
  max_array_size = params.max_array_size;
  unhandled_types = params.unhandled_types;
  comment_nonevals = params.comment_nonevals; 
  
  
  sz = size(x);
  cl = class(x);

  if as_single_line
    if prod(sz)>max_array_size
      % if it is too big, we will suppress all info but a little meta data
      if ~isstruct(x)
        % if not a struct, output type and size
        output = sprintf('[%s %s]',mat2str(sz),cl);
      else
        % if struct, output the type size and fields
        flds = fieldnames(x);
        flds = sprintf('%s,',flds{:});
        output = sprintf('[%s %s [%s]]',mat2str(sz),cl,flds(1:end-1));
      end
    % otherwise, we will output everything
    elseif isnumeric(x) || ischar(x) || islogical(x)
      % numeric, chars, and logicals can be output using mat2str
      if any(strcmp(cl,{'double','char','logical'}));
        % doubles, chars, and logicals can be output normally using mat2str
        % if more than 2 dimensions, unravel into a 2d matrix
        output = mat2str(x(:,:));
      else
        % others (numeric formats), need the class identifier too
        % if more than 2 dimensions, unravel into a 2d matrix
        output = mat2str(x(:,:),'class');
      end
      if length(sz)>2
        % if more than 2D, add a reshape command to get back to the original
        output = sprintf('reshape(%s,%s)',output,mat2str(sz));
      end
    elseif strcmp(cl,'function_handle')
      output = char(x);
      if output(1)~='@'
        output = ['@' output];
      end
    elseif iscell(x)
      % run through all elements of the cell array, generating the output for each
      if prod(size(x))==0
        output = sprintf('repmat({[]},%s)',mat2str(size(x)));
      else
        for ll = 1:prod(size(x))
          output{ll} = repr_i(x{ll},params);
        end
        if length(sz)==2 % if 2d we can short cut the notation
          if sz(1)==1 % row vector
            output = sprintf('%s,',output{:});
            output = sprintf('{%s}',output(1:end-1));
          else
            output = sprintf('%s;',output{:});
            output = sprintf('{%s}',output(1:end-1));
          end
        else % if not, we need the reshape
          output = sprintf('%s,',output{:});
          output = sprintf('reshape({%s},%s)',output(1:end-1),mat2str(sz));
        end
      end
    elseif isstruct(x)
      % turn the struct into cell arrays
      C = struct2cell(x);
      fields = fieldnames(x);
      % generate the output for the cell and for the field names
      output = repr_i(C,params);
      of = repr_i(fields,params,'max_array_size',inf);
      % generate the output putting the cell and fieldnames back together using cellstruct
      % cellstruct is not as pretty as using struct, but it is less temperamental
      output = sprintf('cell2struct(%s,%s,1)',output,of);
    else
      switch unhandled_types
        case 'error'
          error('Cannot handle type %s',cl);
        case {'warning','skipwarning'}
          warning('Cannot handle type %s',cl);
        case 'none'
          1;
        otherwise
          error('Bad value for unhandled_types (%s).  Should be error, warning, skipwarning, none',unhandled_types);
      end
      % any other type will just produce the same as if it were too big.
      switch unhandled_types
        case {'skip','skipwarning'}
          output = '';
        otherwise
          output = repr_i(x,params,'max_array_size',0);
      end
    end
  
  else
    % Otherwise we are producing multiline output
    % this will generate things like 'x = <blah>;'
    if prod(sz)>max_array_size
      % if too large, output info.  Generate the info using the single line routine
      output = repr_i(x,params,'as_single_line',1);
      if comment_nonevals
        comment = ' % WILL NOT EVAL';
      else
        comment = '';
      end
      output = sprintf('%s = %s;%s\n',prefix,output,comment);
    % if not too big, output everything
    elseif isnumeric(x) || ischar(x) || islogical(x)
      if length(sz)>2
        % if dimensionality is bigger than 2, need to do more work
        % break into pieces of 2D
        % get the extra dimension sizes
        extra_size = sz(3:end);
        % create a place to receive the extra indices
        out_ind = cell(1,length(extra_size));
        % loop of all possible values of the extra dims
        for ll = 1:prod(extra_size)
          % get repr_i for that data: will be 2D
          output{ll} = repr_i(x(:,:,ll),params,'as_single_line',1);
          % replace ; with ;\n\t to add new lines
          output{ll} = strrep(output{ll},';',sprintf(';\n\t'));
          % create index string for extra dimensions
          [out_ind{:}] = ind2sub(extra_size,ll);
          out_ind_str = sprintf('%i,',out_ind{:});
          % create output line
          output{ll} = sprintf('%s(:,:,%s) = %s;\n',prefix,out_ind_str(1:end-1),output{ll});
        end
        % concatenate them all up
        output = cat(2,output{:});
      else
        % run the single line case, and just replace ; with ;\n\t
        output = repr_i(x,params,'as_single_line',1);
        output = strrep(output,';',sprintf(';\n\t'));
        output = sprintf('%s = %s;\n',prefix,output);
      end  
    elseif strcmp(cl,'function_handle')
        % run the single line case, and just replace ; with ;\n\t
        output = repr_i(x,params,'as_single_line',1);
        output = sprintf('%s = %s;\n',prefix,output);
    elseif iscell(x)
      if length(x)==0
        output{1} = sprintf('%s = {};\n',prefix);
      else
        % if non-empty we need to run through them all
        % create place to hold indices
        out_ind = cell(1,length(sz));
        % loop over the whole cell array
        for ll = 1:prod(size(x))
          % determine index and create index string
          [out_ind{:}] = ind2sub(sz,ll);
          out_ind_str = sprintf('%i,',out_ind{:});
          % get output for the array element, adding the index to the prefix
          output{ll} = repr_i(x{ll},params,'prefix',sprintf('%s{%s}',prefix,out_ind_str(1:end-1)));
        end
      end
      % concatenate them all up
      output = cat(2,output{:});
    elseif isstruct(x)
      %create place to hold indices
      out_ind = cell(1,length(sz));
      % grab fieldnames
      fields = fieldnames(x);
      % loop over all elements of the struct array
      output = {};
      for ll = 1:prod(size(x))
        % determine the index string
        [out_ind{:}] = ind2sub(sz,ll);
        out_ind_str = sprintf('%i,',out_ind{:});
        % loop over all fields
        for kk = 1:length(fields)
          % create the output for the field data, appending the struct and index to the prefix
          output{kk,ll} = repr_i(x(ll).(fields{kk}),params,'prefix',sprintf('%s(%s).%s',prefix,out_ind_str(1:end-1),fields{kk}));
        end
      end
      % contatenate them all up
      if length(output)>0
        output = cat(2,output{:});
      else
        % either has no fields or no size, or both
        if length(fields)==0 && isequal(size(x),[1 1])
          output = sprintf('%s = struct;\n',prefix);
        elseif length(fields)==0 
          output = sprintf('%s = repmat(struct,%s);\n',prefix,mat2str(size(x)));
        else
          of = repr_i(reshape(fields,1,[]),params,'max_array_size',inf,'as_single_line',1);
          output = sprintf('%s = repmat(cell2struct(repmat({[]},[1 %i]),%s,2),%s);\n',prefix,length(fields),of,mat2str(size(x)));
        end
      end          
    else
      % any other type will just produce the same as if it were too big.
      output = repr_i(x,params,'as_single_line',1);
      if ~isempty(output)
        output = sprintf('%s = %s;\n',prefix,output);
      end
    end
  end
end
  

