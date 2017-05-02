function M = nan_std(varargin)


% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

M = sqrt(nan_var(varargin{:}));
