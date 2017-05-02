function h = surfmat(varargin)
%SURFMAT   3-D colored surface.
%
%   Precisely the same as SURF, except that an extra column and row
%   of 1's are added to the Z matrix (X and Y are extended naturally
%   by the last increment in each) so that the entire matrix is 
%   displayed, rather than just 1:(n-1) and 1:(m-1).  SURF thinks of
%   the X and Y (perhaps implicitly defined) as the vertex points
%   of 
%
%   SURFMAT(X,Y,Z,C) plots the colored parametric surface defined by
%   four matrix arguments.  The view point is specified by VIEW.
%   The axis labels are determined by the range of X, Y and Z,
%   or by the current setting of AXIS.  The color scaling is determined
%   by the range of C, or by the current setting of CAXIS.  The scaled
%   color values are used as indices into the current COLORMAP.
%   The shading model is set by SHADING.
%
%   SURFMAT(X,Y,Z) uses C = Z, so color is proportional to surface height.
%   and, if do_3d = 0, it then sets Z to 0's to avoid single NaN's leading 
%   to 4 'boxes' being wiped out.
%
%   SURFMAT(x,y,Z) and SURFMAT(x,y,Z,C), with two vector arguments replacing
%   the first two matrix arguments, must have length(x) = n and
%   length(y) = m where [m,n] = size(Z).  In this case, the vertices
%   of the surface patches are the triples (x(j), y(i), Z(i,j)).
%   Note that x corresponds to the columns of Z and y corresponds to
%   the rows.  If no C is given C = Z then, if do_3d = 0, Z is set to 0's 
%   to avoid single NaN's leading to 4 'boxes' being wiped out.
%
%   SURFMAT(Z) and SURFMAT(Z,C) use x = 1:n and y = 1:m.  In this case,
%   the height, Z, is a single-valued function, defined over a
%   geometrically rectangular grid. If no C is given C = Z then , if do_3d=0,
%   Z is set to 0's to avoid single NaN's leading to 4 'boxes' being wiped out.
%
%   SURFMAT(...,'PropertyName',PropertyValue,...) sets the value of the 
%   specified surface property.  Multiple property values can be set
%   with a single statement.
%
%   SURFMAT(<data matricies>,{'Param',param_value,...},<surface properties>) 
%   sets the SURFMAT parameter 'Param' to param_value.  Multiple property 
%   values can be set with a single statement.  Param can be:
%
%     do_3d = either 1 or 0, default 0.  If C is *not* given then C defaults
%             to C regardless of do_3d.  If do_3d = 0 then Z is set to 0's.
%             this avoids the problem that if a Z-value is NaN or inf, then
%             the point doesn't exist and therefore and region with this point
%             as a vertex will disappear.  You can override this fix by setting
%             do_3d to 1.
%
%     no_colorbar = either 1 or 0, default 0.  The default behaviour is to add
%             a colorbar.  Override this by setting no_colorbar to 1.
%
%     fix_coords = either 1 or 0, default 1.  Attempts to adjust the coords
%             of the boxes so that the points are in the center of the regions.
%             (not quite right yet!)
%
%   SURFMAT returns a handle to a SURFACE object.
%
%   Examples:
%      Z = rand(25);
%        surfmat(Z);
%        surfmat(Z,'EdgeColor','none')
%        surfmat(Z,{'do_3d',1},'EdgeColor','none')
%        surfmat(Z,{'do_3d',1})
%        surfmat(Z,{'do_3d',1,'no_colorbar',1},'EdgeColor','none')
%
%   AXIS, CAXIS, COLORMAP, HOLD, SHADING and VIEW set figure, axes, and 
%   surface properties which affect the display of the surface.
%
%   See also SURF, SURFC, SURFL, MESH, SHADING.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


%-------------------------------
%   Additional details:
%
%   If the NextPlot axis property is REPLACE (HOLD is off), SURF resets 
%   all axis properties, except Position, to their default values
%   and deletes all axis children (line, patch, surf, image, and 
%   text objects).

% defaults:
no_colorbar = 0;
do_3d = 0;
fix_coords = 1;
mode = 'surface';

%%%%%%%%%%%%%%%%%%%  Begin
cax = newplot;

% the following does all the work that surf doesn't do.
% namely, extend the matricies to the right size, and 
[varargin,options] = process_varargin(varargin);

paramparse(options);

fun = str2func(mode);

if length(varargin) == 0
  error('Not enough input arguments.')
elseif length(varargin) == 1
  if min( size( varargin{1} ) ) == 1
    error('Input argument must be a matrix not a vector or a scalar')
  else
    hh = feval(fun,varargin{1},'EdgeColor','none');
  end
else
  hh = feval(fun,varargin{:},'EdgeColor','none');
end

next = lower(get(cax,'NextPlot'));
if ~ishold
    view(3); grid on
end
if nargout == 1
    h = hh;
end

view(2);
axis tight;

