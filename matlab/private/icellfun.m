function result = icellfun(cl,fun,varargin)
% ICELLFUN applies a function to each element in a cell array
%
%  usage: result = icellfun(cl,fun,'param',value,...)
% 
%   cl - any cell array - this will get operated on.
%   fun - either an INLINE function, a string containing the name of
%         a function, a string containing an expression, or a function
%         handle. examples: 'size', @size, inline('size(x,1)','x'),
%         'size(x)'.  This function will get applied individually
%         to each element of cl.
%
%   params:
%     return_type = 'cell'; or can be 'mat'.  If 'mat' then cell2mat is
%         performed on the data before returning
%     error_handling = 'warning'.  can be 'error' or 'warning'
%
%   result - a cell array of the same size as cl, only it contains the
%         results from FUN(cl).
%
%  This function is similar to CELLFUN, only much less restrictive.
%  FUN can be any function.  If an error occurs, only a warning will
%  actually get called and then it will continue processing.  The 
%  offending entry will return a [].

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


return_type = 'cell';
error_handling = 'warning';

paramparse(varargin);

fun = make_feval_able(fun);

result = cell(size(cl));
for l = 1:prod(size(cl))
  try
    result{l} = feval(fun,cl{l});
  catch
    feval(error_handling,'Error occured in ICELLFUN loop:',lasterr);
  end;
end;
if strcmp(return_type,'mat')
  try
    result = cell2mat(result);
  catch
    feval(error_handling,'Error occured in converting to matrix:',lasterr);
  end
end;
