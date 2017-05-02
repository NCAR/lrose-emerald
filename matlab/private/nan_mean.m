function [M,N] = nan_mean(x,dim)


% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

if nargin<2 | isempty(dim)
   dim = find(size(x)>1);
   if isempty(dim)
     dim = 1;
   else
     dim = dim(1);
   end
end

% find where is nan and set those locations to 0
in = isnan(x);
x(in) = 0;

% count the length in that dimension
N = sum(~in,dim);

% find those places where the length of non-nan's is 0
% and set those N's to 1.  Avoids divide by 0
ind = N==0;
N(ind) = 1;

% compute the actual mean
M = sum(x,dim)./N;

% in those places where the length of non-nan's is 0, set the
% answer to NaN
M(ind) = NaN;
if nargout>1
  N(ind) = 0;
end

