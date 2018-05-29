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
    
    
    % find color map based on input field
    function cax_par=find_caxis_params(fld,axlim,colmap)
         if ~isempty(strfind(fld,'DBZ')) | ~isempty(strfind(fld,'Reflectivity'))
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
         elseif ~isempty(strfind(fld,'VEL')) | ~isempty(strfind(fld,'Velocity'))
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
         elseif ~isempty(strfind(fld,'temp')) | ~isempty(strfind(fld,'Temp'))
             cax_par.color_map=colmap.temp;
             cax_par.limits=axlim.temp;
         elseif ~isempty(strfind(fld,'backscat')) | ~isempty(strfind(fld,'BackScat'))
             cax_par.color_map=colmap.backscat;
             cax_par.limits=axlim.backscat;
         elseif ~isempty(strfind(fld,'depol')) | ~isempty(strfind(fld,'Depol'))
             cax_par.color_map=colmap.depol;
             cax_par.limits=axlim.depol;
         elseif ~isempty(strfind(fld,'od')) | ~isempty(strfind(fld,'OpticalDepth'))
             cax_par.color_map=colmap.od;
             cax_par.limits=axlim.od;
         elseif ~isempty(strfind(fld,'extinction')) | ~isempty(strfind(fld,'Extinction'))
             cax_par.color_map=colmap.ext;
             cax_par.limits=axlim.ext;
         else
             cax_par.color_map=colormap(parula(24));
         end
        
         % use default
         if isempty(cax_par.color_map)
             cax_par.color_map=colormap(parula(24));
         end
    end
    
    %     % adjust color map and add color bar to figures based on user input
    %     function adjust_colors(ax_params,h)
    %         fld=h.CData;
    %         if ~isfield(ax_params,'limits')
    %              colormap(gca,ax_params.color_map);
    %         elseif isempty(ax_params.limits)
    %              colormap(gca,ax_params.color_map);
    %         elseif length(ax_params.limits)==2
    %             colormap(gca,ax_params.color_map);
    %             caxis(ax_params.limits);
    %         else
    %             col_def1 = nan(size(fld));
    %             col_def2 = nan(size(fld));
    %             col_def3 = nan(size(fld));
    %             for ii=1:size(ax_params.color_map,1)
    %                 col_ind=find(fld>ax_params.limits(ii) & fld<=ax_params.limits(ii+1));
    %                 col_def1(col_ind)=ax_params.color_map(ii,1);
    %                 col_def2(col_ind)=ax_params.color_map(ii,2);
    %                 col_def3(col_ind)=ax_params.color_map(ii,3);
    %                 col_ind=find(fld>ax_params.limits(ii) & fld<=ax_params.limits(ii+1));
    %             end
    %             if ~isequal(size(col_def1),(size(fld)))
    %                 col_def=cat(3,col_def1',col_def2',col_def3');
    %             else
    %                 col_def=cat(3,col_def1,col_def2,col_def3);
    %             end
    %             h.CData=col_def;
    %             colormap(gca,ax_params.color_map);
    %             caxis([0 size(ax_params.color_map,1)]);
    %       end
    %     end
    
    % adjust color map and add color bar to figures based on user input
    function col_def=adjust_colors(fld,ax_params)
        if ~isfield(ax_params,'limits') || isempty(ax_params.limits) || length(ax_params.limits)==2
            col_def=fld;
        else
            col_def1 = nan(size(fld));
            col_def2 = nan(size(fld));
            col_def3 = nan(size(fld));
            for ii=1:size(ax_params.color_map,1)
                col_ind=find(fld>ax_params.limits(ii) & fld<=ax_params.limits(ii+1));
                col_def1(col_ind)=ax_params.color_map(ii,1);
                col_def2(col_ind)=ax_params.color_map(ii,2);
                col_def3(col_ind)=ax_params.color_map(ii,3);
            end
            col_def=cat(3,col_def1,col_def2,col_def3);
        end
    end
    
    % add color bar
    function add_colorbar(ax_params,bar_units)
        if ~isfield(ax_params,'limits') || isempty(ax_params.limits)
            colormap(gca,ax_params.color_map);
            hcb=colorbar;
            set(get(hcb,'Title'),'String',bar_units);
        elseif length(ax_params.limits)==2
            colormap(gca,ax_params.color_map);
            hcb=colorbar;
            set(get(hcb,'Title'),'String',bar_units);
            col_length=size(ax_params.color_map,1);
            spacing=(ax_params.limits(2)-ax_params.limits(1))/(col_length);
            caxis_yticks=[(ax_params.limits(1)+spacing):spacing:(ax_params.limits(2)-spacing)];
            while length(caxis_yticks)>16
                caxis_yticks=caxis_yticks(1:2:end);
            end
            set(hcb,'ytick',caxis_yticks);
        else            
            colormap(gca,ax_params.color_map);
            hcb=colorbar;
            set(get(hcb,'Title'),'String',bar_units);            
            col_length=size(ax_params.color_map,1);
            spacing=1/(col_length);
            caxis_yticks=[spacing:spacing:(1-spacing)];
            caxis_ytick_labels=num2str(ax_params.limits(2:end-1)');
            while length(caxis_yticks)>16
                caxis_yticks=caxis_yticks(1:2:end);
                caxis_ytick_labels=caxis_ytick_labels((1:2:end),:);
            end
            set(hcb,'ytick',caxis_yticks);
            set(hcb,'YTickLabel',caxis_ytick_labels);
        end
    end
    
  end
  
end
