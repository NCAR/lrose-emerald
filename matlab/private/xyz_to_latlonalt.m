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
  
  % modify sizes of olat, olon, and oalt if necessary
  if numel(olat)>1 && ~isequal(size(x),size(olat))
      % check if olat is vector of right size
      if min(size(olat)) == 1 && ismember(length(olat),size(x))
          olat=reshape(olat,1,[]);
          if length(olat)==size(x,2)
              olat=repmat(olat,size(x,1),1);
          else
              olat=repmat(olat',1,size(x,2));
          end
      else
          error('Cannont calculate lat, lon, alt. Dimensions do not match.');
      end
  end
  
  if numel(olon)>1 && ~isequal(size(olon),size(x))
      % check if olon is vector of right size
      if min(size(olon)) == 1 && ismember(length(olon),size(x))
          olon=reshape(olon,1,[]);
          if length(olon)==size(x,2)
              olon=repmat(olon,size(x,1),1);
          else
              olon=repmat(olon',1,size(x,2));
          end
      else
          error('Cannont calculate lat, lon, alt. Dimensions do not match.');
      end
  end
  
  if numel(oalt)>1 && ~isequal(size(oalt),size(x))
      % check if oalt is vector of right size
      if min(size(oalt)) == 1 && ismember(length(oalt),size(x))
          oalt=reshape(oalt,1,[]);
          if length(oalt)==size(x,2)
              oalt=repmat(oalt,size(x,1),1);
          else
              oalt=repmat(oalt',1,size(x,2));
          end
      else
          error('Cannont calculate lat, lon, alt. Dimensions do not match.');
      end
  end
      
  
  % compute new coordinates
  lats = asin( (y.*cos(olat) + (RADIUS+oalt+z).*sin(olat)) ./ ...
	       sqrt(x.^2+y.^2+(RADIUS+oalt+z).^2)) * 180/pi;
  lons = atan2( (x.*cos(olon) + sin(olon).*((RADIUS+oalt+z).*cos(olat) - y.*sin(olat))), ...
		(-x.*sin(olon) + cos(olon).*((RADIUS+oalt+z).*cos(olat) - y.*sin(olat))) ) * 180/pi;
  alts = sqrt(x.^2 + y.^2 + (RADIUS+oalt+z).^2) - RADIUS;
    
% END (xyz_to_latlonalt)
