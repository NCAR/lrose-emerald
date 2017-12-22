classdef emerald_utils

% Utilities for emerald

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.4 $
  
  methods (Static = true)
    function [missing_flds,msg] = check_fields_exist(str,flds)
      flds = cellify(flds);
      missing_flds = setdiff(flds,fieldnames(str));
      msg = sprintf('%s\n',missing_flds{:});
      return
    end
    
    function [missing_flds,msg] = check_nc_fieldsdata_exist(str,flds,subfld)
      flds = cellify(flds);
      missing_flds = setdiff(flds,fieldnames(str));
      
      found_fields = setdiff(flds,missing_flds);
      prob_fields = {};
      for ll = 1:length(found_fields)
        if ~isstruct(str.(found_fields{ll})) || ~isfield(str.(found_fields{ll}),subfld)
          missing_flds{end+1} = found_fields{ll};
        end
      end
      
      msg = sprintf('%s\n',missing_flds{:});
      return
    end
    
    
    
    function [lat,lon,alt,x,y,x_corr,y_corr] = polar2cart(r,theta,elev,radar_location)
    % converts polar to lat/lon/alt and x,y,alt
    % x,y,alt are in KM, with alt MSL.
    % radar_location is [lat lon alt] in [deg deg MSLkm]
      if length(elev)==1 && length(theta)>1
        elev = repmat(elev,size(theta));
      elseif length(theta)==1 && length(elev)>1
        theta = repmat(theta,size(elev));
      elseif length(theta)~=length(elev)
        error('length of theta should equal length of elev')
      end
      [thetas,rs] = ndgrid(theta,r);
      [elevs,rs] = ndgrid(elev,r);
      % needed to put 0 for OALT since it would be counted twice
      [x_corr,y_corr,z] = radar_razelev_to_xyz(0,rs,thetas,elevs);
      reshape(radar_location,[],3);
      [lat,lon,alt] = xyz_to_latlonalt(radar_location(:,1),radar_location(:,2),radar_location(:,3),x_corr,y_corr,z);
      if nargout>3
        x = rs .* cos((90-thetas)*pi/180);
        y = rs .* sin((90-thetas)*pi/180);
      end
    end
    
    function out = plot_struct(varargin)
      out = struct('name','','call','','fill',{1},'options',{{}},'xy2ind','');
      out = paramparses(out,varargin);
    end
    
    function ap = modify_entry(ap,nm,varargin);
      ind = find(strcmp({ap.name},nm));
      if isempty(ind)
        warning('No matching entry found');
        return
      end
      ap(ind(1)) = paramparses(ap(ind(1)),varargin);
    end
    
    function str = get_version
      fid = fopen('VERSION','rt');
      str = fscanf(fid,'%s');
      fclose(fid);
    end
    
    function [rlat,rlon,ralt] = get_platform_midloc(rlat,rlon,ralt)
      inds = find(~isnan(rlat) & ~isnan(rlon) & ~isnan(ralt));
      if length(inds) == 0
        rlat = NaN;
        rlon = NaN;
        ralt = NaN;
        return
      end
      [~,indind] = min(abs(inds)-(length(rlat)+1)/2);
      inds = inds(indind);
      rlat = rlat(inds);
      rlon = rlon(inds);
      ralt = ralt(inds);
    end
    
  end
  
end
