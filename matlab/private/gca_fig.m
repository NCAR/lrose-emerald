function h = gca_fig(fig)
% gca_fig: get gca from specific figure;
% usage h = gca_fig(fig)
% fig can be a matrix of figure handles

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


%h = findobj(fig,'type','axes');
%h = h(end);

h = get(fig,'currentaxes');
return