if ~no_colorbar
  %colorbar60;
  colorbar;
end;

return;

%%%%%%%%%%%%%%%%%
function [v,o] = process_varargin(v)
% reworks the parameters to do the correct things
% as specified by the help.  Also returns the 
% surfmat specific options that may or may not be
% included in the paramters given by user.

% get parameter defaults from caller fcn:
do_3d = evalin('caller','do_3d');
fix_coords = evalin('caller','fix_coords');
no_colorbar = [];

% other setups
o = {};

if ~iscell(v)
  v = {v};
end;

% Count the number of numeric arguments:
% 1 implies just a Z=C matrix
% 2 Z and C
% 3 x,y,Z=C
% 4 x,y,Z,C
num_arg = 0;
l = 0;
while l<length(v)
  l = l+1;
  if isnumeric(v{l}) | islogical(v{l})
    num_arg = num_arg+1;
  else
    l = length(v);
  end;
end;

for l = 1:num_arg
  if islogical(v{l})
    v{l} = double(v{l});
  end;
end;

% if we are to fix the coordinates but none are
% given, we fix the default coordinates.
if fix_coords & any(num_arg==[1 2])
  v = { 1:size(v{1},2) 1:size(v{1},1) v{:}};
  num_arg = num_arg+2;
end;

% parse out surfmat options if there
if num_arg<length(v) & iscell(v{num_arg+1})
  o = v{num_arg+1};
  v = {v{1:num_arg} v{num_arg+2:end}};
end;

paramparse(o);

% We have to augment the matricies to handle
% the problem that the last row and column 
% are not normally displayed.  So x and y
% matricies (method 2) need to get extended
% by a delta at the end.  Z and C (method 1)
% need to just repeat the last row and column

% in the cases that Z=C, this is bad because
% nulls wipe out mor data than they should
% because for 1 NaN, 4 'boxes' lose a vertex,
% thus wiping out all 4 boxes.  force C = Z and
% Z = zeros(size(Z)).  This is done *unless* 
% do_3d is set to 1;

if ~do_3d & any(num_arg == [1 3])
  v = {v{1:(num_arg-1)} zeros(size(v{num_arg})) v{num_arg} v{(num_arg+1):end}};
  num_arg = num_arg + 1;
end

methodvec = ones(1,num_arg);
%if num_arg==3 
%  v = {v{1:2} zeros(size(v{3})) v{3:end}};
%  num_arg = 4;
%  methodvec = ones(1,num_arg);
%end;
  
if any(num_arg == [3 4])
  methodvec(1:2)=[2 2];
end;

% if methodvec is a 2, treat as an x or y vec.  if 1 treat
% as Z,C vector
for l = 1:num_arg
  if length(v{l})==1
    if methodvec(l) == 2
      v{l}(end+1,1) = 2*v{l}(end);
    elseif methodvec(l) == 1
      v{l}([1 2],[1 2]) = v{l}(1);
    end;
  elseif length(v{l})>1
    if methodvec(l) == 2;
      % extend x or y
      v{l} = shiftdim(v{l});
      if realndims(v{l})==2
	% in case of 2-D add last delta in each direction
	% to the last row and add this to the end. same for columns
	v{l}(:,end+1)=2*v{l}(:,end)-v{l}(:,end-1);
	v{l}(end+1,:)=2*v{l}(end,:)-v{l}(end-1,:);
      else
	% in case of 1-D, just add the last delta to the last number
	% and add this to the end.
	v{l}(end+1)=2*v{l}(end)-v{l}(end-1);
      end
    elseif methodvec(l) == 1
      % extend Z C; just repeat last row then last column
      v{l}(:,end+1)=v{l}(:,end);
      v{l}(end+1,:)=v{l}(end,:);
    end;
  end;
end;

if fix_coords
  for l = 1:num_arg
    if length(v{l})>1 & methodvec(l) == 2;
      % adjust x or y
      if realndims(v{l})==2
	if l == 1
	  % in the case of x: add a new column at the begining
	  % with the same step size, then average 1:end-1 to 2:end
	  v{l} = cat(2,2*v{l}(:,1)-v{l}(:,2),v{l});
	  v{l} = (v{l}(:,1:(end-1))+v{l}(:,2:end))/2;
	else
	  % in the case of y: add a new row at the begining
	  % with the same step size, then average 1:end-1 to 2:end
	  v{l} = cat(1,2*v{l}(1,:)-v{l}(2,:),v{l});
	  v{l} = (v{l}(1:(end-1),:)+v{l}(2:end,:))/2;
	end;
      else
	% in case of 1-D, just add the first delta to the first number
	% and add this to the beginning, then average 1:end-1 and 2:end.
	v{l} = [(2*v{l}(1)-v{l}(2)) ; v{l}];
	v{l} = (v{l}(1:(end-1))+v{l}(2:end))/2;
      end
    end;
  end;
end;
