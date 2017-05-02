EMERALD README

Installation

New

The file is provided as a gzip'ed tar file.  To install, simply unpack
the file in the desired location.  For example, in *NIX:

Step 1) Create the emerald directory

> mkdir emerald; cd emerald

Step 2) Copy the tar file into that directory

Step 3) unpack the archive:

> tar -xvzf emerald-20150326.tgz

This will create a directory under emerald called emerald-20150326.

Step 4) add the path You probably should add the MATLAB path to
EMERALD.  This can be done at the MATLAB command line (this change
only lasts in that Matlab session), in the startup.m file, or
globally.  If the EMERALD directory is not added to the path, then
MATLAB will need to be run from the EMERALD directory.  In MATLAB
command window:

>> addpath /THE/FULL/PATH/TO/emerald/emerald-20150326

This will add the path for the current session only.  To make it more
permanent, either add the above line (without ">>") to the startup.m
file (in *NIX, if that file exists, it is located in ~/matlab), or use
the matlab GUI.  To do the latter, select "File"->"Set Path" from the
menu, click on "Add Folder", then use the dialog box to select the
emerald-20150326 directory.  See the MATLAB documentation for more
information on setting up paths.  Once this is done, the MATLAB
working directory can be anywhere but EMERALD will still be available.

NOTE: It is recommended that you do not mix EMERALD and your other
files together.  In other words, do not put your personal scripts,
data, or configuration files in the EMERALD directory as it will make
upgrading much more difficult.

NOTE: If you set up the path correctly, you will be able to call
EMERALD from any directory.

Upgrades

Assuming that you followed the steps listed above for the installation:

Step 1) Go into the top emerald directory

> cd /THE/FULL/PATH/TO/emerald

Step 2) Copy the tar file into that directory

Step 3) unpack the archive:

> tar -xvzf emerald-20150326.tgz

This will create a directory under emerald called emerald-20150326.

Step 4) modify the path If you modified your path, to include EMERALD
(which you probably should have) then you will want to modify the
MATLAB path to the new version.  If you just add the path during each
session using the addpath command, then simply start using the new
path (emerald-20150326).  If you modified your startup.m to include
the addpath command, then change that command to point to the new
path.  If you went through the GUI, then you add the new path and
remove the old one in the same dialog described above in the Install
New section.

 
Running EMERALD

Launching

To start emerald, launch MATLAB, and run:

>> em = emerald;

NOTE: you should be able to launch EMERALD from any directory if you
set up the path.  It is recommended that personal scripts are not
added into the emerald-20150326 directory since this will complicate
upgrades.  Instead put your personal scripts in a different directory,
launch Matlab and call EMERALD from there.  Optionally, EMERALD can be
launched with various arguments.  See the section on User
Configuration.  The plot window should pop up.
 
See EMERALD.pdf for more help

