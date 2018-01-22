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
    
    
    %add colorbar based on input field
    function cax_par=find_caxis_params(fld,axlim,colmap)
         %if strcmp(fld,'DBZ') || strcmp(fld,'DBZHC') || strcmp(fld,'DBZVC') || strcmp(fld,'DBZ')
         if ~isempty(strfind(fld,'DBZ'))
            cax_par.color_map=colmap.dbz;
            cax_par.limits=axlim.dbz;
        elseif ~isempty(strfind(fld,'DBM'))
            cax_par.color_map=colmap.dbm;
            cax_par.limits=axlim.dbm;
        elseif ~isempty(strfind(fld,'LDR'))
            cax_par.color_map=colmap.ldr;
            cax_par.limits=axlim.ldr;
        elseif ~isempty(strfind(fld,'NCP'))
            cax_par.color_map=colmap.ncp;
            cax_par.limits=axlim.ncp;
        elseif ~isempty(strfind(fld,'SNR'))
            cax_par.color_map=colmap.snr;
            cax_par.limits=axlim.snr;
         elseif ~isempty(strfind(fld,'VEL'))
             cax_par.color_map=colmap.vel;
             cax_par.limits=axlim.vel;
         elseif ~isempty(strfind(fld,'WIDTH'))
             cax_par.color_map=colmap.width;
             cax_par.limits=axlim.width;
         elseif ~isempty(strfind(fld,'ZDR'))
             cax_par.color_map=colmap.zdr;
             cax_par.limits=axlim.zdr;
         elseif ~isempty(strfind(fld,'RHOHV'))
             cax_par.color_map=colmap.rhohv;
             cax_par.limits=axlim.rhohv;
         elseif ~isempty(strfind(fld,'PHIDP'))
             cax_par.color_map=colmap.phidp;
             cax_par.limits=axlim.phidp;
         else
             cax_par.color_map=colormap(parula(24));
        end
        if isempty(cax_par.color_map)
            cax_par.color_map=colormap(parula(24));
        end
        col_length=size(cax_par.color_map,1);
        try
            spacing=(cax_par.limits(2)-cax_par.limits(1))/(col_length);
            cax_par.yticks=[(cax_par.limits(1)+spacing):spacing:(cax_par.limits(2)-spacing)];
            while length(cax_par.yticks)>16
                cax_par.yticks=cax_par.yticks(1:2:end);
            end
        end
    end
    
  end
  
end
