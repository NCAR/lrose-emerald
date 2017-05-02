function em = emerald(varargin)
% EMERALD GUI for the display of Radar/Lidar data
%
% usage: em = emerald;
%  or    em = emerald(configfile);
%  or    em = emerald(configfile,'param1',value1,...);
%
% This function creates an EMERALD window.  The user can also specify 
% a user config file to use.  This should be a string containing the 
% name of a config file in the current path.  Config files are just
% matlab '.m' files that set variables.  If the configfile is '', then 
% it is ignored.
%
% Additionally, the user can further modify parameters using the 3rd syntax.  
%
% Parameters available for user configuration are visible in the file
% emerald_default_config.m [DO NOT MODIFY THIS FILE].  
% Generally, the ones that users are most likely to want to modify are:
%
% cfradial_base_datadir = '.'; Default path to the data.  The default is 
%   the current directory.  This is used just to help the user get to 
%   the data more quickly.  It is just used as the starting point for the
%   file selector dialog.
%
% default_plot = 'PPI (XY)'; Name of the default plot to use
%
% It may also be useful to override these parameters after the GUI has
% already started.  This can be done by:
% >> em.override_params.PARAMNAME = NEWVALUE;
% e.g.
% >> em.override_params.cfradial_base_datadir = 'newpath';
% Note that not all parameters will update nicely.  Some may require
% you to apply 'Plots'->'Render Plots' or run >> em.render_plots;
%
% See the help documentation emerald.pdf for more info

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


% $Revision: 1.2 $

em = emerald_api(varargin{:});
em.plot_window_create;
