classdef rhi_plot
% libirary for creating a RHI.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.1 $
  methods (Static = true)

    function [h labels_out] = call(em,fld_in,ax,varargin)
      options = {};
      
      fld=fld_in.moment_field;
      
      paramparse(varargin);

      mode = 'polar'; % can be 'polar','polar_elcorr', or 'lonlat'
      
      paramparse(options,'mode');
      
      ds = em.get_current_dataset;
      
      try
          bar_units=ds.moments_info.(fld).atts.units.data;
      catch
          bar_units='';
      end
      
      X = ds.meta_data.x_elcorr;
      Y = ds.meta_data.y_elcorr;
      S = sqrt(X.^2+Y.^2);
      elev = circ_arith(ds.meta_data.elevation,180);
      inds = elev>90 | elev < -90;
      S(inds,:) = -S(inds,:);
      Z = ds.meta_data.alt;
      
      [~,~,ralt] = emerald_utils.get_platform_midloc(ds.meta_data.latitude,ds.meta_data.longitude,ds.meta_data.altitude);
      radar_location = [0 0 ralt];
      
      cdata_plot=emerald_utils.adjust_colors(ds.moments.(fld),fld_in.caxis_params);
            
      [h labels_out] = rhi_plot.plot(S,Z,ds.moments.(fld),cdata_plot,'ax',ax,'az',median(ds.meta_data.azimuth),...
          'alt',ds.meta_data.alt,'radar_location',radar_location,options{:});
    end
    
    function ind = xy2ind(plot_obj,pos,options)
      xdata = get(plot_obj,'XData');
      ydata = get(plot_obj,'YData');
      [~,ind] = min((pos(1)-xdata(:)).^2+(pos(2)-ydata(:)).^2);
      [ind(1),ind(2)] = ind2sub(size(xdata),ind);
      ind = reshape(ind,1,[]);
    end
    
    function [h labels_out] = plot(S,Z,fld,cdata_plot,varargin)
      radar_location = [0 0 0]; % depends on mode: 'polar' [x-km y-km z-km], 'lonlat' [lat-deg lon-deg alt-km]: this is for the grid
      alt = [];
      az = NaN;
      ax = [];
      fix_coords = 1;
      contour_field = [];
      contour_vals = [];
    
      max_alt = 25;
      
      paramparse(varargin);

      if ~isempty(ax)
        fig = get(ax,'Parent');
        set(0,'CurrentFigure',fig)
        set(fig,'CurrentAxes',ax);
      end

      h = plot_surf(S,Z,fld,cdata_plot);
      
      hold on
      if ~isempty(contour_field)
        if ~isequal(size(contour_field),size(fld))
          error('Contour field must be same size as the input field');
        end
        xopts = {};
        if ~isempty(contour_vals)
          xopts = {contour_vals};
        end;
        contour(S,Z,tmp,xopts{:},'k');
      end
      labels_out={'Distance (km)';'MSL Altitude (km)'};

      axis fill;
      if ~isempty(max_alt) 
        yl = ylim;
        yl(end) = min(yl(end),max_alt);
        ylim(yl);
      end
    end

  end
end
