function sz = realndims(m)
% usage sz = realndims(m)
%  REALNDIMS works just like ndims, except that if M is
%  1-D, it will return 1 rather than 2 like NDIMS does.
%
%  see NDIMS, REALSIZE

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


sz = length(realsize(m));

