function M = nan_var(x,flag,dim)


% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

if nargin<2 | isempty(flag)
  flag = 0;
end

if nargin<3 | isempty(dim)
   dim = find(size(x)>1);
   if isempty(dim)
     dim = 1;
   else
     dim = dim(1);
   end
end

[MM,N] = nan_mean(x,dim);
M = nan_mean(abs(bsxfun(@minus,x,MM).^2),dim);

if ~flag
  ind = N==1;
  N(ind) = 2;
  M = M.*N./(N-1);
end
 
