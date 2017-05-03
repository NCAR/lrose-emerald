function netcdf_write(ncin, filename,varargin)
% usage netcdf_write(ncin,filename,'param',value,...)
%
%   ncin is a struct of the same form generated using either format 1 or 2
%    from NetcdfRead (type 'help NetcdfRead' for more info).
%
%   filename - the NetCDF variable name
%   'param' can be any of the following (shown with defaults)
%
%     varstoput = {}; - if empty, put all vars, otherwise a cellarray
%                       of variables to put. Can use regular expressions (see regexp
%                       for valid expressions)
%     putvaratts = 0; - 1 to put the variable attributes
%     putvartype = 0; - 1 to put the variable type from netcdf
%     putvardim = 1; - 1 to put the variable dimensions
%     putmode = 1; - 1 - create and save data for all vars listed in varstoput
%                    2 - create all vars but save data for only those listed in
%                        varstoput
%     putfileatts = 0; - 1 to put file attributes
%     putfiledim = 0; - 1 to put file dimensions
%     putall = 0; 1 turns on all the puts,  0 otherwise
%     nans2fills = 1; - 1 to convert Fill values to NaNs;
%     packvars = 0; - 1 to scale and add offset for all vars
%     clobber = 0; 1 means to clobber existing files, i.e. destroy what was
%                  there previously.
%     unsigned_ints = 0; - set to 1 if netcdf bytes should be treated as unsigned.
%                 Normally, netcdf bytes are treated as signed as dictated by the
%                 netcdf documentation, but sometimes makers of netcdf files do not
%                 follow this.
%     netcdfformat = 'CLASSIC'; Can be 'CLASSIC','64BIT','NETCDF4','NETCDF4_CLASSIC'.
%                'CLASSIC' - traditional netcdf3 binary format
%                '64BIT' = netcdf3 format with support for larger files
%                'NETCDF4' = new netcdf4 format
%                'NETCDF4_CLASSIC' - a new netcdf4 format file (not readable using netcdf3 
%                      libraries) but the restrictions on variable types and lack of group
%                      support is that same as netcdf3.  Thus, a "NETCDF4_CLASSIC" file could,
%                      in theory, be opened using a netcdf4 library and saved as 'CLASSIC' 
%                      with no changes.
%     verbose = 0; % set to 1 to print diagnostic information.
%     check_vars = 0; % set to 1 if you are getting a problem writing and you are not able to 
%                determine which variable is the problem.  You should also turn on verbose mode.
%                The reason for this is that sometimes there are errors that are not
%                figured out by the netcdf library until the file is taken out of def mode
%                and put into data mode, at which point it is not obvious which variable
%                caused the problem.  An example is a datatype mismatch between a variable
%                and it's fillvalue.  Setting this to 1 will cause the file to be switched
%                to data mode and back to def mode after every variable is created.  The
%                problem with this is that in some cases this causes a different problem.
%                ERROR: 'Attempt to define var properties, like deflate, after enddef. (NC_ELATEDEF)'
%                It is not clear why this occurs.
%
%
%  NOTE: This function is intended to be used in 2 ways. 1) modify data
%    in an existing file or 2) create a new (or clobber an old) netcdf
%    file.  At this time the only things that can be *modified* on an
%    EXISTING netcdf file is the values of *data* and the length of the
%    record dimension.  You can always ADD anything to an existing netcdf 
%    (variables, dimensions, attributes).  If you need to modify something
%    not allowed, the easiest and safest thing to do is to just create a new netcdf 
%    file since on a new netcdf, everything is new so you can create everything.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 



%     force = 0; 1 means to force modifications that are otherwise not performed.
%                if force = 1, and the file existed and if clobber = 0
%                then values for all attributes are changed or created in the file according to the 
%                ncin structure.  If force = 0, and the file existed and if clobber = 0
%                then only new attributes are created.  If the file did not exist or if 
%                clobber is set to 1, then the value of force is moot.  The values of
%                the variables (i.e. the data) can be modified whether force is 0 or 1.


x = NetcdfCommon(varargin{:});
x.open_file(filename,'write');

switch x.params.format
  case 1
    ncin = x.old_to_new(ncin);
  case 0
    error('Cannot create a file based of off the simple format.  There is not enough information.');
end

x.store(ncin);
x.cleanup;
