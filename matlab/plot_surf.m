function h = plot_surf(varargin)
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
%mode = 'surface';

%%%%%%%%%%%%%%%%%%%  Begin
%cax = newplot;

% the following does all the work that surf doesn't do.
% namely, extend the matricies to the right size, and
varargin = process_varargin(varargin);

h=findobj(gca, 'type', 'surface');

if length(varargin) ~= 4
    error('Not enough input arguments.')
elseif length(h)==0
    if length(size(varargin{4}))==2
        h = surface(varargin{:},'EdgeColor','none');
    else
        h = surface(varargin{:},'EdgeColor','none','CDataMapping','direct');
    end
    grid on
    axis tight;
    caxis([0 1]);
else
    h.XData=varargin{1,1};
    h.YData=varargin{1,2};
    h.ZData=varargin{1,3};
    caxis manual
    h.CData=varargin{1,4};
end
%return;
end

%%%%%%%%%%%%%%%%%
function [vout] = process_varargin(vin)
% reworks the parameters to do the correct things
% as specified by the help.  Also returns the
% surfmat specific options that may or may not be
% included in the paramters given by user.

% % other setups
%
% if ~iscell(v)
%   v = {v};
% end;

if length(size(vin{4}))==3
    v=vin(1:3);
    v{end+1}=vin{4}(:,:,1);
    v{end+1}=vin{4}(:,:,2);
    v{end+1}=vin{4}(:,:,3);
end

% Count the number of numeric arguments:
% 1 implies just a Z=C matrix
% 2 Z and C
% 3 x,y,Z=C
% 4 x,y,Z,C
num_arg = length(v);

% We have to augment the matricies to handle
% the problem that the last row and column
% are not normally displayed.  So x and y
% matricies (method 2) need to get extended
% by a delta at the end.  Z and C (method 1)
% need to just repeat the last row and column

methodvec = ones(1,num_arg);
methodvec(1:2)=[2 2];

% if methodvec is a 2, treat as an x or y vec.  if 1 treat
% as Z,C vector
for l = 1:num_arg
    if length(v{l})==1
        if methodvec(l) == 2
            v{l}(end+1,1) = 2*v{l}(end);
        elseif methodvec(l) == 1
            v{l}([1 2],[1 2]) = v{l}(1);
        end
    elseif length(v{l})>1
        if methodvec(l) == 2
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
        end
    end
end

for l = 1:num_arg
    if length(v{l})>1 && methodvec(l) == 2
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
            end
        else
            % in case of 1-D, just add the first delta to the first number
            % and add this to the beginning, then average 1:end-1 and 2:end.
            v{l} = [(2*v{l}(1)-v{l}(2)) ; v{l}];
            v{l} = (v{l}(1:(end-1))+v{l}(2:end))/2;
        end
    end
end

if num_arg==4
    vout=v;
elseif num_arg==6
    color_out=zeros(size(v{4},1),size(v{4},2),3);
    color_out(:,:,1)=v{4};
    color_out(:,:,2)=v{5};
    color_out(:,:,3)=v{6};
    vout=cell(1,4);
    vout(1:3)=v(1:3);
    vout(4)={color_out};
else
    disp('Wrong number of input arguments.');
    return
end
end
