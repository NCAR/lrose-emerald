function in = cellify(in)
% usage out = cellify(in)
%  if 'in' not a cell array, it wraps in into a cell array

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


if ~iscell(in)
  in = {in};
end;
