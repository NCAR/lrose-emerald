function [handle_matrix, fig]= axes_grid(fig,num_per_column,varargin)
% AXES_GRID - 
%    [handle_matrix, fig]= axes_grid(fig,num_per_column,'param1',value1, ...)
%
%  REQUIRED INPUT
%   figure            the handle of the figure to be drawn upon.  If this is
%                     empty, then a figure will be created.
%   num_per_column    vector containing the number of axes per column
%                     The number of columns is determined by the length of
%                     this vector
%
%  OPTIONAL INPUT/PARAMETERS
%   spacing           as [horiz vert] where horiz is the normalized spacing
%                     between columns, and vert is that for the rows
%   margins           as [left right top bottom] where each is the normalized 
%                     amount of spacing
%   hspace_override   as n x 2 vec [column space] where space is normailized 
%                     space to the left of the column
%   vspace_override   as n x 3 vector [row column space] where space is 
%                     normalized space above object
%   columns_independent  if not 0 and not empty then the plot sizes will be act 
%                     independent across the column.  If 0 or empty or not 
%                     given then all plots will have the same vertical size
%   input_units = 'normalized'; This allows the units of all the inputs to be
%                     something other than normalized.  This can be handy to
%                     allow for the same sized spacings/margins regardless
%                     of the initial figure size.
%   final_position_units = 'normalized'; This allows the final units of the 
%                     axes position to be something other than normalized.
%                     Note that this will lock the placement of the axes
%                     which may not be desired if the figure is later resized.
%                     
%   include_text = 0; This changes the axes whether position or outerposition is used of the
%                     axes, which controls whether the plot area of the axes
%                     is adjusted to accomodate changes to labels, ticklabels, and 
%                     titles.  If set to 0, then margins need to allow space for 
%                     labels, ticklabels, and titles.  If set to 1, then they do not.  
%                     The problem with the latter is that the axes may no longer 
%                     line up if the supporting labels, etc., are different.
%   refresh_sizes = 0; If 1, then num_per_column is interpreted to be a handle of
%                     axes created by axes_grid.  This will just change the positions
%                     of the existing axes.  This is useful to refresh the plot.
%   modify_resize_fcn = 0;  If 1, then the figure's resize function callback will be 
%                     modified to call this function.  Typically you would only
%                     want to do this if the input_units are not normalized.  
%   
%  OUTPUT
%   handle_matrix     a matrix of size = 
%                         max(num_per_column) x length(num_per_column)
%                     which contains the handles of the axes.  The blanks are 
%                     padded with NaN's if version is before R2014b.  Otherwise
%                     blanks are matlab.graphics.GraphicsPlaceholder.
%   fig               the handle of the fig, useful if a figure is generated
%
%
% For backwards compatibility, this usage is also allowed.
% usage  [handle_matrix, fig]= axes_grid(fig,num_per_column,spacing, ...
%                                           margins, hspace_override, ...
%                                           vspace_override, ...
%					    columns_independent, ...
%                                           'param1',value1,...)
% or 
%

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


if nargin < 2 | isempty(num_per_column)
  error('You Need to specify a num_per_column');
  return;
end;

spacing = [0 0];
margins = [0 0 0 0];
hspace_override = [1 0];
vspace_override = [1 1 0];
space_override = [];
columns_independent = 0;
input_units = 'normalized';
final_position_units = 'normalized';
include_text = 0;
refresh_sizes = 0;
modify_resize_fcn = 0;
return_objects = 0;

if length(varargin)>0 
  if ischar(varargin{1})
    paramparse(varargin);
  else
    
    for ll = 1:length(varargin)
      switch ll
       case 1
        spacing = varargin{ll};
       case 2
        margins = varargin{ll};
       case 3
        hspace_override = varargin{ll};
       case 4
        vspace_override = varargin{ll};
       case 5
        space_override = varargin{ll};
       case 6
        columns_independent = varargin{ll};
      end
    end
    clear ll
    paramparse(varargin(6:end));
  end
end

if refresh_sizes
  fig = get(num_per_column(1),'parent');
  handle_matrix = num_per_column;
  num_per_column = sum(ishandle(handle_matrix),1);
end

if isempty(fig)
  fig=figure;
elseif ~ishandle(fig)
  warning('This figure handle does not exist. Creating a new figure.');
  fig=figure;
elseif ~strcmp(get(fig,'Type'),'figure')
  warning('This figure handle is not actually a figure. Creating a new figure.');
  fig=figure;
end

if prod(size(num_per_column)) ~= length(num_per_column)
  error('num_per_column should be a 1 dimensional matrix')
  return;
end

if prod(size(spacing)) ~= length(spacing)
  error('spacing should be a 1 dimensional matrix')
  return;
