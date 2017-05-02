function data  = NetcdfRead(filename,varargin)
% usage ncout = NetcdfRead(filename,'param',value,...)
%
%   ncout is a Netcdf struct.  Type 'help NetcdfFormat' for more help.
%
%   filename - the NetCDF variable name
%   'param' can be any of the following (shown with defaults)
%     varstoget = {}; - if empty, get all vars, otherwise a cellarray
%                       of variables to get.  Can use regular expressions (see regexp
%                       for valid expressions)
%     getvaratts = 0; - 1 to get the variable attributes
%     getvartype = 0; - 1 to get the variable type from netcdf
%     getvardim = 1; - 1 to get the variable dimensions
%     getmode = 1; - 1 - get only those listed
%                    2 - get those listed but retrieve all names
%     getfileatts = 0; - 1 to get file attributes
%     getfiledim = 0; - 1 to get file dimensions
%     getgroups = 1; - 1 to get file groups (netcdf4)
%     fills2nans = 1; - 1 to convert Fill values to NaNs; Note that char arrays do not
%                       handle nan's (float/double concept) so these are NEVER converted to
%                       NaN's.  They are left AS IS.
%     unpackvars = 0; - 1 to scale and add offset for all vars (note that
%                       if fills2nans == 0, then the fill value will be 'unpacked'
%     getall = 1; if 1 then getvar* and getfile* default to 1
%                 but it leaves rest of options alone
%     unsigned_ints = 0; - set to 1 if netcdf bytes should be treated as unsigned.
%                 Normally, netcdf bytes are treated as signed as dictated by the
%                 netcdf documentation, but sometimes makers of netcdf files do not
%                 follow this.
%     tempdir = ''; The temporary directory to use if the netcdf file is actually gzipped.
%     format = 2; can be 0 - super simple structure containing nothing but the (mangled)
%         netcdf variable names and the data containing them. 1- the old netcdfread output 
%         format (note that the values of the types and atts_type are consistent with the 
%         new library, not the old netcdfread library (so "NC_CHAR" instead of 'char').  
%         2 - the new format.
%     ncload = 0;  There was an old routine called ncload which put the netcdf variables directly
%         into the caller workspace.  If 1, then this will be done.  Note that if the format 
%         is 1 or 2, then the variable structure is saved to the workspace (i.e. var1, var2... are 
%         saved as structures, including .data, .dims, .atts, etc.  If the format is 0, then
%         the variable will be only the data.  Note that this is NOT the recommended way of
%         working, especially when putting NetcdfRead in a script. (See below).
%
%  A typical usage would be 
%  
%  out = NetcdfRead('theFileName.nc');
%  
%  If you want to turn off fills2nans (which converts fill values to
%  NaNs) which is 1 be default, then:
%  
%  out = NetcdfRead('theFileName.nc','fills2nans',0);
%  
%  Or if you want to 'unpack' the variables (use the scale and add_offset
%  variable attributes, then:
%  
%  out = NetcdfRead('theFileName.nc','unpackvars',1);
%  
%  Or if you want to load certain variables, but also unpack them:
%  
%  out = NetcdfRead('theFileName.nc','unpackvars',1,'varstoget',{'latitude','longitude'});
%
%  Additionally, put it in the simple, but less informative (no attributes, dimensions, etc.)
%  then:
%  
%  out = NetcdfRead('theFileName.nc','unpackvars',1,'varstoget',{'latitude','longitude'},'format',0);
%
%  If you want to use the mode where the variables are put directly into matlab (no return structure)
%  then:
%
%  out = NetcdfRead('theFileName.nc','unpackvars',1,'varstoget',{'latitude','longitude'},'format',0,'ncload',1);  
%
%  Couple of notes:  
%     All numeric values (atts/vars) are converted to doubles.
%
%     The netcdf file can be gziped as long as it has the .gz extension.
%
%     FillValues that are character arrays and are longer than 1 character
%     are cut down to be exactly 1 character.  Not sure what netcdf does with
%     longer ones....
%
%     The inherent problem of trying to create a "mirror" of the netcdf
%     file as a structure is that matlab does not have as much flexability
%     with names of objects as netcdf does.  For example '_foo-bar.fu' is
%     a valid netcdf variable name, but violates 3 naming rules in matlab.
%     The solution taken here is to mangle names. leading '_' are removed, 
%     - becomes '__DASH__', etc.  This solution was only partially 
%     implemented and so a netcdf file could be found that breaks the code.  
%     Note that the original_name field is used to store the original netcdf
%     name for everything so no information is lost.
%     
%     This program is not smart about checking for already defined names.
%     If two variables get mangled to the same string, the last one is 
%     saved. e.g. if there were 2 variables, 1 named
%     'foo__DASH__', and the other 'foo-'. Or, more likely '_foo' and 'foo'
%
%     Why NCLOAD is BAD: The reason has to do with the way matlab determines whether
%     something is a variable or a function at runtime.  The short of it is that if
%     there is a function in the matlab path with the same name as a netcdf variable,
%     matlab may think that all references to that variable in your code are 
%     referenceing the function instead.  E.g., if there is a netcdf variable called
%     info.  After the ncload, if you say x = info(1), matlab will think that you
%     mean to call the info *function* with argument 1, rather than wanting the 
%     first element in the info variable.  YOU HAVE BEEN WARNED.
%
%  MIGRATION from old netcdfread
%     To replace netcdfread calls with NetcdfRead calls, you should be able
%     to do:
%       data = netcdfread(filename,'p1',v1,'p2',v2,...)
%     to
%       data = NetcdfRead(filename,'format',1,'p1',v1,'p2',v2,...)
%     A few netcdfread options are silently ignored (backend, old_backend, getorigvarname. 
%     Note that it would be better to modify your code to adopt the new format, but
%     if this is not possible, then this should work.
%
%  See NetcdfResize and NetcdfWrite.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


x = NetcdfCommon(varargin{:});
x.open_file(filename,'read');
data = x.retrieve;
x.cleanup;

if x.params.ncload
  switch x.params.format
    case {1,2}
      vars = fieldnames(data.vars);
      for ll = 1:length(vars)
        assignin('caller',vars{ll},data.vars.(vars{ll}));
      end
      return
    case 0
      data = x.new_to_simple(data);
      vars = fieldnames(data)
      for ll = 1:length(vars)
        assignin('caller',vars{ll},data.(vars{ll}));
      end
      return
  end
end


switch x.params.format
  case 1
    data = x.new_to_old(data);
  case 0 
    data = x.new_to_simple(data);
end

      

