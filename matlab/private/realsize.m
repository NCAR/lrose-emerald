function sz = realsize(varargin)
% usage sz = realsize(m)
%  REALSIZE works just like size, except that if M is
%  1-D, it will return a vector of length 1 rather than 2
%  like SIZE does.
%
%  see SIZE

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


sz = size(varargin{:});
if length(sz)==2 & sz(2)==1
  sz = sz(1);
end;
