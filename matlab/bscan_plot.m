classdef bscan_plot
% library for bscan plot

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.7 $
  methods (Static = true)

    function h = call(em,fld,ax,varargin)
      %dataset = em.current_dataset;
      options = {};
      
      paramparse(varargin);
      
      mode = 'altitude'; % can be 'altitude', or 'range'
      
      paramparse(options,'mode');
      
      ds = em.get_current_dataset;
      
      %In altitude mode, check if altitude data has been calculated
      if strcmp(mode,'altitude') & ~isfield(ds.meta_data,'alt')
          mode = 'range';
          disp('Altitude data does not exist. Switching to "range" mode.');
      end
      
      try
          bar_units=ds.moments_info.(fld).atts.units.data;
      catch
          bar_units='';
      end
      
      if isempty(emerald_utils.check_fields_exist(ds.meta_data,'time')) && all(diff(ds.meta_data.time))~=0
        x = ds.meta_data.time-24*3600*(ds.meta_data.time_start_mld-ds.meta_data.time_coverage_start_mld);
        xl = sprintf('Seconds from %s',datestr(ds.meta_data.time_start_mld,'yyyy-mm-ddTHH:MM:SSZ'));
      else
        x = 1:size(ds.moments.(fld),1);
        xl = 'beam index';
      end
      
      flip = 0;
      
      switch mode
          case 'range'
              Y = ds.meta_data.range;
              [X,Y]=meshgrid(x,ds.meta_data.range);
              if nan_mean(ds.meta_data.elevation)<-20
                  flip = 1;
              end
          case 'altitude'
              Y = ds.meta_data.alt';
              X = repmat(x,1,size(Y,1))';
      end
      
      h = bscan_plot.plot(X,Y,ds.moments.(fld).','ax',ax,'flip',flip);
      xlabel(xl);
      
      switch mode
          case 'range'
              ylabel('range (KM)');
          case 'altitude'
              ylabel('alt (KM)');
              ylim([-1,8]);
      end
      
      emerald_utils.add_colorbar(bar_units,fld);
    end
    
    % function bdf(obj,event_obj,em,fld,mode)
    %   h = get(event_obj,'Target');
    %   ok = strcmp(get(h,'Type'),'axes') || h==0;
    %   while ~ok
    %     h = get(h,'Parent');
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
      [ind(2),ind(1)] = ind2sub(size(xdata),ind);
      ind = reshape(ind,1,[]);
    end
    
    
    function h = plot(x,y,fld,varargin)
      
      ax = [];
      fix_coords = 1;
      flip = 0;
          
      paramparse(varargin);

      if ~isempty(ax)
        fig = get(ax,'Parent');
        set(0,'CurrentFigure',fig)
        set(fig,'CurrentAxes',ax);
      end
      
      %[x,y]=meshgrid(x,y);
      h = surfmat(x,y,fld,{'fix_coords',fix_coords,'no_colorbar',1});
                 
      if flip
        set(gca,'YDir','reverse');
      end
    end
    
  end
end
