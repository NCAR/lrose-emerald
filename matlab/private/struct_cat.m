function out = struct_cat(data,varargin)
% function struct_cat   concatenate fields of struct array into a single struct
%
% out = struct_cat(data,'param1',value1,...)
%
% data is a struct array
%
% optional parameters:
%   dim = 1; % the dimension in which to concatenate the fields
%   cat_mode = 'only_identical'; % can be 'only_identical', 'exact', 'any'
%              'only_identical' - all have to be exactly the same size
%              'exact' - have to be the same size as 'exact_size'
%              'any' - it will just give it a try no matter what
%   exact_size = NaN;
%   error_mode = 'error'; % can be 'error','warn','ignore'

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 




dim = 1;
cat_mode = 'only_identical'; % can be 'only_identical', 'exact', 'any'
exact_size = NaN;
error_mode = 'error'; % can be 'error','warn','ignore'
fields = {};


paramparse(varargin);

%out = data(1);
flds = fieldnames(data);
if ~isempty(fields)
  [dummy,inds] = intersect(flds,fields);
  flds = flds(sort(inds));
end

for ll = 1:length(flds)
  szs = icellfun({data.(flds{ll})},@size);
  problem = '';
  switch cat_mode
   case 'only_identical'
    uszs = unique(icellfun(szs,@mat2str));
    if length(uszs) ~= 1
      problem = sprintf('The field "%s" does not have the same size across all elements',flds{ll});
    end
   case 'exact'
    if isnan(exact_size)
      error('exact_size should be non-NaN');
    end
    res = icellfun(szs,@(x) isequal(x,exact_size),'return_type','mat');
    if any(~res)
      problem = sprintf('Some element of field "%s" does not have the specified size "%s"',flds{ll},mat2str(exact_size));
    end
  end
  try
    out.(flds{ll}) = cat(dim,data.(flds{ll}));
  catch ME
    problem = sprintf('Error concatenating field "%s": (%s) %s"',flds{ll},ME.identifier,ME.message);
  end
  if ~isempty(problem)
    switch error_mode
     case 'error'
      error(problem);
     case 'warn'
      warning(problem);
     case 'ignore'
      continue
    end
  end
end
  
   
    
