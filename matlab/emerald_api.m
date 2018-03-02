classdef emerald_api < handle
% This class contains the API for the GUI part of emerald.  It makes use of the
% emerald_databuffer and emerald_dataset classes, along with plots.  Most users
% will just use the GUI directly by calling emerald
% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


% $Revision: 1.9 $
  
  properties (GetAccess = public, SetAccess = public, SetObservable)
    % setable
    user_config_file = ''; 
    override_params = struct;
  end
  
  properties (GetAccess = public,SetAccess = private)
    % only for display
    default_config_file = 'emerald_default_config'; 
    default_params = struct; % struct with defaults from default config
    user_config_params = struct; % struct with defaults from user config
    params = struct; % final settings struct which incorporates the default/user/override_params
    axes_handles = []; % handles of all the axes on the figure
    fig = []; % handle of the figure
    current_dataset = 1; % pointer into the databuffer
    plotted_dataset = []; % dataset currently plotted
    plot_window_title = [];
    plots = {}; % listing of the currently selected plots
    plotted = {}; % plots that are actually currently in the figure
    polygon_list = []; % polygon listing
    mode = NaN; % current user mode (NaN,'polygon')
    links = {}; % listing of linked axes

    datainfo_fields = {};
    modify_dataset_info = struct;
    workspace_save_var = '';
  end
  
  methods 
    
    % constructor 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% emerald_api
    function obj = emerald_api(varargin)
    % obj = emerald_api(varargin)
    % first arguement, if given, is the user_config_file
      if length(varargin)>0 && ~isempty(varargin{1})
        obj.user_config_file = varargin{1};
      end
      
      
      % create databuffer
      emerald_databuffer.create_databuffer;
      % load default config
      obj.default_params = obj.load_config(obj.default_config_file);
      % load user config
      obj.user_config_params = obj.load_config(obj.user_config_file);
      % add user options
      if length(varargin)>=1
        obj.override_params = paramparses(obj.override_params,varargin(2:end),{},'none');
      end
      % regenerate current params
      obj.regenerate_params;
      
      % if user changes user_config_file or override_params, rerun the regenerate params
      addlistener(obj,'user_config_file','PostSet',@obj.regenerate_params);
      addlistener(obj,'override_params','PostSet',@obj.regenerate_params);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% set.user_config_file
    function set.user_config_file(obj,filename)
    % if user sets the user config file name, set it and load it.  The listener will regenerate params
      obj.load_config(filename);
      obj.user_config_file = filename;
    end
    
    %%%%%%%%%%%%
    %% axes_handles_list
    function hl = axes_handles_list(obj)
    % Function to return valid axes_handles in a list.
      hl = obj.axes_handles.';
      hl = hl(ishandle(hl)).';
    end
    
    %%%%%%%%%%%%%%%%%%%%%%
    %% check_plot_window
    function [res,msg] = check_plot_window(obj,varargin)
      check_figure = 1;
      check_figure_tag = 1;
      check_axes = 0;
      
      paramparse(varargin);
      
      res = emerald_errorcodes.OK;
      msg = '';
      
      if check_figure
        if isempty(obj.fig)
          res = emerald_errorcodes.NO_EMERALD_FIGURE;
          msg = 'Emerald window not started';
          return;
        end
        
        if ~ishandle(obj.fig)
          res = emerald_errorcodes.EMERALD_FIGURE_KILLED;
          msg = 'Emerald window was killed';
          return;
        end
        
        if ~strcmp(get(obj.fig,'type'),'figure')
          res = emerald_errorcodes.BAD_EMERALD_FIGURE_HANDLE;
          msg = 'Emerald figure handle is bad';
          return
        end
      
        if check_figure_tag && ~strcmp(get(obj.fig,'Tag'),obj.plot_window_tag)
          res = emerald_errorcodes.NOT_EMERALD_FIGURE;
          msg = 'The Emerald figure handle is does not point to an emerald plot window figure.';
          return
        end
      end
      
      if check_axes
        if isempty(obj.axes_handles)
          res = emerald_errorcodes.NO_AXES;
          msg = 'Axes have not been initialized';
          return
        end
        
        if any(~ishandle(obj.axes_handles_list))
          res = emerald_errorcodes.BAD_AXES_HANDLES;
          msg = 'At least one axes object seems to have been removed.';
          return
        end
      end        
    end      
    
    %%%%%%%%%%%%%
    %% check_plots
    function [res,msg] = check_plots(obj,varargin)
      res = emerald_errorcodes.OK;
      msg = '';
      
      if isempty(obj.plots)
        res = emerald_errorcodes.NO_PLOTS;
        msg = 'No plots have been selected';
        return
      end
      
      if length(obj.plots)~=obj.params.plot_panels
        res = emerald_errorcodes.WRONG_NUMBER_OF_PLOTS;
        msg = 'The number of plots does not match the plot_panels';
        return;
      end
        
    end
    
    %%%%%%%%%%%%%
    %% check_current_dataset
    function [res,msg] = check_current_dataset(obj,varargin)
      res = emerald_errorcodes.OK;
      msg = '';
      
      if emerald_databuffer.databuffer_length==0
        res = emerald_errorcodes.NO_DATA;
        msg = 'No data loaded';
        return
      end
      
      if isempty(obj.current_dataset)
        res = emerald_errorcodes.NO_DATASET_SELECTED;
        msg = 'No dataset was selected';
        return
      end
              
      [res,msg] = emerald_dataset.check_single_dataset(obj.get_current_dataset);
        
    end
    
    
    %%%%%%%%
    %% MsgBox
    function [hf,hu] = msgbox(obj,msg)
    % Routine to create a message box
      hf = dialog;
      pos = get(hf,'Position');
      set(hf,'position',[pos(1:2) [200 100]]);
      hu = uicontrol(hf,'Style','text','Units','normalized','Position',[0.1 .01 .98 .98],'String',msg,'Tag',obj.plot_window_tag,'Max',1000,'HorizontalAlignment','center','FontName','fixedwidth','FontSize',14);
      drawnow;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_tag
    function s = plot_window_tag(obj)
    % function for generating a unique plot_tag.

    % check the plot is ok, but do not check that the tag is ok, otherwise end up in a inf loop.
      [res,msg] = obj.check_plot_window('check_figure_tag',0);
      if any(res == [emerald_errorcodes.NO_EMERALD_FIGURE emerald_errorcodes.EMERALD_FIGURE_KILLED])
        % if there is no figure, then die.
        obj.params.error_function(sprintf('Cannot create a plot_window_tag since there is not plot window: %s',msg));
        return
      end
      s = sprintf('EMERALD_%i',ghandle(obj.fig));
    end
        
    %%%%%%%
    %% create_plot_window_title
    function create_plot_window_title(obj,varargin)
    % Function to create or refresh the plot_window_title
      
    % get size in points
      [res,msg] = obj.check_plot_window;
      if res
        obj.params.error_function(sprintf('Cannot create a plot_window_title since there is not plot window: %s',msg));
        return
      end
      fig = obj.fig;
      old_units = get(fig,'Units');
      set(fig,'Units','points');
      p = get(fig,'Position');
      set(fig,'units',old_units);
      % compute the new position
      new_pos = [0 p(4)-obj.params.plot_window_title.height p(3) obj.params.plot_window_title.height];
      if ~isempty(obj.plot_window_title) && ishandle(obj.plot_window_title)
        % if already exists, just move it
        set(obj.plot_window_title,'Position',new_pos);
      else
        % if not there, create it.
        obj.plot_window_title = uicontrol(fig,'Style','text','String','','Units','points','Position',new_pos,'HorizontalAlignment','center','Tag','plot_window_title');
      end
    end
    
    %%%%%%
    %% redraw
    function redraw(obj,varargin)
    % function to redraw the main objects.  This should be called after a figure resize automatically
      obj.create_plot_window_title(varargin);
      obj.plot_window_add;
      %obj.ender_plots;

      res = obj.check_plots || obj.check_plot_window('check_axes',1);
      if res
        return;
      end
      ah = obj.axes_handles_list;
      plots = obj.plots;
      for ll = 1:length(ah)
        h = ah(ll);
        plot_info = obj.params.available_plots(plots(ll).plot_type);
        if ~isequal(plot_info.call,'NONE') && plot_info.fill
          axis(h,'fill');
        end
      end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_add
    function plot_window_add(obj)
    % Routine to add/reposition the axes
      [res,msg] = obj.check_plot_window;
      if res
        obj.params.error_function('Could not add plots since there is a problem with the plot_window: %s',msg);
        return
      end
      [res,msg] = obj.check_plot_window('check_axes',1,'check_figure',0);
      if ~res
        npc = obj.axes_handles;
        args = {'refresh_sizes',1};
      else
        switch obj.params.plot_panels
          case 1
            npc = 1;
          case 2
            npc = [1 1];
          case 3
            npc = [2 1];
          case 4 
            npc = [2 2];
          otherwise
            npc = floor(sqrt(obj.params.plot_panels));
            npc = repmat(npc,1,ceil(obj.params.plot_panels/npc));
            npc(end) = npc(end) - (sum(npc)-obj.params.plot_panels);
        end
        args = {};
      end
      plot_window = obj.params.plot_window;
      obj.axes_handles = axes_grid(obj.fig,npc,'spacing',[plot_window.horizontal_spacing plot_window.vertical_spacing],...
                                   'margins',[plot_window.left_margin plot_window.right_margin plot_window.top_margin plot_window.bottom_margin],...
                                   'input_units','points',args{:});
     
    end
          
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_create
    function plot_window_create(obj)
    % GUI routine for creating the main window with menus and title bar.  
      [res,msg] = obj.check_plot_window;
      if ~res
        % don't create anything.
        obj.redraw;
        return;
      end
      fig = figure('renderer',obj.params.plot_window.renderer,'Position',obj.params.plot_window.position,'MenuBar','none','ToolBar','figure','Name','EMERALD');
      set(fig,'ResizeFcn',@obj.redraw);
      obj.fig = fig;
      obj.axes_handles = [];
      % set tag and add hooks for the keyboard shortcuts
      set(fig,'Tag',obj.plot_window_tag);
      set(fig,'KeyReleaseFcn',@obj.keyrelease_callback);
      obj.plot_window_add;
      
      % Create Menu items.
      fileh = uimenu(fig,'Label','File');
      uimenu(fileh,'Label','Quit','Callback',@(x,y) obj.plot_window_close_fcn);

      datah = uimenu(fig,'Label','Data');
      uimenu(datah,'Label','Fetch All from Files','Callback',@(x,y) obj.fetch_all_from_files);
      uimenu(datah,'Label','Fetch by Selection','Callback',@(x,y) obj.fetch_by_selection);
      uimenu(datah,'Label','Print Databuffer','Callback',@(x,y) obj.show_databuffer_inventory,'separator','on');
      uimenu(datah,'Label','Select Dataset','Callback',@(x,y) obj.select_current_dataset);
      uimenu(datah,'Label','Delete Dataset(s)','Callback',@(x,y) obj.delete_dataset,'separator','on');
      uimenu(datah,'Label','Clear Databuffer','Callback',@(x,y) obj.clear_databuffer);
      uimenu(datah,'Label','Modify Dataset','Callback',@(x,y) obj.modify_current_dataset,'separator','on');
      
      ploth = uimenu(fig,'Label','Plots');
      uimenu(ploth,'Label','Select Plots','Callback',@(x,y) obj.plot_window_pick_plots);
      uimenu(ploth,'Label','Render Plots','Callback',@(x,y) obj.render_plots);
      uimenu(ploth,'Label','Zoom Lock','Callback',@(x,y) obj.zoom_lock,'Separator','on','Checked',obj.tf2onoff(obj.params.zoom_lock));
      %uimenu(ploth,'Label','Color Axis Lock','Callback',@(x,y) obj.caxis_lock,'Checked',obj.tf2onoff(obj.params.caxis_lock));
      %subploth=uimenu(ploth,'Label','Color Axis Lock');
      uimenu(ploth,'Label','Data Info Fields','Callback',@(x,y) obj.update_datainfo,'Separator','on');
      
      plota = uimenu(fig,'Label','Analysis');
      uimenu(plota,'Label','Histogram from current axes (CTRL-click in polygon mode)','Callback',@(x,y) obj.plot_window_hist_from_polygon);
      uimenu(plota,'Label','Scatter plot from two variables','Callback',@(x,y) obj.plot_scatter_vars);
      
     % add submenu for color axis lock
