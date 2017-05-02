function str = get_axes_text(handle,varargin)
% get_axes_text: get axes title/label strings
%
% usage fname = get_axes_text(handle,varargin)
%
% optional parameters:
%   field = 'title'; 'can be 'title','xlabel','ylabel'
%
% handle can be a figure or axes handle.  If a figure
% handle is given, it will find the 'gca' from that figure

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


field = 'title';

paramparse(varargin);

if strcmp(get(handle,'type'),'figure')
  handle = gca_fig(handle);
end

str = get(get(handle,field),'string');
              
str = char2delim(str,sprintf('\n'));
