% XYZ_TO_LATLONALT Convert tangent plane x, y, z to lat, lon, and altitude.
%   [LAT,LON,ALT] = XYZ_TO_LATLONALT(OLAT,OLON,OALT,X,Y,Z) takes 
%   the following inputs:
%
%     OLAT - latitude of origin in degrees
%     OLON - longitude of origin in degrees
%     OALT - MSL altitude of origin in kilometers
%     X - Cartesian W-E displacement, in km 
%     Y - Cartesian S-N displacement, in km
%     Z - vertical displacement, in km
%
%   and returns the vectors LAT, LON, ALT containing the corresponding 
%   latitude (in degrees), longitude (in degrees), and altitude (km MSL).
%   The Cartesian coordinate system has its origin at OLAT, OLON, OALT 
%   with west-east x-axis, south-north y-axis, and vertical z-axis.
%
%   See also LATLONALT_TO_XYZ, EARTHDIST.
%
%   Example: 
%
%     olat = 34; olon = -80; oalt = 1;
%     [x,y,z] = latlonalt_to_xyz(olat,olon,oalt,[34 35],[-81 -80],[2 3])
%     [lat,lon,alt] = xyz_to_latlonalt(olat,olon,oalt,x,y,z)

% Written by John K. Williams (303-497-2822, jkwillia@ucar.edu)



% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

function [lats,lons,alts] = xyz_to_latlonalt(olat,olon,oalt,x,y,z)

  % define constant (radius of the earth, in km)
  RADIUS  = 6378.140;

  % convert olat, olon into radians
  olat = olat * pi/180;
  olon = olon * pi/180;
  
  % compute new coordinates
  lats = asin( (y*cos(olat) + (RADIUS+oalt+z)*sin(olat)) ./ ...
	       sqrt(x.^2+y.^2+(RADIUS+oalt+z).^2)) * 180/pi;
  lons = atan2( (x*cos(olon) + sin(olon)*((RADIUS+oalt+z)*cos(olat) - y*sin(olat))), ...
		(-x*sin(olon) + cos(olon)*((RADIUS+oalt+z)*cos(olat) - y*sin(olat))) ) * 180/pi;
  alts = sqrt(x.^2 + y.^2 + (RADIUS+oalt+z).^2) - RADIUS;
    
% END (xyz_to_latlonalt)
