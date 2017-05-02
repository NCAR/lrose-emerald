% RADAR_RAZELEV_TO_XYZ Convert radar range, az, elev to tangent plane x, y, z.
%   [X,Y,Z] = RADAR_RAZELEV_TO_XYZ(OALT,R,AZ,ELEV) takes as input equally-
%   sized vectors or matrices containing radar range (R), azimuth (AZ) and
%   elevation (ELEV) values, where azimuth and elevation values are in
%   degrees,  It computes the Cartesian W-E displacement (X), S-N 
%   displacement (Y), and vertical displacement (Z), having the same units 
%   as R, under the assumption of 4 x earth radius beam bending (Doviak 
%   and Zrnic, 1993, p. 18ff).
%
%   See also XYZ_TO_LATLONALT, LATLONALT_TO_RADAR_RAZELEV, EARTHDIST.
%
%   Example: 
%
%     oalt = 0.1; r = 0:240; az = zeros(size(r)); elev = 0.5*ones(size(r));
%     [x,y,z] = radar_razelev_to_xyz(oalt,r,az,elev);
%     figure; plot(r,z)

% Written by John K. Williams (303-497-2822, jkwillia@ucar.edu)



% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

function [x,y,z] = radar_razelev_to_xyz(oalt,r,az,elev)

  % define constants
  RADIUS  = 6378.140; % radius of earth, in km
  RC = 4*RADIUS; % radius of curvature for "4/3 earth" model
  
  elev = mod(elev,360); % turn elevs to be between 0 and 359.999
  flip_elev_inds = abs(elev-180)<90;
  elev(flip_elev_inds) = 180-elev(flip_elev_inds);
  
    % convert az, elev into radians
  az = az * pi/180;
  elev = elev * pi/180;
  
  % compute new coordinates
  xydist = RC*(sin(r/RC-elev) + sin(elev));
  x = sin(az).*xydist;
  y = cos(az).*xydist;
  z = oalt + RC*(cos(r/RC-elev) - cos(elev));
  
  flip_elev_inds = resize(flip_elev_inds,size(x));
  x(flip_elev_inds) = -1*x(flip_elev_inds);
  y(flip_elev_inds) = -1*y(flip_elev_inds);
  
% END (radar_razelev_to_xyz)
