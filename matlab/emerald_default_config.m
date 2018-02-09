%%% DO NOT MODIFY THIS FILE.  Instead use your own config file
% and set the user_config_file property to that filename.

% $Revision: 1.5 $

% Default base data directory

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

cfradial_base_datadir = '.';

% plotting
plot_panels = 4; % currently, 4 is the upper limit

% a list of the available plots.
available_plots = emerald_utils.plot_struct('name','NONE');
available_plots(end+1) = emerald_utils.plot_struct('name','PPI (XY)','call',@ppi_plot.call,'options',{'mode','polar'},'xy2ind',@ppi_plot.xy2ind);
available_plots(end+1) = emerald_utils.plot_struct('name','PPI (XY,Elev Corr)','call',@ppi_plot.call,'options',{'mode','polar_elcorr'},'xy2ind',@ppi_plot.xy2ind);
available_plots(end+1) = emerald_utils.plot_struct('name','PPI (lonlat)','call',@ppi_plot.call,'options',{'mode','lonlat'},'xy2ind',@ppi_plot.xy2ind);
available_plots(end+1) = emerald_utils.plot_struct('name','RHI','call',@rhi_plot.call,'xy2ind',@rhi_plot.xy2ind);
available_plots(end+1) = emerald_utils.plot_struct('name','BSCAN (range)','call',@bscan_plot.call,'options',{'mode','range'},'xy2ind',@bscan_plot.xy2ind);
available_plots(end+1) = emerald_utils.plot_struct('name','BSCAN (altitude)','call',@bscan_plot.call,'options',{'mode','altitude'},'xy2ind',@bscan_plot.xy2ind);

% default plot to use.  Must match the name of one of the available plots.
default_plot = 'PPI (XY)';

% set the x and y limits of plots. If empty, matlab defaults will be used
ax_limits.x=[];
ax_limits.y=[];

% If 1, then when the user switches datasets, the plots will maintain the same zoom.  Otherwise, it will
% go back to the default zoom or ax_limits will be used
zoom_lock = 1;

% Vector of 0 or 1 corresponding to the figure panels.
% If 1, then when the user switches datasets, the plots will maintain the same color scale.
% Otherwise, it will go back to the default color scale from the plotting routine.
% caxis_lock = [0,0,0,0];

% Color scale limits. Three possibilities:
% 1. Empty []: Matlab will determine the axis limits
% 2. Vector with minimum and maximum value, e.g. [0 10]
% 3. Vector with spacing of interval. Can be regular or irregular. Needs to
% be length(colormap)+1, e.g. [-inf 1 2 3 inf]
% Different possibilities can be chosen for different variables.
caxis_limits.dbz=[];
caxis_limits.dbm=[];
caxis_limits.ldr=[];
caxis_limits.ncp=[];
caxis_limits.snr=[];
caxis_limits.vel=[];
caxis_limits.width=[];
caxis_limits.zdr=[];
caxis_limits.rhohv=[];
caxis_limits.phidp=[];
caxis_limits.temp=[];
caxis_limits.backscat=[];
caxis_limits.depol=[];
caxis_limits.od=[];
caxis_limits.ext=[];

% Color map. If empty, default matlab color map will be used.
color_map.dbz=dbz_default; % 24 colors
color_map.dbm=dbm_default; % 17 colors
color_map.ldr=ldr_default; % 23 colors
color_map.ncp=ncp_default; % 17 colors
color_map.snr=snr_default; % 23 colors
color_map.vel=vel_default; % 17 colors
color_map.width=width_default; % 17 colors
color_map.zdr=zdr_default; % 25 colors
color_map.rhohv=rhohv_default; % 17 colors
color_map.phidp=phidp_default; % 36 colors
color_map.temp=temp_default; % 28 colors
color_map.backscat=backscat_default; % 22 colors
color_map.depol=depol_default; % 19 colors
color_map.od=od_default; % 61 colors
color_map.ext=ext_default; % 31 colors


% Main Plot Window Size
plot_window.position = [   56 66 1007 814]; % pixels

% Spacing for the Main Plot Window.
plot_window.left_margin = 40; % points;
plot_window.right_margin = 16; % points;
plot_window.top_margin = 40; % points;
plot_window.bottom_margin = 32; % points;
plot_window.vertical_spacing = 40; % points
plot_window.horizontal_spacing = 40; % points
plot_window.renderer = 'zbuffer'; % can be 'zbuffer' or 'OpenGL'.  Override at your own risk.

% Size of the plot window title
plot_window_title.height = 16; % points

% Which error function to use.  Can be @error or @errordlg
error_function = @error;

% When selecting 'file by selection', we restrict to only reading 1 file at a time.
% When selecting from multiple files at same time, all files need same variables.
data_load.MultiSelect = 'off'; % can be 'on' or 'off'

