%User config file for HSRL data

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

% Default base data directory
cfradial_base_datadir = '.';

% default variables to plot when initializing. Must be cell with strings matching variable names
% e.g. When none are chosen, the
% first ones are plottet
plot_vars={'BackScatterCoeff','ParticleDepolRatio','ExtinctionCoeff','OpticalDepth'};

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
caxis_limits.temp=[-inf (200:5:330) inf];
caxis_limits.backscat=[-inf 1e-8 1.7e-8 3e-8 6e-8 1e-7 1.7e-7 3e-7 6e-7 1e-6 1.7e-6 3e-6 6e-6 ...
    1e-5 1.7e-5 3e-5 6e-5 0.0001 0.00017 0.0003 0.0006 0.001 inf];
caxis_limits.depol=[-inf (0.025:0.025:0.45) inf];
caxis_limits.od=[0 6];
caxis_limits.ext=[-inf 2e-7 3e-7 5e-7 7.5e-7 1e-6 2e-6 3e-6 5e-6 7.5e-6 1e-5 2e-5 3e-5 5e-5 7.5e-5 ...
    0.0001 0.0002 0.0003 0.0005 0.00075 0.001 0.002 0.003 0.005 0.0075 0.01 0.02 0.03 0.05 0.075 0.1 inf];

% When selecting 'file by selection', we restrict to only reading 1 file at a time.
% When selecting from multiple files at same time, all files need same variables.
data_load.MultiSelect = 'on'; % can be 'on' or 'off'
