%%% DO NOT MODIFY THIS FILE.  Instead use your own config file
% and set the user_config_file property to that filename.

% $Revision: 1.4 $

% Default base data directory

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

cfradial_base_datadir = '/scr/rain2/rsfdata/projects/pecan/cfradial/kddc/moments/20150525/';
disp('User file loaded.');
% 
% % plotting
% plot_panels = 4; % currently, 4 is the upper limit
% 
% % a list of the available plots.
% available_plots = emerald_utils.plot_struct('name','NONE');
% available_plots(end+1) = emerald_utils.plot_struct('name','PPI (XY)','call',@ppi_plot.call,'options',{'mode','polar'},'xy2ind',@ppi_plot.xy2ind);
% available_plots(end+1) = emerald_utils.plot_struct('name','PPI (XY,Elev Corr)','call',@ppi_plot.call,'options',{'mode','polar_elcorr'},'xy2ind',@ppi_plot.xy2ind);
% available_plots(end+1) = emerald_utils.plot_struct('name','PPI (lonlat)','call',@ppi_plot.call,'options',{'mode','lonlat'},'xy2ind',@ppi_plot.xy2ind);
% available_plots(end+1) = emerald_utils.plot_struct('name','RHI','call',@rhi_plot.call,'xy2ind',@rhi_plot.xy2ind);
% available_plots(end+1) = emerald_utils.plot_struct('name','BSCAN','call',@bscan_plot.call,'xy2ind',@bscan_plot.xy2ind);
% 
% % default plot to use.  Must match the name of one of the available plots.
% default_plot = 'PPI (XY)';
% 
% % If 1, then when the user switches datasets, the plots will maintain the same zoom.  Otherwise, it will
% % go back to the default zoom from the plotting routine
% zoom_lock = 1;
% 
% % If 1, then when the user switches datasets, the plots will maintain the same zoom.  Otherwise, it will
% % go back to the default zoom from the plotting routine
% caxis_lock = 1;
% 
% % Main Plot Window Size
% plot_window.position = [   56 66 1007 814]; % pixels
% 
% % Spacing for the Main Plot Window.
% plot_window.left_margin = 40; % points;
% plot_window.right_margin = 16; % points;
% plot_window.top_margin = 40; % points;
% plot_window.bottom_margin = 32; % points;
% plot_window.vertical_spacing = 40; % points
% plot_window.horizontal_spacing = 40; % points
% plot_window.renderer = 'zbuffer'; % can be 'zbuffer' or 'OpenGL'.  Override at your own risk.
% 
% % Size of the plot window title
% plot_window_title.height = 16; % points
% 
% % Which error function to use.  Can be @error or @errordlg
% error_function = @error;
% 
% % When selecting 'file by selection', we restrict to only reading 1 file at a time.
% % When selecting from multiple files at same time, all files need same variables.
% data_load.MultiSelect = 'off'; % can be 'on' or 'off'
% 
