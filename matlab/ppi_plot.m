classdef ppi_plot
% libirary for creating a PPI.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.5 $
  methods (Static = true)

    function [h labels_out]= call(em,fld_in,ax,varargin)
      options = {};
      
      fld=fld_in.moment_field;
      
      paramparse(varargin);

      mode = 'polar'; % can be 'polar','polar_elcorr', or 'lonlat'
      
      paramparse(options,'mode');
      
      ds = em.get_current_dataset;
     
      [rlat,rlon,ralt] = emerald_utils.get_platform_midloc(ds.meta_data.latitude,ds.meta_data.longitude,ds.meta_data.altitude);
      switch mode
        case 'polar'
          X = ds.meta_data.x;
          Y = ds.meta_data.y;
          radar_location = [0 0 ralt];
        case 'polar_elcorr'
          X = ds.meta_data.x_elcorr;
          Y = ds.meta_data.y_elcorr;
          radar_location = [0 0 ralt];
        case 'lonlat'
          X = ds.meta_data.lon;
          Y = ds.meta_data.lat;
          radar_location = [rlat rlon ralt];
      end          
      
      cdata_plot=emerald_utils.adjust_colors(ds.moments.(fld),fld_in.caxis_params);
            
      [h labels_out] = ppi_plot.plot(X,Y,ds.moments.(fld),cdata_plot,'ax',ax,'elev',median(ds.meta_data.elevation),...
          'alt',ds.meta_data.alt,'radar_location',radar_location,options{:});
      
    end
        
    function ind = xy2ind(plot_obj,pos,options)
      xdata = get(plot_obj,'XData');
      ydata = get(plot_obj,'YData');
      [~,ind] = min((pos(1)-xdata(:)).^2+(pos(2)-ydata(:)).^2);
      [ind(1),ind(2)] = ind2sub(size(xdata),ind);
      ind = reshape(ind,1,[]);
    end
    
    function [h labels_out]= plot(x,y,fld,cdata_plot,varargin)
      mode = 'polar'; % can be 'polar', or 'lonlat' or 'polar_elcorr
      radar_location = [0 0 0]; % depends on mode: 'polar' [x-km y-km z-km], 'lonlat' [lat-deg lon-deg alt-km]: this is for the grid
      alt = [];
      elev = NaN;
      ax = [];
      fix_coords = 1;
      contour_field = [];
      contour_vals = [];
     
      % grid info
      range_rings = 50:50:450;
      az_spokes = 0:30:359;

      paramparse(varargin,{'range_rings'});
      max_az_spoke_range = range_rings(end);

      % this functionality is not all working
      alt_tick = []; % units based on alt_tick_units
      alt_tick_msl = 0; % if 1 then based on msl, otherwise altitude above radar
      alt_tick_units = 'ft'; % 'ft','m','km'
      alt_tick_marker = '+'; 
      alt_tick_color = [.2 .2 .2]; 
      alt_tick_size = 14;
      paramparse(varargin,{'az_spokes'});
      alt_tick_az = az_spokes;

      paramparse(varargin);

      if ~isempty(alt_tick) & isnan(elev)
        error('if the alt_tick are given then elev must be provided');
      end
      if ~isempty(alt) && ~alt_tick_msl
        alt = alt-radar_location(3);
      end


      switch mode
        case 'polar'
          % compute alt profile
          thexaxis = 'X (KM)';
          theyaxis = 'Y (KM)';
        case 'polar_elcorr'
          % compute alt profile
          thexaxis = 'X (KM; elevation corrected)';
          theyaxis = 'Y (KM; elevation corrected)';
        case 'lonlat'
          thexaxis = 'Longitude (deg)';
          theyaxis = 'Latitude (deg)';
      end;


      if ~isempty(ax)
        fig = get(ax,'Parent');
        set(0,'CurrentFigure',fig)
        set(fig,'CurrentAxes',ax);
      end

      h = plot_surf(x,y,fld,cdata_plot);
      
      maxalt = max(alt(:))+1;
      hold on
      if ~isempty(contour_field)
        if ~isequal(size(contour_field),size(fld))
          error('Contour field must be same size as the input field');
        end
        xopts = {};
        if ~isempty(contour_vals)
          xopts = {contour_vals};
        end;
        contour(x,y,tmp,xopts{:},'k');
      end
     
      labels_out={thexaxis;theyaxis};

      axis equal;
      axis fill;
      %axis square
      
      % if no lines are presesnt, draw range rings and spikes
      h_old=findobj(gca, 'type', 'line');
      if length(h_old)==0
          hold on
          at = 0:1:360;
          if isempty(range_rings)
              ar = [0 max_az_spoke_range];
          else
              ar = [0 range_rings(end)];
              [rrlat,rrlon,rralt,rrx,rry] = emerald_utils.polar2cart(range_rings,at,elev,radar_location);
          end
          
          asr = linspace(ar(1),ar(end),100);
          if ~isempty(az_spokes)
              [aslat,aslon,asalt,asx,asy] = emerald_utils.polar2cart(asr,az_spokes,elev,radar_location);
          end
          
          if ~isempty(alt_tick)
              switch alt_tick_units
                  case 'ft'
                      asalt = asalt*3280.84;
                  case 'm'
                      asalt = asalt*1000;
              end
              alt_tick_ranges = interp1(asalt(1,:),asr,alt_tick,'linear');
              [atlat,atlon,atalt,atx,aty] = emerald_utils.polar2cart(alt_tick_ranges,at,elev,radar_location);
              switch alt_tick_units
                  case 'ft'
                      atalt = atalt*3280.84;
                  case 'm'
                      atalt = atalt*1000;
              end
              
          end
          
          
          switch mode
              case {'polar','polar_elcorr'}
                  if ~isempty(range_rings)
                      hh = plot(rrx,rry,'k','HitTest','off');
                  end
                  
                  if ~isempty(az_spokes)
                      hh = plot(asx.',asy.','k','HitTest','off');
                  end
                  
                  if ~isempty(alt_tick)
                      hh = plot(atx,aty,'LineStyle',':','Color',alt_tick_color,'MarkerSize',alt_tick_size,'HitTest','off');
                  end
                  
              case 'lonlat'
                  if ~isempty(range_rings)
                      hh = plot(rrlon,rrlat,'k','HitTest','off');
                  end
                  
                  if ~isempty(az_spokes)
                      hh = plot(aslon.',aslat.','k','HitTest','off');
                  end
                  
                  if ~isempty(alt_tick)
                      hh = plot(atlon,atlat,alt_tick_marker,'Color',alt_tick_color,'MarkerSize',alt_tick_size,'HitTest','off');
                      for ll = 1:prod(size(atlon))
                          hh = text(atlon(ll),atlat(ll),1,alt_tick_marker,'Color',alt_tick_color,'FontSize',alt_tick_size,'HorizontalAlignment','center','VerticalAlignment','middle','Rotation',-ats(ll));
                      end
                  end
                  
          end;
          
          hold off
      end
    end

  end
end
