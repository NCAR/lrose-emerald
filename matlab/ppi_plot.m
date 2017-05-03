classdef ppi_plot
% libirary for creating a PPI.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.5 $
  methods (Static = true)

    function h = call(em,fld,ax,varargin)
      options = {};
      
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
      h = ppi_plot.plot(X,Y,ds.moments.(fld),'ax',ax,'elev',median(ds.meta_data.elevation),'alt',ds.meta_data.alt,'radar_location',radar_location,options{:});
      
    end
    
    % function bdf(obj,event_obj,em,fld,mode)
    %   h = get(event_obj,'Target');
    %   ok = strcmp(get(h,'Type'),'axes') || h==0;
    %   while ~ok
    %     h = get(h,'parent');
    %     ok = strcmp(get(h,'Type'),'axes') || h==0;
    %   end
    %   pos = get(event_obj,'Position');
    %   data = em.get_current_dataset;
    %   if strcmp(mode,'polar')
    %     [~,ind] = min((pos(1)-data.meta_data.x(:)).^2+(pos(2)-data.meta_data.y(:)).^2);
    %   else
    %     [~,ind] = min((pos(1)-data.meta_data.lon(:)).^2+(pos(2)-data.meta_data.lat(:)).^2);
    %   end
    %   if length(ind)<1
    %     return
    %   end
      
    %   s = {sprintf('X: %4f',data.meta_data.x(ind)),
    %                   sprintf('Y: %4f',data.meta_data.y(ind)),
    %                   sprintf('Alt: %4f',data.meta_data.alt(ind)),
    %                   sprintf('Lat: %4f',data.meta_data.lat(ind)),
    %                   sprintf('Lon: %4f',data.meta_data.lon(ind))          };
    %   figure;
    %   uicontrol('Style','edit','Enable','inactive','Units','normalized','Position',[0 0 1 1],'String',s,'Tag',obj.plot_window_tag,'Max',1000,'HorizontalAlignment','left','FontName','fixedwidth');
    % end
    
    function ind = xy2ind(plot_obj,pos,options)
      xdata = get(plot_obj,'XData');
      ydata = get(plot_obj,'YData');
      [~,ind] = min((pos(1)-xdata(:)).^2+(pos(2)-ydata(:)).^2);
      [ind(1),ind(2)] = ind2sub(size(xdata),ind);
      ind = reshape(ind,1,[]);
    end
    
    function h = plot(x,y,fld,varargin)
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

      auto_zoom = 0;
      auto_zoom_pct = 99.9;


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

      h = surfmat(x,y,fld,{'fix_coords',fix_coords,'no_colorbar',1});
      colorbar('East','YAxisLocation','right');
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
      xlabel(thexaxis);
      ylabel(theyaxis);

      hold on
      axis equal;
      axis fill;
      %axis square
      ax = axis;

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
            %hh = plot(atx.',aty.',alt_tick_marker,'color',alt_tick_color,'markersize',alt_tick_size);
            hh = plot(atx,aty,'LineStyle',':','Color',alt_tick_color,'MarkerSize',alt_tick_size,'HitTest','off');
            for ll = 1:prod(size(atlon))
              %hh = text(atx(ll),aty(ll),1,alt_tick_marker,'color',alt_tick_color,'fontsize',alt_tick_size,'horizontalalignment','center','verticalalignment','middle','rotation',-ats(ll));
            end
          end
          
          axis(ax);
          if auto_zoom
            mdist = max(prctile(abs(x(~isnan(fld))),auto_zoom_pct),prctile(abs(y(~isnan(fld))),auto_zoom_pct));
            axis([-1 1 -1 1]*mdist);
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

          axis(ax);
          if auto_zoom
            mdist = max(prctile(abs(x(~isnan(fld))),auto_zoom_pct),prctile(abs(y(~isnan(fld))),auto_zoom_pct));
            axis([-1 1 -1 1]*mdist);
          end
      end;

      hold off
    end

  end
end