%       if length(obj.params.caxis_lock)~=obj.params.plot_panels
%           obj.params.caxis_lock=cat(2,reshape(obj.params.caxis_lock,1,[]),ones(1,obj.params.plot_panels-length(obj.params.caxis_lock)));
%       end
          
%       for ii=1:obj.params.plot_panels
%           uimenu(subploth,'Label',['Panel ' num2str(ii)],'Callback',@(x,y) obj.caxis_lock(ii),...
%               'Checked',obj.tf2onoff(obj.params.caxis_lock(ii)));
%       end
      
      plotp = uimenu(fig,'Label','Polygon');
      %uimenu(plotp,'Label','Polygon Mode On','callback',@(x,y) obj.plot_window_polygon_mode);
      %uimenu(plotp,'Label','Polygon Mode Off','callback',@(x,y) obj.plot_window_polygon_mode_off);
      uimenu(plotp,'Label','Polygon Mode','Callback',@(x,y) obj.plot_window_polygon_mode,'Checked',obj.tf2onoff(strcmp(obj.mode,'Polygon')));
      uimenu(plotp,'Label','Reset Polygon','Callback',@(x,y) obj.plot_window_polygon_reset);
      uimenu(plotp,'Label','Delete Last Point (Shift-click)','Callback',@(x,y) obj.plot_window_polygon_deletelast);
      %uimenu(plotp,'Label','Histogram from current axes (CTRL-click)','Callback',@(x,y) obj.plot_window_hist_from_polygon,'Separator','on');
      uimenu(plotp,'Label','Assign & Save to Variable','Callback',@(x,y) obj.assign_save_polygon_var,'Separator','on');
      uimenu(plotp,'Label','Append Polygon data to Variable','Callback',@(x,y) obj.save_polygon_data_to_var);
      
      %plotc = uimenu(fig,'Label','CrossSec','Callback',@(x,y) ppi_cross_section.plot_cross_section(obj));      

      ploth = uimenu(fig,'Label','Help');
      uimenu(ploth,'Label','About','Callback',@(x,y) obj.about);
      
      % Add buttons to step through buffer
      hToolbar = findall(fig,'tag','FigureToolBar');
      % Load arrow icon
      icon = fullfile(matlabroot,'/toolbox/matlab/icons/greenarrowicon.gif');
      [cdata,map] = imread(icon);
      % Convert white pixels into a transparent background
      map(find(map(:,1)+map(:,2)+map(:,3)==3)) = NaN;
      % Convert into 3D RGB-space
      cdataStepForward = ind2rgb(cdata,map);
      cdataStepBack = cdataStepForward(:,[16:-1:1],:);
      
      % Add the icons to toolbar
      hPrev = uipushtool(hToolbar,'cdata',cdataStepBack,'Enable','off', 'tooltip','Previous file', 'ClickedCallback',@(x,y) obj.prev_in_buffer);
      hNext = uipushtool(hToolbar,'cdata',cdataStepForward,'Enable','off', 'tooltip','Next file', 'ClickedCallback',@(x,y) obj.next_in_buffer);
      set(hPrev,'Separator','on');
      
      % modify the data cursor so that it only returns x and y
      h = datacursormode(fig);
      h.UpdateFcn = @(x,y) obj.default_datacursor_text(x,y);
      
      % info bar
      obj.create_plot_window_title
    end 
    
    %%%% 
    %% keyrelease_callback
    function keyrelease_callback(obj,src,event)
    % call back for the key presses
      switch event.Key
        case 'leftarrow'
          obj.current_dataset = max(1,obj.current_dataset-1);
          obj.render_plots;
        case 'rightarrow'
          obj.current_dataset = min(emerald_databuffer.databuffer_length,obj.current_dataset+1);
          obj.render_plots;
      end
    end
    
    %%%% 
    %% keyrelease_callback
    function about(obj)
    % routine to display the about
      figure('ToolBar','none','MenuBar','none','Units','points','Position',[ 207.2000  296.8000  656.0000  336.0000]);
      s = sprintf('\n\n\nE M E R A L D\n\nVersion %s\n\nWritten by Gregory Meymaris (UCAR)\nThis software was written under the sponsorship of the National Science Foundation\n\n(C) 1992 - 2015 UCAR; All Rights Reserved\nSee LICENSE.TXT for more information.',emerald_utils.get_version);
      uicontrol('Style','edit','Enable','inactive','Units','normalized','Position',[0 0 1 1],'String',s,'Tag',obj.plot_window_tag,'Max',1000,'HorizontalAlignment','center','FontName','fixedwidth');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_pick_plots
    function plot_window_pick_plots(obj)
    % GUI for getting the plot windows.  This just creates the dialog and sets up the callbacks
      [res,msg] = obj.check_plot_window;
      if res
        obj.params.error_function(sprintf('ERROR: %s',msg));
        return
      end
      fig = dialog;
      p = get(obj.fig,'Position');
      mid = [p(1)+.5*p(3) p(2)+.5*p(4)];
      pd = get(fig,'Position');
      set(fig,'Position',round([mid(1)-.5*pd(3) mid(2)-.5*pd(4) pd(3:4)]),'Name','Pick Plots');
      
      ds = obj.get_current_dataset;
      opts = {'Style','listbox','Units','normalized','HorizontalAlignment','left','FontName','fixedwidth'};

      hs = obj.axes_handles_list;
      sz = [.20 .35];
      pos = [.05 .6;
             .55 .6;
             .05 .2;
             .55 .2];
      uihs = []; % control handles
      moments = fieldnames(ds.moments);
      avail_plots = obj.params.available_plots;
      plot_default = find(strcmp(obj.params.default_plot,{avail_plots.name}));

      for ll = 1:obj.params.plot_panels
        iv = {'value',1};
        if ~isempty(obj.plots)
          % initialize the list to the current field
          iv = {'Value',find(strcmp(obj.plots(ll).moment_field,moments))};
        elseif length(moments)>=ll
          % initialize to the llth field
          iv = {'Value',ll};
        end
        % add the control for the field selector for this plot
        uihs(end+1) = uicontrol(opts{:},'Position',[pos(ll,:) sz],'String',moments,iv{:});

        iv = {'Value',1};
        if ~isempty(obj.plots)
          % initialize the list to the current plot type
          iv = {'Value',obj.plots(ll).plot_type};
        elseif ~isempty(plot_default)
          % intialize to the default plot type
          iv = {'Value',plot_default(1)};
        else
          % don't initialize
          iv = {};
        end
        % add the control for the plots
        uihs(end+1) = uicontrol(opts{:},'Position',[pos(ll,:)+[sz(1) 0] sz],'String',{avail_plots.name},iv{:});
      end
      
      % add an ok button.  The call back will activate plot_window_pickplot_okcallback
      uicontrol('Style','pushbutton','Units','normalized','String','OK','Callback',@(x,y) obj.plot_window_pickplot_okcallback(fig,uihs,moments),'Position',[0 0 .5 .1]);
    
    
    end
    
    %%%%%%%%
    %% default_plot_state_struct
    function out = default_plot_state_struct(obj,varargin)
      out = struct('moment_field','','plot_type',{1},'original_zoom',{},'caxis_params',{});
      out = paramparses(out,varargin);
    end
      
      
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_pickplot_okcallback
    function plot_window_pickplot_okcallback(obj,fig,uihs,moments)
    % The callback routine for the plot_window_pick_plots
      plots = obj.default_plot_state_struct;
      old_plots = obj.plots;
      ah = obj.axes_handles_list;
      % run through the controls, pulling out the appropriate plot for each and setting the plots
      for ll = 1:obj.params.plot_panels
        plots(ll).moment_field = moments{get(uihs((ll-1)*2+1),'Value')};
        plots(ll).caxis_params = emerald_utils.find_caxis_params(plots(ll).moment_field,obj.params.caxis_limits,obj.params.color_map);
        plots(ll).plot_type = get(uihs((ll-1)*2+2),'Value');
        if length(old_plots)>=ll && old_plots(ll).plot_type~=plots(ll).plot_type
          cla(ah(ll));
        end
      end
      close(fig);
      % save it and no render the plots
      obj.plots = plots;
      obj.render_plots;
    end
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% render_plots
    function render_plots(obj)
    % Render the plots
    
    %Set mouse pointer to hour glass
    oldpointer = get(obj.fig, 'pointer');
    set(obj.fig, 'pointer', 'watch')
    drawnow;
    
      [res,msg] = obj.check_plot_window('check_axes',1);
      if res
        %obj.params.error_function(sprintf('ERROR: %s',msg'));
        return;
      end
      
      [res,msg] = obj.check_current_dataset;
      if res
        %obj.params.error_function(sprintf('ERROR: %s',msg'));
        return;
      end

      [res,msg] = obj.check_plots;
      if res
        %obj.params.error_function(sprintf('ERROR: %s',msg'));
        return;
      end
       
       
      % get the axes handles
      ah = obj.axes_handles_list;
      % clear links
      obj.links = {};
      linkaxes(ah,'off');
      
      % check which plots have changed need to be updated
      if obj.current_dataset~=obj.plotted_dataset | isempty(obj.plotted)
          to_plot=1:obj.params.plot_panels;
      else
          to_plot=[];
          for ii=1:obj.params.plot_panels
              if ~isequal(obj.plots(ii).moment_field,obj.plotted(ii).moment_field) ...
                      | ~isequal(obj.plots(ii).plot_type,obj.plotted(ii).plot_type)
                  to_plot=[to_plot ii];
              end
          end
      end
            
      labels_panel=cell(obj.params.plot_panels,1);
      % now run through list populating the plot
      plots = obj.plots;
      set(ah,'Nextplot','replace');
      for kk = 1:length(to_plot)
          ll=to_plot(kk);
          h = ah(ll);
          plot_info = obj.params.available_plots(plots(ll).plot_type);
          if ~isequal(plot_info.name,'NONE')
              try
                  % save zoom info
                  if length(findobj(h))>1
                      plots(ll).last_zoom = axis(h);
                  else
                      plots(ll).last_zoom = [];
                  end
                  
                  %actual plotting routine
                 [h labels_panel{ll}]=plot_info.call(obj,plots(ll),h,'options',plot_info.options);
                  
                  % check which plot components need to be updated
                  % colorbar and title
                  if isempty(obj.plotted) || ~isequal(obj.plots(ll).moment_field,obj.plotted(ll).moment_field)
                      ds = obj.get_current_dataset;
                      try
                          bar_units=ds.moments_info.(obj.plots(ll).moment_field).atts.units.data;
                      catch
                          bar_units='';
                      end
                      emerald_utils.add_colorbar(plots(ll).caxis_params,bar_units);
                      %plot title if necessary
                      title(plots(ll).moment_field,'Interpreter','none')
                  end
                  
                  plots(ll).original_zoom = axis;
                  
                  % axis limits
                  if obj.params.zoom_lock && ~isempty(plots(ll).last_zoom)
                      axis(h,plots(ll).last_zoom);
                  else
                      if ~isempty(obj.params.ax_limits.x)
                          xlim(obj.params.ax_limits.x);
                      end
                      if ~isempty(obj.params.ax_limits.y)
                          ylim(obj.params.ax_limits.y);
                      end
                  end
                  
              catch ME
                  cla(h);
                  %axes(h);
                  %text(.1,.95,sprintf('ERROR: %s',ME.message),'interpreter','none');
                  warning(sprintf('ERROR: %s',ME.message));
              end
          end
      end
      
      % plot labels where necessary
      h_all = obj.axes_handles;
      
      labels_panel=reshape(labels_panel,size(h_all))';
            
      h = h_all(:,1);
      h = h(ishandle(h));
      
      for ll = 1:length(h)
          current_label=h(ll).YLabel.String;
          if ~isempty(labels_panel{ll,1}) && ...
                  (isempty(current_label) || ~strcmp(current_label,labels_panel{ll,1}{2,1}))
              ylabel(h(ll),labels_panel{ll,1}{2,1});
          end
      end
      
      h = h_all(end,:);
      h = h(ishandle(h));
      for ll = 1:length(h)
          current_label=h(ll).XLabel.String;
          if ~isempty(labels_panel{end,ll}) && ...
                  (isempty(current_label) || ~strcmp(current_label,labels_panel{end,ll}{1,1}))
              xlabel(h(ll),labels_panel{end,ll}{1,1});
          end
      end
      
      U = obj.get_active_plot_types;
      for ll = 1:length(U)
        inds = obj.get_same_plot_types(U(ll));
        %linkaxes(ah(~isnan(ah)&inds),'xy');
        set(ah(ishandle(ah)&inds),'XLimMode','manual','YLimMode','manual');
        obj.links{end+1} = linkprop(ah(ishandle(ah)&inds),{'XLim','YLim'});
      end

      h = obj.plot_window_title;
      old_title=h.String;
      s = emerald_databuffer.databuffer_inventory_string('dataset',obj.current_dataset,'mode',2);
      new_title=sprintf('(%i) %s',obj.current_dataset,s);
      if ~strcmp(old_title,new_title)
          set(h,'string',new_title);
      end
      
      if ~isempty(obj.polygon_list)
          obj.redraw_polygon;
      end
      
      % check if figure toolbar push buttens need to be updated
      check_arrows(obj);

      % save plotted variables so we can check them later
      obj.plotted=plots;
      obj.plotted_dataset=obj.current_dataset;
      
      %set mouse pointer back
      set(obj.fig, 'pointer', oldpointer)
    end
    
    %%%%%
    % get_active_plot_types
    function U = get_active_plot_types(obj)
      U = unique([obj.plots(1:obj.params.plot_panels).plot_type]);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % get_same_plot_types
    function inds = get_same_plot_types(obj,plot_type)
      inds = [obj.plots(1:obj.params.plot_panels).plot_type]==plot_type;
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_close_fcn
    function plot_window_close_fcn(obj,varargin)
      objs = findobj(0,'Type','figure','Tag',obj.plot_window_tag);
      close(objs);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% zoom_lock
    function zoom_lock(obj)
      obj.params.zoom_lock = ~obj.params.zoom_lock;
      set(findobj(obj.fig,'Type','uimenu','Label','Zoom Lock'),'Checked',obj.tf2onoff(obj.params.zoom_lock));
    end
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% caxis_lock
%     function caxis_lock(obj,ii)
%       obj.params.caxis_lock(ii) = ~obj.params.caxis_lock(ii);
%       set(findobj(obj.fig,'Type','uimenu','Label',['Panel ' num2str(ii)]),...
%           'Checked',obj.tf2onoff(obj.params.caxis_lock(ii)));
%     end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% update_datainfo
    function update_datainfo(obj)
      ds = obj.get_current_dataset;
      moments = fieldnames(ds.moments);
      di_flds = obj.datainfo_fields;
      di_flds = cellfun(@(x) find(strcmp(x,moments)),di_flds);
      
      [selection,ok] = listdlg('ListString',moments,'SelectionMode','multiple','InitialValue',di_flds,'Name','Pick Moments to display');
      
      if ~ok 
        return
      end
      
      obj.datainfo_fields = moments(selection);
      
    end
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% modify_current_dataset
    function modify_current_dataset(obj)
      if isempty(obj.modify_dataset_info) | length(fieldnames(obj.modify_dataset_info))==0
        obj.modify_dataset_info = struct('type',{'mask'},'expression',{''},'apply_to',{{}});
      end
      
      answer = obj.modify_dataset_info.expression;
      
      ok = 0;
      
      while ~ok
      
        answer = inputdlg('Mask Expression: example: abs(data.ZDR)<3 & data.SNR>3','Specify criteria to keep.',10,{answer},'on');
      
        if isempty(answer)
          return;
        end
        answer = answer{1};
        ds = obj.get_current_dataset;
        data = ds.moments;

        try
          inds = eval(answer);
          ok = 1;
        catch ME
          warning(ME.message,'Invalid expression');
        end
        
      end
      
      obj.modify_dataset_info.expression = answer;
      
      flds = fieldnames(data);
      
      selected_flds = cellfun(@(x) find(strcmp(x,flds)),obj.modify_dataset_info.apply_to);
      
      [selection,ok] = listdlg('ListString',flds,'SelectionMode','multiple','InitialValue',selected_flds,'Name','Pick Moments to display');
      
      if ~ok 
        return
      end
      
      obj.modify_dataset_info.apply_to = flds(selection);
      
      for ll = 1:length(obj.modify_dataset_info.apply_to)
        fld = obj.modify_dataset_info.apply_to{ll};
        ds.moments.(fld)(~inds) = NaN;
      end
      emerald_databuffer.add_to_databuffer(ds,obj.current_dataset);
      obj.current_dataset = obj.current_dataset+1;
      obj.render_plots;
    end
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% plot_window_polygon_mode
    function plot_window_polygon_mode(obj)
      if ~isequal(obj.mode,'Polygon')
        obj.plot_window_setup_axes;
      else
        obj.plot_window_polygon_mode_off;
        obj.mode = NaN;
        set(findobj(obj.fig,'Type','uimenu','Label','Polygon Mode'),'Checked','off')
        set(findobj(obj.fig,'Type','uimenu','Label','Polygon'),'ForegroundColor','black');
      end
    end
    
    function plot_window_setup_axes(obj)
      h = obj.axes_handles_list;
      set(h,'NextPlot','add');
      ch = setdiff(findobj(h),h);
      
      set(ch,'HitTest','off');
      
      set(h,'ButtonDownFcn',@(x,y) obj.polygon_mode_bdf(x,y));
      obj.mode = 'Polygon';
      set(findobj(obj.fig,'Type','uimenu','Label','Polygon Mode'),'Checked','on');
      set(findobj(obj.fig,'Type','uimenu','Label','Polygon'),'ForegroundColor',[0.7 0 0]);
    end
    
    function plot_window_polygon_mode_off(obj)
      h = obj.axes_handles_list;
      ch = setdiff(findobj(h),h);
      
      set(ch,'HitTest','on');
      
      set(h,'ButtonDownFcn','');
      
    end
    
    function plot_window_hist_from_polygon(obj,ax)
      if nargin<2 || isempty(ax)
        ax = gca;
      end
            
      ds = obj.get_current_dataset;
      t = get_axes_text(ax);
      
      hs = findobj(ax,'Type','surface');
      xdata = get(hs,'XData');
      ydata = get(hs,'YData');
      %cdata = get(hs,'CData');
      cdata = ds.moments.(t);
      
      cdata=cat(1,cdata,cdata(end,:));
      cdata=cat(2,cdata,cdata(:,end));
      
      % make sure data is facing the right way
      if ~(size(cdata)==size(xdata))
          cdata=cdata';
      end
      
      if strcmp(obj.mode,'Polygon')
          if size(obj.polygon_list,1)<3
              warndlg('You must have a polygon with at least 3 points','Invalid expression');
              return;
          end
          inds = inpolygon(xdata,ydata,obj.polygon_list([1:end 1],1),obj.polygon_list([1:end 1],2));
          cdata=cdata(inds);
      else
          cdata=reshape(cdata,[],1);
      end
      %sum(inds(:))/prod(size(inds))
      figure;
      [f,b] = hist(cdata,50);
      bar(b,f,1);
      title(t,'Interpreter','none')
      Num = length(cdata);
      NNNum = sum(~isnan(cdata));
      Mean = nan_mean(reshape(cdata,[],1));
      [~,ind] = max(f);
      Mode = b(ind);
      Median = nan_median(reshape(cdata,[],1));
      SDev = nan_std(reshape(cdata,[],1));
      
      h = text(0,0,sprintf('N = %i\nNvalid = %i\nMean = %0.4g\nMode = %0.4g\nMedian = %0.4g\nSDev = %0.4g',Num,NNNum,Mean,Mode,Median,SDev));
      set(h,'Units','normalized','Position',[.98 .98],'HorizontalAlignment','right','VerticalAlignment','top');
    end
    
    function assign_save_polygon_var(obj)
      flds = obj.datainfo_fields;
      if length(flds)==0
        obj.update_datainfo;
        flds = obj.datainfo_fields;
      end
      
      answer = inputdlg('Var name in base workspace [WILL OVERWRITE]:','Specify variable to save to.',1,{obj.workspace_save_var},'on');
      
      if isempty(answer)
        return;
      end
   
      obj.workspace_save_var = answer{1};
      assignin('base',obj.workspace_save_var,cell2struct(cell(0,length(flds)),flds,2));
      obj.save_polygon_data_to_var;
    end

    function save_polygon_data_to_var(obj,ax)
      if size(obj.polygon_list,1)<3
        warndlg('You must have a polygon with at least 3 points','Invalid expression');
        return;
      end

      if isempty(obj.workspace_save_var)
        warndlg('You must select a workspace variable first','Invalid expression');
        return;
      end
      
      try
        flds = evalin('base',sprintf('fieldnames(%s)',obj.workspace_save_var));
      catch ME
        warndlg('Problem with base workspace variable.  Try assigning again.','Invalid expression');
        return;
      end
      
      if ~isequal(reshape(sort(flds),[],1),reshape(sort(obj.datainfo_fields),[],1))
        warndlg('Problem with base workspace variable (fields don''t match current data info fields).  Try assigning again.','Invalid expression');
        return;
      end
      
      if nargin<2 || isempty(ax)
        ax = gca;
      end
      hs = findobj(ax,'Type','surface');
      xdata = get(hs,'XData');
      ydata = get(hs,'YData');
      
      inds = inpolygon(xdata,ydata,obj.polygon_list([1:end 1],1),obj.polygon_list([1:end 1],2));
      inds = inds(1:end-1,1:end-1);
      
      ds = obj.get_current_dataset;

      for ll = 1:length(flds)
        s.(flds{ll}) = ds.moments.(flds{ll})(inds);
      end
      
      data = evalin('base',obj.workspace_save_var);
      if isempty(data)
        data = s;
      else
        data = struct_cat(cat(1,data,s),'cat_mode','any','dim',1);
      end
      assignin('base',obj.workspace_save_var,data);
      
    end
    
    
    function redraw_polygon(obj)
      set(obj.axes_handles_list,'NextPlot','add');
      for h = obj.axes_handles_list
        plot(h,obj.polygon_list(:,1),obj.polygon_list(:,2),'b.-','Tag','POLYGON','HitTest','off');
      end
      obj.plot_window_polygon_draw_connector;
      obj.plot_window_setup_axes
    end
    
    
    function plot_window_polygon_reset(obj)
      h = obj.axes_handles_list;
      polys = findobj(h,'Tag','POLYGON');
      delete(polys);
      obj.polygon_list = [];
      
    end
    
    function plot_window_polygon_deletelast(obj)
      if ~isempty(obj.polygon_list)
        h = findobj(obj.axes_handles_list,'Tag','POLYGON','UserData',size(obj.polygon_list,1));
        delete(h);
        obj.polygon_list = obj.polygon_list(1:end-1,:);
      end
      obj.plot_window_polygon_draw_connector;
    end
    
    function plot_window_polygon_draw_connector(obj)
      h = findobj(obj.axes_handles_list,'Tag','POLYGON','UserData',inf);
      delete(h);
      if size(obj.polygon_list,1)>2
        for h = obj.axes_handles_list
          plot(h,obj.polygon_list([end 1],1),obj.polygon_list([end 1],2),'k--','Tag','POLYGON','HitTest','off','UserData',inf);
        end
      end
    end
    
    function polygon_mode_bdf(obj,ob,y)
      modifier = get(obj.fig,'SelectionType');
      switch modifier
        case 'alt'
          obj.plot_window_hist_from_polygon(ob);
        case 'extend'
          obj.plot_window_polygon_deletelast;
        otherwise      
          x = get(ob,'CurrentPoint');
          cp = x(1,1:2);
          if isempty(obj.polygon_list)
            obj.polygon_list = cp;
            for h = obj.axes_handles_list
              plot(h,cp(1),cp(2),'b.','Tag','POLYGON','HitTest','off','UserData',1);
            end
          else
            obj.polygon_list(end+1,:) = cp;
            for h = obj.axes_handles_list
              plot(h,obj.polygon_list(end-1:end,1),obj.polygon_list(end-1:end,2),'b.-','Tag','POLYGON','HitTest','off','UserData',size(obj.polygon_list,1));
            end
            obj.plot_window_polygon_draw_connector;
          end
      end
      
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% make scatter plot from two variables
    
   function plot_scatter_vars(obj)
      var1=pick_vars(obj,'Variable 1');      
      var2=pick_vars(obj,'Variable 2');
      
      if isempty(var1) | isempty(var2)
          disp('No variables chosen.')
          return;
      end
      
      ds = obj.get_current_dataset;
      ax = gca;
      
      hs = findobj(ax,'Type','surface');
      xdata = get(hs,'XData');
      ydata = get(hs,'YData');

      cdata1 = ds.moments.(var1{:});
      cdata2 = ds.moments.(var2{:});
      
      % duplicate last row and column to match size of xdata and ydata
      % (this is necessary because of the way surfmat is set up
      cdata1=cat(1,cdata1,cdata1(end,:));
      cdata1=cat(2,cdata1,cdata1(:,end));
      cdata2=cat(1,cdata2,cdata2(end,:));
      cdata2=cat(2,cdata2,cdata2(:,end));
      
      % make sure data is facing the right way
      if ~(size(cdata1)==size(xdata))
          cdata1=cdata1';
          cdata2=cdata2';
      end
      
      if strcmp(obj.mode,'Polygon')
          if size(obj.polygon_list,1)<3
              warndlg('You must have a polygon with at least 3 points','Invalid expression');
              return;
          end
          inds = inpolygon(xdata,ydata,obj.polygon_list([1:end 1],1),obj.polygon_list([1:end 1],2));
          cdata1=cdata1(inds);
          cdata2=cdata2(inds);
      else
          cdata1=reshape(cdata1,[],1);
          cdata2=reshape(cdata2,[],1);
      end

       figure;
       plot(cdata1,cdata2,'+');
       title([var1{:} ' vs ' var2{:}],'Interpreter','none');
       try
          xlabel([ds.moments_info.(var1{:}).atts.long_name.data ' (' ds.moments_info.(var1{:}).atts.units.data ')'],...
              'Interpreter','none');
          ylabel([ds.moments_info.(var2{:}).atts.long_name.data ' (' ds.moments_info.(var2{:}).atts.units.data ')'],...
              'Interpreter','none');
       end
   end
    
   function var_out=pick_vars(obj,title_text)
   ds = obj.get_current_dataset;
      moments = fieldnames(ds.moments);
      di_flds = obj.datainfo_fields;
      di_flds = cellfun(@(x) find(strcmp(x,moments)),di_flds);
      
      [selection,ok] = listdlg('ListString',moments,'SelectionMode','single','InitialValue',di_flds,'Name',title_text);
      
      if ~ok 
        var_out=[];
      else      
          var_out = moments(selection);
      end
   end
    
    %% datacursor_mode
    
    
    function output_txt = default_datacursor_text(o,obj,event_obj)
    % Display the position of the data cursor
    % obj          Currently not used (empty)
    % event_obj    Handle to event object
    % output_txt   Data cursor text string (string or cell array of strings).
      plot_obj = get(event_obj,'Target');
      ok = strcmp(get(plot_obj,'Type'),'axes') || plot_obj==0;
      h = plot_obj;
      while ~ok
        h = get(h,'Parent');
        ok = strcmp(get(h,'Type'),'axes') || h==0;
      end
      try
        plot_ind = find(o.axes_handles_list==h);
        if length(plot_ind)==1
          plot_info = o.params.available_plots(o.plots(plot_ind).plot_type);
          if ~isempty(plot_info.xy2ind)
            pos = get(event_obj,'Position');
            ind = plot_info.xy2ind(plot_obj,pos,plot_info.options);

            output_txt = {sprintf('X: %0.2f',pos(1)),
                          sprintf('Y: %0.2f',pos(2))};

            ds = o.get_current_dataset;
            current_fld = o.plots(plot_ind).moment_field;
            flds = o.datainfo_fields;
            f_ind = find(strcmp(current_fld,flds));
            if length(f_ind)==0
              flds = cat(1,{current_fld},flds);
            else
              flds = flds([f_ind 1:(f_ind-1) (f_ind+1):end]);
            end
            for ll = 1:length(flds)
              if isfield(ds.moments,flds{ll})
                output_txt{end+1} = sprintf('%s: %0.2g',flds{ll},ds.moments.(flds{ll})(ind(1),ind(2)));
              else
                output_txt{end+1} = sprintf('%s: ---',flds{ll});
              end
            end
          end
        end
      catch
        output_txt = {lasterr};
      end
    end
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% fetch_by_filename_sweep
    function fetch_by_filename_sweep(obj,files,flds,varargin)
    % Utility function for retrieving CFRadial sweeps into the databuffer
    % Currently just a pass through to the emerald_databuffer routine
      emerald_databuffer.fetch_by_filename_sweep(files,flds,varargin{:});
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% fetch_all_from_files
    function fetch_all_from_files(obj)
    % GUI routine to fetch all the fields and sweeps from a single file
      [files,path] = uigetfile(fullfile(obj.params.cfradial_base_datadir,'*.nc'),'Select File(s)', 'MultiSelect', obj.params.data_load.MultiSelect);
      if isequal(files,0)
        return;
      end
      files = cellify(files);
      files = icellfun(files,@(x) cat(2,path,x));
      if length(files)==0
        return
      end
      
      %Check if databuffer is currently empty
      buffer_empty=emerald_databuffer.databuffer_length==0;
      
      h = obj.msgbox(sprintf('\nPlease wait\nLoading....'));
      obj.fetch_by_filename_sweep(files,'all_fields','sweep_index',inf,'default_plot',obj.params.default_plot);
      close(h);
      drawnow;
      
      %sort the data buffer by input file name
      orig_dataset=obj.current_dataset;
      obj.current_dataset=emerald_databuffer.sort_databuffer(obj.current_dataset);
      
      if obj.plotted_dataset==orig_dataset
          obj.plotted_dataset=obj.current_dataset;
      else
          obj.plotted_dataset=inf;
      end
      
      %update plot title
      h = obj.plot_window_title;
      s = emerald_databuffer.databuffer_inventory_string('dataset',obj.current_dataset,'mode',2);
      set(h,'string',sprintf('(%i) %s',obj.current_dataset,s));
      
      %check if toolbar push buttons need to be updated
      check_arrows(obj);
      
      if isempty(obj.current_dataset)
        obj.current_dataset = 1;
      end
      
      %If databuffer is empty plot the first file
      if buffer_empty
          obj.plot_default_plots;
      end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% fetch_by_selection
    function fetch_by_selection(obj)
    %GUI routine to fetch particular files, sweeps, and fields.
      [files,path] = uigetfile(fullfile(obj.params.cfradial_base_datadir,'*.nc'),'Select File(s)', 'MultiSelect', obj.params.data_load.MultiSelect);
      if isequal(files,0)
        return;
      end
      files = cellify(files);
      files = icellfun(files,@(x) cat(2,path,x));
      if length(files)==0
        return
      end
      
      [nc_info,~,meta_data_fields,moment_fields] = emerald_dataset.get_cfradial_inventory(files{1},'vars',emerald_databuffer.dataset_index_fields);
      
      for ll = 1:length(nc_info)
        options{ll} = sprintf('% 2i: %0.2f deg',nc_info(ll).meta_data.sweep_number,nc_info(ll).meta_data.fixed_angle);
        sweep_numbers(ll) = nc_info(ll).meta_data.sweep_number;
      end
      
      [selection,ok] = listdlg('ListString',options,'SelectionMode','multiple','InitialValue',1,'Name','Pick fixed angle(s)');
      
      if ~ok || length(selection)==0
        return
      end
      
      sweep_numbers = sweep_numbers(selection);
      
      [selection,ok] = listdlg('ListString',moment_fields,'SelectionMode','multiple','InitialValue',1,'Name','Pick fixed angle(s)');
      
      if ~ok || length(selection)==0
        return
      end
      
      %Check if databuffer is currently empty
      buffer_empty=emerald_databuffer.databuffer_length==0;
      
      h = obj.msgbox(sprintf('\nPlease wait\nLoading....'));
      obj.fetch_by_filename_sweep(files,moment_fields(selection),'sweep_number',sweep_numbers,'default_plot',obj.params.default_plot);
      close(h);
      drawnow;
      
      %sort the data buffer by input file name
      obj.current_dataset=emerald_databuffer.sort_databuffer(obj.current_dataset);
      
      %update plot title
      h = obj.plot_window_title;
      s = emerald_databuffer.databuffer_inventory_string('dataset',obj.current_dataset,'mode',2);
      set(h,'string',sprintf('(%i) %s',obj.current_dataset,s));
      
      %check if toolbar push buttons need to be updated
      check_arrows(obj);
      
      if isempty(obj.current_dataset)
        obj.current_dataset = 1;
      end
      %If databuffer is empty plot the first file
      if buffer_empty
          obj.plot_default_plots;
      end
    end
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% clear_databuffer
    function clear_databuffer(obj,varargin)
    % clears the databuffer
      emerald_databuffer.clear_databuffer;
      obj.current_dataset = [];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% delete_dataset
    function delete_dataset(obj,varargin)
      if emerald_databuffer.databuffer_length==0
        obj.params.error_function('The Databuffer is empty.');
        return
      end
      
      s = emerald_databuffer.databuffer_inventory_string;
      s = regexp(s,sprintf('\n'),'split');
      if isempty(obj.current_dataset)
        iv = 2;
      else
        iv = obj.current_dataset+1;
      end
      old_def_font = get(0,'DefaultUicontrolFontName');
      set(0,'DefaultUicontrolFontName','fixedwidth');
      [selection,ok] = listdlg('ListString',s,'SelectionMode','multiple','InitialValue',iv,'Name','Pick Dataset(s) to Delete from Databuffer','listsize',[ 600 400]);
      set(0,'DefaultUicontrolFontName',old_def_font);
      
      selection = setdiff(selection,1)-1;
      
      if ok && length(selection) > 0
        emerald_databuffer.delete_dataset(selection);
      end
      
      obj.current_dataset = min(obj.current_dataset,emerald_databuffer.databuffer_length);

      obj.render_plots;

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% show_databuffer_inventory
    function show_databuffer_inventory(obj,varargin)
    % GUI routine to show the data buffer inventory
      figure('ToolBar','none','MenuBar','none','Units','points','Position',[ 207.2000  296.8000  656.0000  336.0000]);
      s = emerald_databuffer.databuffer_inventory_string;
      s = regexp(s,sprintf('\n'),'split');
      uicontrol('Style','edit','Enable','inactive','Units','normalized','Position',[0 0 1 1],'String',s,'Tag',obj.plot_window_tag,'Max',1000,'HorizontalAlignment','left','FontName','fixedwidth');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% select_current_dataset
    function select_current_dataset(obj,varargin)
      if length(varargin)>0
        ok = 1;
        selection = varargin{1}+1;
      else
        
        % GUI routine to select the current dataset
        if emerald_databuffer.databuffer_length==0
          obj.params.error_function('The Databuffer is empty.  Please select some datasets.');
          return
        end
        
        s = emerald_databuffer.databuffer_inventory_string;
        s = regexp(s,sprintf('\n'),'split');
        if isempty(obj.current_dataset)
          iv = 2;
        else
          iv = obj.current_dataset+1;
        end
        old_def_font = get(0,'DefaultUicontrolFontName');
        set(0,'DefaultUicontrolFontName','fixedwidth');
        [selection,ok] = listdlg('ListString',s,'SelectionMode','single','InitialValue',iv,'Name','Pick Dataset to Show','listsize',[ 600 400]);
        set(0,'DefaultUicontrolFontName',old_def_font);
      end
      
      if ok && selection > 1
        obj.current_dataset = selection-1;
      end
      obj.render_plots;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% get_current_dataset
    function dataset = get_current_dataset(obj)
    % Return the current dataset
      if isempty(obj.current_dataset)
        obj.params.error_function('No dataset is selected');
        return
      end
      dataset = emerald_databuffer.get_dataset(obj.current_dataset);
    end
    

    function print_diagnostic_info(obj)
      s = warning('OFF','MATLAB:structOnObject');
      e = struct(obj);
      warning(s);

      fprintf('\n\nEmerald Version: %s\n',emerald_utils.get_version);
      ver
      fprintf('%s',repr(rmfield(e,{'links','AutoListeners__'}),'prefix','emerald_object','max_array_size',100));
      f = get(obj.fig);
      fprintf('%s',repr(f,'prefix','emerald_figure'));
      d = obj.get_current_dataset;
      fprintf('%s',repr(d.meta_data,'prefix','current_dataset_meta','max_array_size',100));
      fprintf('%s',repr(d.moments,'prefix','current_dataset_moments','max_array_size',100));
    end
    
    %% prev_in_buffer
    function prev_in_buffer(obj)
        obj.current_dataset=obj.current_dataset-1;
        obj.render_plots;
    end
    
    %% next_in_buffer
    function next_in_buffer(obj)
        obj.current_dataset=obj.current_dataset+1;
        obj.render_plots;
    end
    %% plot_default_plots
    function plot_default_plots(obj)
        % Creates default plots when first selecting a data set
        [res,msg] = obj.check_plot_window;
        if res
            obj.params.error_function(sprintf('ERROR: %s',msg));
            return
       end
       
       ds = obj.get_current_dataset;
       
       moments = fieldnames(ds.moments);
       avail_plots = obj.params.available_plots;
       plot_default = find(strcmp(obj.params.default_plot,{avail_plots.name}));
       
       
       plots = obj.default_plot_state_struct;
       old_plots = obj.plots;
       ah = obj.axes_handles_list;
       
       if size(obj.params.plot_vars,2)>size(obj.params.plot_vars,1)
           obj.params.plot_vars=obj.params.plot_vars';
       end
       
       % run through the controls, pulling out the appropriate plot for each and setting the plots
       for ll = 1:obj.params.plot_panels
           if size(obj.params.plot_vars,1)>=ll && max(ismember(moments,obj.params.plot_vars{ll}))
               plots(ll).moment_field=obj.params.plot_vars{ll};
           elseif ll>length(moments)
               plots(ll).moment_field = moments{length(moments)};
           else
               plots(ll).moment_field = moments{ll};
           end
           plots(ll).plot_type = plot_default(1);
           plots(ll).caxis_params = emerald_utils.find_caxis_params(plots(ll).moment_field,obj.params.caxis_limits,obj.params.color_map);
           if length(old_plots)>=ll && old_plots(ll).plot_type~=plots(ll).plot_type
               cla(ah(ll));
           end
       end
       
       % save it and no render the plots
       obj.plots = plots;
       obj.render_plots;
    
    end
    
     %% check_arrows
     function check_arrows(obj)
         % check if figure toolbar push buttens need to be updated
         s = emerald_databuffer.databuffer_inventory_string;
         s = regexp(s,sprintf('\n'),'split');
         hPrev = findall(obj.fig, 'tooltipstring', 'Previous file');
         hNext = findall(obj.fig, 'tooltipstring', 'Next file');
         set(hPrev,'Enable','on')
         set(hNext,'Enable','on')
         % first file
         if obj.current_dataset==1
             set(hPrev,'Enable','off')
         end
         % last file
         if obj.current_dataset==length(s)-2
             set(hNext,'Enable','off')
         end
     end
    %%%%%%%%
  end
  
  methods (Access = private)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% regenerate_params
    function regenerate_params(obj,varargin)
    %fprintf('regenerating\n')
      
      
    %obj.params = obj.default_params;
    %  obj.params = paramparses(obj.params,obj.user_config_params,{},'warn_skip');
    %  obj.params = paramparses(obj.params,obj.override_params,{},'warn_skip');

      obj.params = obj.default_params;
      obj.params = copystruct(obj.user_config_params,obj.params,'copy_if_noexist',0,'recurse_structs',1','warn_if_noexist',1);
      obj.params = copystruct(obj.override_params,obj.params,'copy_if_noexist',0,'recurse_structs',1,'warn_if_noexist',1);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% load_config
    function params = load_config(obj,filename)
      if isempty(filename)
        params = struct;
        return;
      end
      
      try
        params = config2struct(filename);
      catch ME
        fprintf('Unable to load ''%s''.  The following is the actual reported error:\n',filename);
        rethrow(ME);
      end
    end
    
    %%% tf2onoff
    function str = tf2onoff(obj,tf)
      if tf
        str = 'on';
      else
        str = 'off';
      end
    end
  
  
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OBSOLETE
  
  
    function plot_window_datacursor_mode(obj)
      if ~isequal(obj.mode,'DataCursor')
      
        h = obj.axes_handles_list;
        set(h,'NextPlot','add');
        ch = setdiff(findobj(h),h);
        
        set(ch,'HitTest','off');
        
        set(h,'ButtonDownFcn',@(x,y) obj.datacursor_mode_bdf(x,y));
        obj.mode = 'DataCursor';
        set(findobj(1,'Type','uimenu','Label','Datacursor Mode'),'Checked','on');
      else
        obj.plot_window_datacursor_mode_off;
        obj.mode = NaN;
        set(findobj(1,'Type','uimenu','Label','Datacursor Mode'),'Checked','off')
      end
    end
    
    function plot_window_datacursor_mode_off(obj)
      h = obj.axes_handles_list;
      ch = setdiff(findobj(h),h);
      
      set(ch,'HitTest','on');
      
      set(h,'ButtonDownFcn','');
      
    end
    
% $$$     function plot_window_hist_from_polygon(obj,ax)
% $$$       if nargin<2 || isempty(ax)
% $$$         ax = gca;
% $$$       end
% $$$       hs = findobj(ax,'type','surface');
% $$$       xdata = get(hs,'xdata');
% $$$       ydata = get(hs,'ydata');
% $$$       cdata = get(hs,'cdata');
% $$$       
% $$$       t = get_axes_text(ax);
% $$$       
% $$$       inds = inpolygon(xdata,ydata,obj.polygon_list([1:end 1],1),obj.polygon_list([1:end 1],2));
% $$$       %sum(inds(:))/prod(size(inds))
% $$$       figure; hist(cdata(inds),50);
% $$$       title(t,'interpreter','none')
% $$$       text(0,0,sprintf('N = %i',sum(inds(:))),'units','normalized','position',[.98 .98],'HorizontalAlignment','right','verticalalignment','top');
% $$$     end

    function plot_window_datacursor_reset(obj)
      h = obj.axes_handles_list;
      polys = findobj(h,'Tag','DATACURSOR');
      delete(polys);
      obj.datacursor_list = [];
      
    end
    
    function datacursor_mode_bdf(obj,x,y)
      x = get(x,'CurrentPoint');
      cp = x(1,1:2);
      if isempty(obj.polygon_list)
        obj.polygon_list = cp;
        for h = obj.axes_handles_list
          plot(h,cp(1),cp(2),'b.','Tag','POLYGON','HitTest','off');
        end
      else
        obj.polygon_list(end+1,:) = cp;
        for h = obj.axes_handles_list
          plot(h,obj.polygon_list(end-1:end,1),obj.polygon_list(end-1:end,2),'b.-','Tag','POLYGON','HitTest','off');
        end
      end
      
      
    end
    
    function output_txt = default_datacursor_text_old(o,obj,event_obj)
    % Display the position of the data cursor
    % obj          Currently not used (empty)
    % event_obj    Handle to event object
    % output_txt   Data cursor text string (string or cell array of strings).
      plot_obj = get(event_obj,'Target');
      ok = strcmp(get(plot_obj,'Type'),'axes') || plot_obj==0;
      h = plot_obj;
      while ~ok
        h = get(h,'Parent');
        ok = strcmp(get(h,'Type'),'axes') || h==0;
      end
      try
        plot_ind = find(o.axes_handles_list==h);
        if length(plot_ind)==1
          pos = get(event_obj,'Position');
          xdata = get(plot_obj,'XData');
          ydata = get(plot_obj,'YData');
          [~,ind] = min((pos(1)-xdata(:)).^2+(pos(2)-ydata(:)).^2);
          
          %data = o.get_current_dataset;
        
          %[~,ind] = min((pos(1)-data.meta_data.x(:)).^2+(pos(2)-data.meta_data.y(:)).^2);
        
          inds = find(o.get_same_plot_types(o.plots(plot_ind).plot_type));
          ax = o.axes_handles_list;
          
          output_txt = {sprintf('X: %0.2f',xdata(ind)),
                        sprintf('Y: %0.2f',ydata(ind))};
          for ll = 1:length(inds)
            pos_h = findobj(ax(inds(ll)),'Type',get(plot_obj,'Type'));
            xdatas = cellify(get(pos_h,'XData'));
            pos_h = pos_h(find(cellfun(@(x) isequal(size(x),size(xdata)),xdatas)));
            if length(pos_h)==1
              cdata = get(pos_h,'CData');
              output_txt{end+1} = sprintf('%s: %0.2g',o.plots(inds(ll)).moment_field,cdata(ind));
            end
          end
        end
      catch
        output_txt = {lasterr};
      end
    end
  
  
  
  
  
  
  
  
  
  end
  

end
