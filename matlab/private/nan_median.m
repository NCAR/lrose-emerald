function [M,N] = nan_median(x,dim)


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

nin = ~isnan(x);
% count the length in that dimension
N = sum(nin,dim);

M = prctile(x,50,dim);
