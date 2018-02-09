%User config file for S-POL data

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

% Default base data directory
cfradial_base_datadir = '.';

% default plot to use.  Must match the name of one of the available plots.
%default_plot = 'PPI (XY)';
%default_plot = 'PPI (XY,Elev Corr)';
default_plot = 'PPI (lonlat)';
%default_plot = 'RHI';

% Color scale limits. Three possibilities:
% 1. Empty []: Matlab will determine the axis limits
% 2. Vector with minimum and maximum value, e.g. [0 10]
% 3. Vector with spacing of interval. Can be regular or irregular. Needs to
% be length(colormap)+1, e.g. [-inf 1 2 3 inf]
% Different possibilities can be chosen for different variables.
caxis_limits.dbz=[-inf -20 -10 -5 (0:3:27) 31 (35:5:70) 80 inf];
caxis_limits.vel=[-inf -23 (-18:3:-3) -1 1 (3:3:18) 23 inf];
caxis_limits.width=[-inf (0.5:0.5:3) (4:1:8) 10 12.5 15 20 25 inf];
caxis_limits.zdr=[-inf -2 -1 (-0.8:0.2:1) 1.5 2 2.5 (3:1:6) 8 10 15 20 50 inf];
caxis_limits.rhohv=[-inf 0.7 0.8 0.85 (0.9:0.01:0.97) 0.975 0.98 0.985 0.99 0.995 inf];
caxis_limits.phidp=[-inf (-170:10:170) inf];

% When selecting 'file by selection', we restrict to only reading 1 file at a time.
% When selecting from multiple files at same time, all files need same variables.
data_load.MultiSelect = 'on'; % can be 'on' or 'off'

