classdef rhi_plot
% libirary for creating a RHI.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.1 $
  methods (Static = true)

    function h = call(em,fld_in,ax,varargin)
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
      
      h = rhi_plot.plot(S,Z,ds.moments.(fld),'ax',ax,'az',median(ds.meta_data.azimuth),...
          'alt',ds.meta_data.alt,'radar_location',radar_location,options{:});
      
     emerald_utils.adjust_colors(ds.moments.(fld),fld_in.caxis_params,h,bar_units);
     
    end
    
    function ind = xy2ind(plot_obj,pos,options)
      xdata = get(plot_obj,'XData');
      ydata = get(plot_obj,'YData');
      [~,ind] = min((pos(1)-xdata(:)).^2+(pos(2)-ydata(:)).^2);
      [ind(1),ind(2)] = ind2sub(size(xdata),ind);
      ind = reshape(ind,1,[]);
    end
    
    function h = plot(S,Z,fld,varargin)
      radar_location = [0 0 0]; % depends on mode: 'polar' [x-km y-km z-km], 'lonlat' [lat-deg lon-deg alt-km]: this is for the grid
      alt = [];
      az = NaN;
      ax = [];
      fix_coords = 1;
      contour_field = [];
      contour_vals = [];
      
      % grid info
      %range_rings = 50:50:450;
      %elev_spokes = 0:30:359;
      max_alt = 25;
      
      %paramparse(varargin,{'range_rings'});
      %max_az_spoke_range = range_rings(end);

      % this functionality is not all working
      %alt_tick = []; % units based on alt_tick_units
      %alt_tick_msl = 0; % if 1 then based on msl, otherwise altitude above radar
      %alt_tick_units = 'ft'; % 'ft','m','km'
      %alt_tick_marker = '+'; 
      %alt_tick_color = [.2 .2 .2]; 
      %alt_tick_size = 14;
      %paramparse(varargin,{'az_spokes'});
      %alt_tick_az = az_spokes;

      auto_zoom = 0;
      auto_zoom_pct = 99.9;


      paramparse(varargin);

      if ~isempty(ax)
        fig = get(ax,'Parent');
        set(0,'CurrentFigure',fig)
        set(fig,'CurrentAxes',ax);
      end

      h = surfmat(S,Z,fld,{'fix_coords',fix_coords,'no_colorbar',1});
      
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
      xlabel('Distance (km)');
      ylabel('MSL Altitude (km)');

      axis fill;
      if ~isempty(max_alt) 
        yl = ylim;
        yl(end) = min(yl(end),max_alt);
        ylim(yl);
      end
    end

  end
end