elseif length(spacing) ~= 2
  error('spacing should have length 2');
  return;
end;

if prod(size(margins)) ~= length(margins)
  error('margins should be a 1 dimensional matrix')
  return;
elseif length(margins) ~= 4
  error('margins should have length 4');
  return;
end;

if size(hspace_override,1) > length(num_per_column)
  warning('Too many elements in hspace_override.  Ignoring the tail.');
  hspace_override=hspace_override(1:length(num_per_column),:);
end;
  
if ~(size(hspace_override,2) == 2) 
  error('hspace_override must be an n x 2 matrix');
end;
  
if size(vspace_override,1) > sum(num_per_column)
  warning('Too many elements in vspace_override.  Ignoring the tail.');
  vspace_override=vspace_override(1:sum(num_per_column),:);
end;
  
if ~(size(vspace_override,2) == 3) 
  error('vspace_override must be an n x 3 matrix');
end;

if ~strcmp(input_units,'normalized')
  old_fig_units = get(fig,'units');
  set(fig,'units',input_units);
  figsz = get(fig,'position');
  set(fig,'units',old_fig_units);
  figsz = figsz(3:4);
  spacing = spacing./figsz;
  margins = margins./figsz([1 1 2 2]);
  hspace_override(:,2) = hspace_override(:,2)/figsz(1);
  vspace_override(:,3) = vspace_override(:,3)/figsz(2);
end  

total_vspace=1-sum(margins(3:4));
total_hspace=1-sum(margins(1:2));

hspace_vector=spacing(1)*[0 ones(1,length(num_per_column)-1)];
if max(hspace_override(:,1)>length(num_per_column))==1 | ...
      max(hspace_override(:,1)<=0)==1
  error('hspace_override has an index which is out of bounds');
  return;
end;

hspace_vector(hspace_override(:,1))=hspace_override(:,2);

plot_hspace=(total_hspace-sum(hspace_vector))/length(num_per_column);

if plot_hspace<=0
  error('There is no horizontal space for the plots!');
  return;
end;
vspace_matrix=zeros(max(num_per_column),length(num_per_column));
if max(vspace_override(:,2)>length(num_per_column))==1 | ...
      max(vspace_override(:,2)<=0)==1
  vspace_override
  error('vspace_override has a column index which is out of bounds');
  return;
end;


for k=1:length(num_per_column)
  vspace_vector=spacing(2)*[0 ones(1,num_per_column(k)-1)]';
  find_column_overrides=find(vspace_override(:,2)==k);
  if max(vspace_override(find_column_overrides,1)>num_per_column(k))==1 | ...
	max(vspace_override(find_column_overrides,1)<=0)==1
    vspace_override
    error('vspace_override has a row index which is out of bounds');
    return;
  end;
  vspace_vector(vspace_override(find_column_overrides,1)) = ...
      vspace_override(find_column_overrides,3);
  vspace_matrix(1:length(vspace_vector),k)=vspace_vector;
  plot_vspace(k)=(total_vspace-sum(vspace_vector))/num_per_column(k);

  if plot_vspace(k)<=0
    plot_vspace
    error('There is no vertical space for the plots!');
    return;
  end;
end;

%vspace_matrix
%plot_vspace

if ~columns_independent
  plot_vspace(:)=min(plot_vspace);
end;

set(0,'CurrentFigure',fig)

cum_hspace_vector=cumsum(hspace_vector);
cum_vspace_matrix=cumsum(vspace_matrix);

if include_text
  posstr = 'outerposition';
else
  posstr = 'position';
end

if ~refresh_sizes
  if ~verLessThan('matlab','8.4.0') 
    handle_matrix = gobjects(max(num_per_column),length(num_per_column));
  else
    handle_matrix = repmat(NaN,max(num_per_column),length(num_per_column));
  end
end
  
for col=1:length(num_per_column)
  for row=1:num_per_column(col)
    args = {'Units','normalized',...
             'NextPlot','add', ...
             posstr, [(margins(1)+cum_hspace_vector(col)+(col-1)*plot_hspace) ...
                      (1-(margins(3)+cum_vspace_matrix(row,col)+(row)*plot_vspace(col))) ...
                      plot_hspace ...
                    plot_vspace(col)],'units',final_position_units};
    if refresh_sizes
      set(handle_matrix(row,col),args{:});
    else
      h=axes(args{:});
      handle_matrix(row,col)=h;
    end;
  end
end;

if ~return_objects
  fig = ghandle(fig);
end

if modify_resize_fcn
  set(fig,'resizefcn',@(x,y) axes_grid(fig,handle_matrix,varargin{:},'refresh_sizes',1));
end


%set(handle_matrix(~isnan(handle_matrix)),'activepositionproperty','position');
