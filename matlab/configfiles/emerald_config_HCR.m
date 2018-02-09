%User config file for HCR data

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

% Default base data directory
cfradial_base_datadir = '.';

% default variables to plot when initializing. Must be cell with strings matching variable names
% e.g. When none are chosen, the
% first ones are plottet
plot_vars={'DBZ','VEL','WIDTH','SNR'};

% default plot to use.  Must match the name of one of the available plots.
%default_plot = 'BSCAN (range)';
default_plot = 'BSCAN (altitude)';

% set the x and y limits of plots. If empty, matlab defaults will be used
ax_limits.x=[];
ax_limits.y=[-1 8];

% Color scale limits. Three possibilities:
% 1. Empty []: Matlab will determine the axis limits
% 2. Vector with minimum and maximum value, e.g. [0 10]
% 3. Vector with spacing of interval. Can be regular or irregular. Needs to
% be length(colormap)+1, e.g. [-inf 1 2 3 inf]
% Different possibilities can be chosen for different variables.
caxis_limits.dbz=[-inf (-43:3:23) inf];
caxis_limits.dbm=[-inf (-111:6:-21) inf];
caxis_limits.ldr=[-inf (-45:5:60) inf];
caxis_limits.ncp=[-inf (-0.05:0.05:0.4) (0.5:0.1:1) inf];
caxis_limits.snr=[-inf -10 (-6:3:15) (20:5:70) 80 90 inf];
caxis_limits.vel=[-inf (-7:1:-1) -0.5 0.5 (1:1:7) inf];
caxis_limits.width=[-inf (0.1:0.1:0.6) (0.75:0.25:2.5) 3 4 inf];

% When selecting 'file by selection', we restrict to only reading 1 file at a time.
% When selecting from multiple files at same time, all files need same variables.
data_load.MultiSelect = 'on'; % can be 'on' or 'off'

