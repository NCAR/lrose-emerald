function [str,objhandle] = get_axes_text(handle,varargin)
% get_axes_text: get axes title/label strings
%
% usage fname = get_axes_text(handle,varargin)
%
% optional parameters:
%   field = 'title'; 'can be 'title','xlabel','ylabel'
%   figure_title_search = {};  if not empty cell array, should be a 
%         a cell array of length 2*n containing a search conditions
%         for findobj which will return an object under 'handle'
%         that contains the string.
%         The idea here is that sometimes people use an text-type 
%         uicontrol to be the title for the figure. 
%         e.g. {'tag','plot_window_title'} % if the tag property
%         % was set to 'plot_window_title' when it was created.
%         {'type','uicontrol','style','text'}
%         % if there is only 1 text-type uiconrtol
%
% handle can be a figure or axes handle.  If a figure
% handle is given, it will find the 'gca' from that figure

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


field = 'title';
figure_title_search = {};

paramparse(varargin);

if strcmp(get(handle,'type'),'figure')
  if isempty(figure_title_search)
    h = findobj(handle,'type','axes');
    for ll = 1:length(h)
      str = get(get(h(ll),field),'string');
      has(ll) = ~isempty(str);
    end
    handle = h(max(find(has)));
    if isempty(handle)
      str = '';
      objhandle = [];
      return
    end
  else
    h = findobj(handle,figure_title_search{:});
    for ll = 1:length(h)
      try
        str = get(h(ll),'string');
        has(ll) = ~isempty(str);
      catch
        has(ll) = logical(0);
      end
    end
    handle = h(max(find(has)));
    if isempty(handle)
      str = '';
      objhandle = [];
      return
    end
    str = get(handle,'string');
    str = char2delim(str,sprintf('\n'));
    objhandle = handle;
    return
  end
end

objhandle = handle;
str = get(get(handle,field),'string');
              
str = char2delim(str,sprintf('\n'));
