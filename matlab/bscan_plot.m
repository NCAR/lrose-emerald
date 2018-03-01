classdef bscan_plot
% library for bscan plot

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.7 $
  methods (Static = true)

    function h = call(em,fld_in,ax,varargin)
      %dataset = em.current_dataset;
      options = {};
      
      fld=fld_in.moment_field;
      
      paramparse(varargin);
      
      mode = 'altitude'; % can be 'altitude', or 'range'
      
      paramparse(options,'mode');
      
      ds = em.get_current_dataset;
      
      %In altitude mode, check if altitude data has been calculated
      if strcmp(mode,'altitude') & ~isfield(ds.meta_data,'alt')
          mode = 'range';
          disp('Altitude data does not exist. Switching to "range" mode.');
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
      
      cdata_plot=emerald_utils.adjust_colors(ds.moments.(fld),fld_in.caxis_params);
      
      if length(size(cdata_plot))==3;
          cdata_pass=permute(cdata_plot,[2 1 3]);
      else
          cdata_pass=cdata_plot.';
      end
      
      h = bscan_plot.plot(X,Y,ds.moments.(fld).',cdata_pass,'ax',ax,'flip',flip);
      xlabel(xl);
      
      switch mode
          case 'range'
              ylabel('range (KM)');
          case 'altitude'
              ylabel('alt (KM)');
      end
      
%       %adjuds color map
%       if ~isfield(fld_in.axis_params,'limits')
%              colormap(gca,fld_in.axis_params.color_map);
%         elseif isempty(fld_in.axis_params.limits)
%              colormap(gca,fld_in.axis_params.color_map);
%         elseif length(fld_in.axis_params.limits)==2
%             colormap(gca,fld_in.axis_params.color_map);
%             caxis(fld_in.axis_params.limits);
%       else
%             colormap(gca,fld_in.axis_params.color_map);
%             caxis([0 size(fld_in.axis_params.color_map,1)]);
%       end
      
      %emerald_utils.adjust_colors(fld_in.caxis_params,h);
      
      if ~isempty(em.params.ax_limits.x)
          xlim(em.params.ax_limits.x);
      end
      if ~isempty(em.params.ax_limits.y)
          ylim(em.params.ax_limits.y);
      end
      
    end
    
       
    function ind = xy2ind(plot_obj,pos,options)
      xdata = get(plot_obj,'XData');
      ydata = get(plot_obj,'YData');
      [~,ind] = min((pos(1)-xdata(:)).^2+(pos(2)-ydata(:)).^2);
      [ind(2),ind(1)] = ind2sub(size(xdata),ind);
      ind = reshape(ind,1,[]);
    end
    
    
    function h = plot(x,y,fld,cdata_plot,varargin)
      
      ax = [];
      fix_coords = 1;
      flip = 0;
          
      paramparse(varargin);

      if ~isempty(ax)
        fig = get(ax,'Parent');
        set(0,'CurrentFigure',fig)
        set(fig,'CurrentAxes',ax);
      end
      
      h = plot_surf(x,y,fld,cdata_plot);
                      
      if flip
        set(gca,'YDir','reverse');
      end
    end
    
  end
end
