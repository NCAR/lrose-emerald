classdef NetcdfCommon < handle


% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  properties
    params
    filename
    cleanup_files = {};
    nc
    
  end
  
  properties (GetAccess=public, SetAccess=private)
    nc_type_names
    nc_type_values
    nc_types
    numeric_types
    char_types
    converter

    %mat_type_names = {'
  end

    
  methods (Access = protected)
    
    function z = setdifford(obj,x,y);
      [z,I] = setdiff(x,y);
      z = x(sort(I));
    end
      
    %%% format2create
    function res = format2create(obj,fmt,extra)
      if ischar(extra)
        extra = netcdf.getConstant(extra);
      end
      switch fmt
        case 'CLASSIC'
          res = extra;
        case '64BIT'
          res = bitor(extra,netcdf.getConstant('64BIT_OFFSET'));
        case 'NETCDF4'
          res = bitor(extra,netcdf.getConstant('NETCDF4'));
        case 'NETCDF4_CLASSIC'
          res = bitor(extra,netcdf.getConstant('NETCDF4'),netcdf.getConstant('CLASSICAL_MODEL'));
        otherwise
          error('bad netcdfformat');
      end
    end
        
    %%%% translate_name
    function outname = translate_name(obj,inname)

      if iscell(inname)
        outname = {};
        for l = 1:length(inname)
          outname{l} = obj.mangle(inname);
        end;
      else
        outname = obj.mangle(inname);
      end;
      return;
    end

    function outname = untranslate_name(obj,inname)
      if iscell(inname)
        outname = {};
        for l = 1:length(inname)
          outname{l} = obj.demangle(inname);
        end;
      else
        outname = obj.demangle(inname);
      end;
      return;
    end
    
    
    
    %%% mangle
    function outname = mangle(obj,inname)
      outname = strrep(inname,'-','__DASH__');
      outname = strrep(outname,'.','__DOT__');
      outname = strrep(outname,'\','__BKSL__');
      outname = strrep(outname,'[','__OPBR__');
      outname = strrep(outname,']','__CLBR__');
      outname = strrep(outname,'+','__PLUS__');
      outname = obj.strip_(outname);
      outname = obj.pad_leading(outname);
      return
    end
    
    %%% demangle
    function outname = demangle(obj,inname)
      outname = obj.strrepb(inname,'__DASH__','-');
      outname = obj.strrepb(outname,'__DOT__','.');
      outname = obj.strrepb(outname,'__BACKSLASH__','\');
      outname = obj.strrepb(outname,'__OPENBRACKET__','[');
      outname = obj.strrepb(outname,'__CLOSEBRACKET__',']');
      outname = obj.strrepb(outname,'__PLUS__','+');
      return;
    end
    
    %%%% strip_
    function outname = strip_(obj,inname)
      inds = find(inname~='_');
      if length(inds)>0
        outname = inname(inds(1):end);
      else
        error(sprintf('variable "%s" is nothing but "_"s',inname));
      end
      return
    end
    
    %%% pad_leading
    function outname = pad_leading(obj,inname)
      inds = regexp(inname,'^\d');
      if length(inds)>0
        outname = ['NR_PL__' inname];
      else
        outname = inname;
      end
    end   
    
    %%%% strrepb
    function outname = strrepb(obj,inname,from,to);
      outname = strrep(inname,from,to);
      inds = regexp(inname,sprintf('^%s',from(3:end)),'end');
      if length(inds)>0
        outname = [to inname((inds(1)+1):end)];
      end
      return
    end
    
    
    
    %%% determine_nc_type
    function [nctype] = determine_nc_type(obj,data_type,ncver)
      
      switch data_type
        case 'char'
          nctype = 'NC_CHAR';
        case 'single'
          nctype = 'NC_FLOAT';
        case 'double'
          nctype = 'NC_DOUBLE';
        case 'int8'
          nctype = 'NC_BYTE';
        case 'uint8'
          nctype = 'NC_UBYTE';
        case 'int16'
          nctype = 'NC_SHORT';
        case 'int32'
          nctype = 'NC_INT';
        case {'uint16','uint32','uint64','int64'}
          if ncver>=4
            switch data_type
              case 'uint16'
                nctype = 'NC_USHORT';
              case 'uint32'
                nctype = 'NC_UINT';
              case 'uint64'
                nctype = 'NC_UINT64';
              case 'int64'
                nctype = 'NC_INT64';
            end
          else % version 3, we have to convert to some type
            switch data_type
              case 'uint16'
                nctype = 'NC_INT';
              case 'uint32'
                nctype = 'NC_INT';
              case 'uint64'
                nctype = 'NC_INT';
              case 'int64'
                nctype = 'NC_INT';
            end
          end
        otherwise
          error(sprintf('Do not know how to handle a ''%s''',datatype));
      end
    end

    %%%% netcdf_ver
    function v = netcdf_ver(obj)
      if isempty(regexp(obj.params.netcdfformat,'^NETCDF4'))
        v = 3;
      else
        v = 4;
      end
    end
    
    %%%% get_type_from_id
    function name = get_type_from_id(obj,id)
      ind = find(id==obj.nc_type_values);
      if length(ind)>=1
        name = obj.nc_type_names{ind(1)};
      else
        error('Constant not found');
      end
    end
    
    %%% preprocess_params
    function preprocess_params(obj,filename)
      if obj.params.getall
        obj.params.getvaratts = 1;
        obj.params.getvartype = 1;
        obj.params.getvardim = 1;
        obj.params.getfileatts = 1;
        obj.params.getfiledim = 1;
        obj.params.getorigvarname = 1;
        obj.params.getgroups = 1;
      end;

      if ~iscell(obj.params.varstoget) 
        obj.params.varstoget = {obj.params.varstoget};
      end;

      if obj.params.clobber | ~exist(filename,'file') | obj.params.putall
        obj.params.putvaratts = 1;
        obj.params.putvartype = 1;
        obj.params.putvardim = 1;
        obj.params.putfileatts = 1;
        obj.params.putfiledim = 1;
      end;
      
      if ~iscell(obj.params.varstoput) 
        obj.params.varstoput = {obj.params.varstoput};
      end;
      
      if ~any(strcmp(obj.params.netcdfformat,{'CLASSIC','64BIT','NETCDF4','NETCDF4_CLASSIC'}))
        error('bad netcdfformat');
      end
      
      if obj.params.format~=0 && obj.params.format~=1 && obj.params.format ~=2
        error('format must be either 1 or 2');
      end
      
    end
    
    %% setup_types
    function setup_types(obj)
      
    % $$$       if isempty(regexp(obj.params.netcdfformat,'^NETCDF4'))
    % $$$         
    % $$$         obj.nc_type_names = {'NC_BYTE','NC_CHAR','NC_DOUBLE','NC_FLOAT','NC_INT','NC_LONG','NC_SHORT','NC_UBYTE'};
    % $$$         obj.nc_type_values = cellfun(@netcdf.getConstant,obj.nc_type_names);
    % $$$         obj.nc_types = cell2struct(num2cell(obj.nc_type_values),obj.nc_type_names,2);
    % $$$         obj.char_types = [obj.nc_types.NC_CHAR];
    % $$$         obj.numeric_types = setdiff(obj.nc_type_values,obj.char_types);
    % $$$ 
    % $$$       else        
    % $$$         
      obj.nc_type_names = {'NC_BYTE','NC_CHAR','NC_DOUBLE','NC_FLOAT','NC_INT','NC_INT64','NC_LONG','NC_SHORT','NC_UBYTE','NC_UINT','NC_UINT64','NC_USHORT'};%,'NC_STRING'};
      obj.nc_type_values = cellfun(@netcdf.getConstant,obj.nc_type_names);
      obj.nc_types = cell2struct(num2cell(obj.nc_type_values),obj.nc_type_names,2);
      
      obj.char_types = [obj.nc_types.NC_CHAR];% obj.nc_types.NC_STRING];
      
      obj.numeric_types = setdiff(obj.nc_type_values,obj.char_types);
      %      obj.converter = cell2struct({@uint8 @char @double   @single     @int32    @int64     @int32    @int16     @uint8    @uint32    @uint64    @uint16    @char },obj.nc_type_names,2);
      obj.converter = cell2struct({@int8 @char @double   @single     @int32    @int64     @int32    @int16     @uint8    @uint32    @uint64    @uint16},obj.nc_type_names,2);
    % $$$       end
      
    end
    
    %%% prep_data
    function od = prep_data(obj,data,data_type)
      if isnumeric(data_type)
        data_type = obj.get_type_from_id(data_type);
      end
      if obj.params.unsigned_ints & any(strcmp(data_type),{'NC_BYTE','NC_SHORT','NC_INT','NC_INT64'});
        data_type = strrep(data_type,'NC_','NC_U');
      end
      converter = obj.converter.(data_type);
      od = converter(data);
    end      
      
    %%% prep_data_att
    function od = prep_data_att(obj,data,data_type)
      od = obj.prep_data(data,data_type);
      if ischar(od) && isempty(od)
        od = char(0);
      end
    end      
      
   
    
  
  end
  

  methods
    
    %%%% NetcdfCommon (consturctor)
    function obj = NetcdfCommon(varargin);

      format = 2; % 1 - for old format, 2 for new format
      ncload = 0;
      
      varstoget = {};
      getall = 1;
      getvaratts = 0;
      getvartype = 0;
      getvardim = 1;
      getmode = 1;
      getfileatts = 0;
      getfiledim = 0;
      getgroups = 1;
      fills2nans = 1;
      unpackvars = 0;
      unsigned_ints = 0;
      tempdir = '';

      
      varstoput = {};
      putvaratts = 0;
      putvartype = 0;
      putvardim = 0;
      putmode = 1;
      putfileatts = 0;
      putfiledim = 0;
      putall = 0;
      nans2fills = 1;
      packvars = 0;
      unsigned_ints = 0;
      netcdfformat = 'CLASSIC'; % can be 'CLASSIC','64BIT','NETCDF4','NETCDF4_CLASSIC'
      check_vars = 0;
      
      clobber = 0;
      verbose = 0;
      force = 0;

      old_backend = [];
      backend = []; % can be 'matlab','mexnc','nctoolbox'
      getorigvarname = [];
      
      paramparse(varargin);
      
      obj.params = varstruct({},{'varargin','obj'});
      
    end
    
    %%% open_file
    function nc = open_file(obj,filename,mode)
      obj.preprocess_params(filename);
      p = obj.params;
      switch mode
        case 'read'
          try
            if length(filename)>3 && strcmp(lower(filename(end-2:end)),'.gz')
              if isempty(p.tempdir)
                pth = fileparts(filename);
              else 
                pth = p.tempdir;
              end
              [dummy,tmpfile] = fileparts(tempname);
              tfile = fullfile(pth,[tmpfile '.nc']);
              [r,o] = run_shell(sprintf('gunzip -c %s > %s',filename,tfile));
              if r
                error(sprintf('Unzipping of file ''%s'' gave the following error: %s',filename,o));
              end
              if p.verbose
                fprintf('Unzipped gzip file "%s"\n',filename);
              end;
              obj.cleanup_files{end+1} = tfile;
            else
              tfile = filename;
            end
          catch
            error(sprintf('Unzipping of file ''%s'' gave the following error: %s',filename,o));
          end
          nc = netcdf.open(tfile,netcdf.getConstant('NC_NOWRITE'));
          obj.filename = filename;
          obj.nc = nc;
          obj.params.netcdfformat = strrep(netcdf.inqFormat(nc),'FORMAT_','');
          if p.verbose
            fprintf('Opened file "%s"\n',filename);
          end;
        case 'write'
          if p.clobber
            % exist or not create a new file
            nc = netcdf.create(filename,obj.format2create(obj.params.netcdfformat,'NC_CLOBBER'));
            obj.cleanup_files{end+1} = obj.filename;
          elseif ~exist(filename,'file')
            % file didn't exist 
            nc = netcdf.create(filename,obj.format2create(obj.params.netcdfformat,'NC_NOCLOBBER'));
            obj.cleanup_files{end+1} = obj.filename;
          else
            % file exists and clobber == 0
            nc = netcdf.open(filename,netcdf.getConstant('NC_WRITE'));
            obj.params.netcdfformat = strrep(netcdf.inqFormat(nc),'FORMAT_','');
          end;
          obj.filename = filename;
          obj.nc = nc;
          if p.verbose
            fprintf('Opened file "%s"\n',filename);
          end;
      end
      obj.setup_types;

    end
    
    %%%% clean_up
    function cleanup(obj)
      try
        netcdf.close(obj.nc)
      end
      for ll = 1:length(obj.cleanup_files)
        try
          delete(obj.cleanup_files{ll});
        end
      end
    end
      
    
    %%% retrieve
    function ncout = retrieve(obj,nc)
      if nargin<2
        nc = obj.nc;
      end
      
      if nc==obj.nc
        ncout.load_info.filename = obj.filename;
        ncout.load_info.format = netcdf.inqFormat(nc);
        ncout.load_info.params = obj.params;
      end
      
      %info = obj.retrieve_global_info(nc);
      [dims,unlim_dims] = obj.retrieve_dims(nc);
      if obj.params.getfiledim
        ncout.dims = dims;
        ncout.unlim_dims = unlim_dims;
      end
      if obj.params.getfileatts
        ncout.atts = obj.retrieve_atts(nc,netcdf.getConstant('NC_GLOBAL'));
      end
      ncout.vars = obj.retrieve_vars(nc,dims);    
      
      if obj.params.getgroups & ~isempty(netcdf.inqGrps(nc));
        ncout.groups = obj.retrieve_groups(nc);
      end
      
    end
    
    %%%% retrieve_global_info(obj,nc)
    function info = retrieve_global_info(obj,nc)
      [info.ndims, info.nvars, info.natts] = netcdf.inq(nc);
      info.dimids = netcdf.inqDimIDs(nc);
      info.varids = netcdf.inqVarIDs(nc);
      info.attids = 0:info.natts-1;
    end
    
    %%% retrieve_dims
    function [dims,unlimited] = retrieve_dims(obj,nc,dimids)
      if nargin<3
        ginfo = obj.retrieve_global_info(nc);
        dimids = ginfo.dimids;
      end
      dims = struct;
      dimnames = {};
      for ll = dimids
        [dimname, dimlength] = netcdf.inqDim(nc,ll);
        dimnames{ll+1} = obj.translate_name(dimname);
        dims.(dimnames{ll+1}).data = dimlength;
        dims.(dimnames{ll+1}).original_name = dimname;
      end;
      if nargout<=1
        return;
      end
      unlimdim = netcdf.inqUnlimDims(nc);
      unlimited = {};
      for ll = 1:length(unlimdim)
        unlimited{ll} = obj.translate_name(netcdf.inqDim(nc,unlimdim(ll)));
      end
    end
    
    %%% retrieve_atts
    function atts = retrieve_atts(obj,nc,varid,attsids)
      if nargin<4 
        if varid==netcdf.getConstant('NC_GLOBAL')
          ginfo = obj.retrieve_global_info(nc);
          attsids = ginfo.attids;
        else
          vinfo = obj.retrieve_var_info(nc);
          attsids = 0:vinfo([vinfo.id]==varid).natts-1;
        end;
      end;

      atts = struct;
      for ll = attsids
        attname = netcdf.inqAttName(nc,varid, ll);
        
        [datatype, attlen] = netcdf.inqAtt(nc,varid,attname);
        name = obj.translate_name(attname);

        if any(datatype == obj.numeric_types)
          att_value = netcdf.getAtt(nc,varid,attname,'double');
          att_value = double(att_value);
          atts.(name).data = att_value;
        else
          try
            att_value = netcdf.getAtt(nc,varid,attname);
            atts.(name).data = att_value;
          catch ME
            warning(sprintf('Unable to retrieve data: %s',ME.message));
            atts.(name).error = ME.message;
          end
        end
        try
          atts.(name).type = obj.get_type_from_id(datatype);
        end
        atts.(name).original_name = attname;
      end
    end

    %%%% compute_expected_size
    function sz = compute_expected_size(obj,dinfo,dimids)
       if isempty(dimids)
         sz = 1;
         return
       end
       %dinfo = retrieve_dims(obj,nc,dimids);
       flds = fieldnames(dinfo);
       for ll = 1:length(flds)
         sz(ll) = dinfo.(flds{ll}).data;
       end
       if length(sz)==1
         sz(2) = 1;
       end
    end
    

    %%% retrieve_vars_info
    function vars = retrieve_var_info(obj,nc,varids,dinfo)
      if nargin<3 
        ginfo = obj.retrieve_global_info(nc);
        varids = ginfo.varids;
      end
      if nargin < 4 
        dinfo = obj.retrieve_dims(nc);
      end
      vars = struct('varname',{},'datatype',{},'dimids',{},'natts',{},'ndims',{},'original_name',{},'id',{});
      for ll = varids
        vars(end+1).varname = '';
        [vars(end).varname, vars(end).datatype, vars(end).dimids, ...
         vars(end).natts] = netcdf.inqVar(nc, ll);
        vars(end).ndims = length(vars(end).dimids);
        vars(end).dimids = fliplr(vars(end).dimids);
        vars(end).size = obj.compute_expected_size(dinfo,fliplr(vars(end).dimids));
        vars(end).original_name = vars(end).varname;
        vars(end).varname = obj.translate_name(vars(end).varname);
        vars(end).id = ll;
      end;
    end
    
    %%%% retrieve_var_data
    function data = retrieve_var_data(obj,nc,var,atts)
      p = obj.params;
      if any(var.datatype == obj.numeric_types)
        try
          %data = netcdf.getVar(nc, var.id,'double');
          data = netcdf.getVar(nc, var.id);
        catch ME
          if regexp(ME.message,'Index exceeds dimension bound')
            data = zeros(var.size);
          else
            rethrow(ME);
          end
        end
        data = double(data);
      else
        try
          data = netcdf.getVar(nc, var.id);
        catch ME
          if regexp(ME.message,'Index exceeds dimension bound')
            data = repmat(' ',var.size);
          else
            rethrow(ME);
          end
        end
      end;
      % permute so that dimensions are correct.
      if var.ndims > 1
        data = permute(data,var.ndims:-1:1);
      end;
      % make nans out of fill values
      if isfield(atts,'FillValue') & p.fills2nans & isnumeric(data)
        fillvalue = atts.FillValue.data;
        if length(fillvalue)==0
          warning(sprintf(['FillValue for the variable %s in file ''%s'' ' ...
                           'has length==0. Skipping.'],...
                          var.varname,obj.filename));
        else
          if length(fillvalue)>1 
            warning(sprintf(['FillValue for the variable %s in file ''%s'' ' ...
                             'has length>1. Just using the first value.'],...
                            var.varname,obj.filename));
            fillvalue = fillvalue(1);
          end;
          data(data==fillvalue) = NaN;
        end;
      end
      if p.unsigned_ints
        switch var.datatype
          case obj.nc_types.NC_BYTE
            data(data<0) = data(data<0)+2^8;
          case obj.nc_types.NC_SHORT
            data(data<0) = data(data<0)+2^16;
          case obj.nc_types.NC_LONG
            data(data<0) = data(data<0)+2^32;
        end
      end
      % unpack
      if p.unpackvars
        if isfield(atts,'scale_factor') && atts.scale_factor.data ~= 1
          data = data*atts.scale_factor.data;
        end;
        if isfield(atts,'add_offset') && atts.add_offset.data ~= 0
          data = data+atts.add_offset.data;
        end;
      end;
    end;

    
    %%%% retrieve_vars
    function vardata = retrieve_vars(obj,nc,dinfo)
      if nargin < 3 | isempty(dinfo)
        dinfo = obj.retrieve_dims(nc);
      end
      
      p = obj.params;
      vars = obj.retrieve_var_info(nc);
      
      if isempty(p.varstoget) 
        inds = 1:length(vars);
        varstoget = {vars.varname};
      elseif ~isempty(p.varstoget) & p.getmode == 2
        inds = 1:length(vars);
      else
        inds = find(strcmpr({vars.varname},p.varstoget));
      end;
      
      for k = inds
        thisvar = {};
        atts = obj.retrieve_atts(nc, vars(k).id, 0:vars(k).natts-1);
        if p.getmode == 1 | (p.getmode == 2 & any(strcmpr(vars(k).varname,p.varstoget)))
          %if getmode == 1 | (getmode == 2 & any(cellfun(@(x) ~isempty(x),regexp(var.varname,varstoget))))
          % get variable data
          vardata.(vars(k).varname).data = obj.retrieve_var_data(nc,vars(k),atts);
        end
        % get variable dimensions
        if p.getvardim
          dimids = vars(k).dimids;
          % check if variable name is valid
          
          vardata.(vars(k).varname).dims = cell(1,0);
          for l = dimids
            dimname = netcdf.inqDim(nc,l);
            vardata.(vars(k).varname).dims{end+1} = obj.translate_name(dimname);
          end;
        end  
        % get variable type
        if p.getvartype
          vardata.(vars(k).varname).type = obj.get_type_from_id(vars(k).datatype);
        end;
        % get variable attributes
        if p.getvaratts & ~isempty(atts)
          vardata.(vars(k).varname).atts = atts;
        end;
        vardata.(vars(k).varname).original_name = vars(k).original_name;
      end;
    end
      
    %%% retrieve_groups
    function groups = retrieve_groups(obj,nc)
      grp_ids = netcdf.inqGrps(nc);
      for ll = grp_ids
        orig_group_name = netcdf.inqGrpName(ll);
        group_name = obj.translate_name(orig_group_name);
        groups.(group_name).data = obj.retrieve(ll);
        groups.(group_name).original_name = orig_group_name;
      end
    end
      
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% writing functions
    
    %%% store
    function store(obj,ncin,nc)
      if obj.params.verbose
        fprintf('redef\n');
      end;
      
      if nargin<3
        nc = obj.nc;
      end
      % put into redef mode
      obj.redef;
    
      ginfo = obj.retrieve_global_info(nc);
      if obj.params.putfiledim & isfield(ncin,'dims')
        if isfield(ncin,'unlim_dims')
          ud = ncin.unlim_dims;
        else
          ud = {};
        end
        obj.store_dims(ncin.dims,ud,nc);
      end
      if obj.params.putfileatts & isfield(ncin,'atts')
        obj.store_atts(ncin.atts,nc,netcdf.getConstant('GLOBAL'));
      end
      
      obj.store_vars(ncin.vars,nc);
      if obj.params.verbose
        fprintf('Enddef\n');
      end;
      
      %obj.store_var_data(ncin.vars,nc);
      
    end
    
    
    
    
    %%%%%%%%%%%%% 
    function redef(obj)
      try
        netcdf.reDef(obj.nc);
      catch ME
        if isempty(regexp(ME.message,'Operation not allowed in define mode'))
          rethrow(ME); 
        end;
      end
    end
      
    %%%%%%%%%%%%% 
    function endef_redef_check(obj)
      netcdf.endDef(obj.nc);
      obj.redef;
    end

    %%%%%%%%%%%% store_dims
    function store_dims(obj,ncin_dims,unlim_dims,nc)
    % see what dimensions are already there.
      [dim_info] = obj.retrieve_dims(nc);
      dims = fieldnames(dim_info);
      ncin_dim_names = fieldnames(ncin_dims);
      % Do not mess with dimensions that already exist.
      dims = obj.setdifford(ncin_dim_names,dims);
      % if record dimension defined
      ind = cellfun(@(x) any(strcmp(x,unlim_dims)),dims);
      if any(ind)
        % and if that dimension is to be added, just set that
        % dimension to 0;
        ind = find(ind);
        for ll = 1:length(ind)
          ncin_dims.(dims{ind(ll)}).data = 0;
        end
      end;
      % loop through adding dimensions
      for ll = 1:length(dims)
        if obj.params.verbose
          fprintf('Creating Dim "%s"\n',dims{ll});
        end;
        if isfield(ncin_dims.(dims{ll}),'original_name')
          dimname = ncin_dims.(dims{ll}).original_name;
        else
          dimname = obj.untranslate_name(dims{ll});
        end
        dimid = netcdf.defDim(nc, dimname, ncin_dims.(dims{ll}).data);
      end;
    end;
    
    %%% store_atts
    function store_atts(obj,ncin_atts,nc,varid)
      attinfo = obj.retrieve_atts(nc,varid);
      atts = fieldnames(attinfo);
      
      ncin_atts_names = fieldnames(ncin_atts);
      if obj.params.force
        atts = ncin_atts_names;
      else
        % don't mess with attributes that already exist
        atts = obj.setdifford(ncin_atts_names,atts);
      end;
      for ll = 1:length(atts)
        if ~isfield(ncin_atts.(atts{ll}),'type')
          nctype = obj.determine_nc_type(class(ncin_atts.(atts{ll}).data),obj.netcdf_ver);
        else
          nctype = ncin_atts.(atts{ll}).type;
        end
        
        tmp = obj.prep_data_att(ncin_atts.(atts{ll}).data,nctype);
        if isfield(ncin_atts.(atts{ll}),'original_name')
          attname = ncin_atts.(atts{ll}).original_name;
        else
          attname = obj.untranslate_name(atts{ll});
        end
        if obj.params.verbose
          if varid==netcdf.getConstant('GLOBAL')
            fprintf('Creating Global Att "%s"\n',atts{ll});
          else
            fprintf('Creating Variable Att "%s"\n',atts{ll});
          end
        end;
        if strcmp(attname,'_FillValue')
          [varname,vtype] = netcdf.inqVar(nc,varid);
          if obj.nc_types.(nctype)~=vtype
            warning(sprintf('Fillvalue for %s has a different type than the variable.  Skipping FillValue.',varname));
            continue;
            fprintf('about to fill %s',varname);
          end
          if length(tmp)~=1
            warning(sprintf('The Fillvalue for ''%s'' has length %i.  Matlab Netcdf does not like this.  Just using the first one.',varname,length(tmp)));
            tmp = tmp(1);
          end          
          if obj.netcdf_ver>=4
            netcdf.defVarFill(nc,varid,false,tmp);
          else
            netcdf.putAtt(nc, varid, attname, tmp);
          end
        else
          netcdf.putAtt(nc, varid, attname, tmp);
        end
      end;
    end
  
    %%%% store_vars
    function store_vars(obj,ncin_vars,nc)
      p = obj.params;
      vinfo = obj.retrieve_var_info(nc);
      varnames = {vinfo.varname};
      
      ncin_var_names = fieldnames(ncin_vars);
      if isempty(p.varstoput) 
        %define all
        inds = 1:length(ncin_var_names);
        %put all
        p.varstoput = ncin_var_names;
      elseif ~isempty(p.varstoput) & p.putmode == 2
        %define all , put what is in ncin_vars
        inds = 1:length(ncin_var_names);
      else
        %define and put what is in ncin_vars
        inds = find(strcmpr(ncin_var_names,p.varstoput));
      end;
      
      for k = reshape(inds,1,[])
        thisvar = ncin_vars.(ncin_var_names{k});
        if ~any(strcmp(ncin_var_names{k},varnames))
          % Need to create the variable
          if ~isfield(thisvar,'dims') | ...
              ~isfield(thisvar,'type')
            error(sprintf('"dim" and "type" required to create field "%s"',...
                          ncin_vars{k}));
          end;
          thedim = ncin_vars.(ncin_var_names{k}).dims;
          % create the variable based off of the nc_in info
          dinfo = obj.retrieve_dims(nc);
          dimnames = fieldnames(dinfo);
          dimids = [];
          for l = 1:length(thedim)
            ind = find(strcmp(thedim{l},dimnames));
            if length(ind)==1
              dimids(end+1) = ind-1;
            else
              error(sprintf('No dimension named %s in file ''%s'' for variable %s',thedim{l},...
                            obj.filename, ncin_var_names{k}));
            end;
          end
          
          if isfield(thisvar,'original_name')
            varname = thisvar.original_name;
          else
            varname = obj.untranslate_name(ncin_var_names{k});
          end
          
          if obj.params.verbose
            fprintf('Creating Var "%s"\n',varname);
          end;
          
          if isfield(thisvar,'type')
            nctype = thisvar.type;
          else
            nctype = obj.determine_nc_type(class(thisvar.data),obj.netcdf_ver);
          end
          
          varid = netcdf.defVar(nc, varname, nctype, fliplr(dimids));
          
          % good checking spot
          if p.check_vars
            obj.endef_redef_check;
          end
        else
          varid = vinfo(strcmp(varnames,ncin_var_names{k})).id;
        end
        
        % Now variable is definitely there.
        % Run through atts.
        if obj.params.putvaratts & isfield(thisvar,'atts')
          obj.store_atts(thisvar.atts,nc,varid);
        end
      end      

      % done Def'ing 
      netcdf.endDef(nc);
      % Now start putting data

      [ncdims,unlimited] = obj.retrieve_dims(nc);
      ginfo = obj.retrieve_global_info(nc);
      vsinfo = obj.retrieve_var_info(nc);
      
      for k = reshape(inds,1,[])
        tmp = ncin_vars.(ncin_var_names{k}).data;

        szt = size(tmp);
        if prod(szt)==0
          continue;
        end
        % get dimensions 
        vinfo = vsinfo(strcmp({vsinfo.varname},ncin_var_names{k}));
        ainfo = obj.retrieve_atts(nc,vinfo.id);
        dinfo = obj.retrieve_dims(nc,vinfo.dimids);
        
        flds = fieldnames(dinfo);
        sz = [];
        if length(dinfo)>0
          for lll = 1:length(flds)
            sz(lll) = dinfo.(flds{lll}).data;
          end
        end
        if isempty(sz)
          sz = 1;
        end;
        if length(sz)==1
          sz = [sz 1];
        end;
        % change the record dimensions to the size of the vector
        ind = cellfun(@(x) any(strcmp(x,unlimited)),fieldnames(dinfo));
        sz(ind) = szt(ind);
        
        if ~isequal(sz,szt)
          error(sprintf('Dimensions of "%s" do not match',ncin_var_names{k}));
        end;

        scale_factor = [];
        add_offset = [];
        FillValue = [];
        
        % get important variable atts
        if isfield(ainfo,'scale_factor')
          scale_factor = ainfo.scale_factor.data;
        end
        if isfield(ainfo,'add_offset')
          add_offset = ainfo.add_offset.data;
        end
        if isfield(ainfo,'FillValue')
          FillValue = ainfo.FillValue.data;
        end
        
        % put variable data
        if obj.params.putmode == 1 | (obj.params.putmode == 2 & any(strcmpr(ncin_var_names{k},obj.params.varstoput)))
          if obj.params.packvars
            if ~isempty(add_offset)
              tmp = tmp-add_offset;
            end;
            if ~isempty(scale_factor)
              tmp = tmp/scale_factor;
            end;
          end;
          
          % make nans out of fill values (note the any(isnan(tmp(:))) condition will rule out
          % character arrays which can't have NaN's.
          if ~isempty(FillValue) & obj.params.nans2fills & any(isnan(tmp(:)))
            tmp(isnan(tmp))=FillValue;
          end;
          
          % prep data
          tmp = obj.prep_data(tmp,vinfo.datatype);
          
          try
            if obj.params.verbose
              fprintf('Putting var data "%s"\n',ncin_var_names{k});
            end;
            
            % we do the actual 'putting' carefully. 
            % 1) if the variable does not have a dimension then start must have 0 length
            % 2) putting with start and size is required for vars with recdim to grow the recdim
            % 3) char arrays work best if you put without size because of how the library 
            %    deals with char(0)'s.  It compares to the size and throws an error.  If
            %    the size is not given, it seems to work just fine.
            if vinfo.ndims==0
              % we do this for the case where no dimensions are given
              netcdf.putVar(nc, vinfo.id, permute(tmp,length(szt):-1:1));
              
            else
              % usual case, will handle recdim resizing but it will not do the reight thing
              % if writing over existing data with a char array containing char(0)
              netcdf.putVar(nc, vinfo.id, zeros(1,max(1,vinfo.ndims)), ...
                            szt(max(vinfo.ndims,1):-1:1),permute(tmp,length(szt):-1:1));
            end
          catch ME
            warning(sprintf('Error Occured while writing ''%s'': diagnosing',vinfo.original_name));
            if strcmp(ME.identifier,'MATLAB:netcdf:putVara:invalidDataType')
              determine_problem_fill_mbe(nc);
            end
            throw(ME);
          end
          if strcmp(obj.get_type_from_id(vinfo.datatype),'NC_CHAR') && any(tmp(:)==char(0))
            % this is to handle the case where this is a char array with a char(0)
            try
              if obj.params.verbose
                fprintf('Hacking text "%s"\n',ncin_var_names{k});
              end;
              netcdf.putVar(nc, vinfo.id, permute(tmp,length(szt):-1:1));
            catch ME
              warning(sprintf('Error Occured while writing ''%s''',vinfo.original_name));
              throw(ME);
            end
          end
        end;
      end
      
    end
  
    
    %%%%%%%%%%%%%%%%%%%%%%
    %% converters
    
    function old = new_to_old(obj,new);
      
      old = struct;
      if isfield(new,'dims')
        dims = fieldnames(new.dims);
        for ll = 1:length(dims)
          old.dims.(dims{ll}) = new.dims.(dims{ll}).data;
        end
      end
      if isfield(new,'atts')
        atts = fieldnames(new.atts);
        for ll = 1:length(atts)
          old.atts.(atts{ll}) = new.atts.(atts{ll}).data;
          if isfield(new.atts.(atts{ll}),'type')
            old.atts_type.(atts{ll}) = new.atts.(atts{ll}).type;
          end
        end
      end
      if isfield(new,'unlim_dims')
        if iscell(new.unlim_dims) & length(new.unlim_dims)==1
          old.recdim = new.unlim_dims{1};
        else
          old.recdim = new.unlim_dims;
        end
      end
      
      flds = fieldnames(new.vars);
      for ll = 1:length(flds)
        newvar = new.vars.(flds{ll});
        if isfield(newvar,'data')
          oldvar.data = newvar.data;
        end
        if isfield(newvar,'dims')
          oldvar.dim = newvar.dims;
        end;
        if isfield(newvar,'type')
          oldvar.type = newvar.type;
        end;
        if isfield(newvar,'atts')
          atts = fieldnames(newvar.atts);
          for kk = 1:length(atts)
            oldvar.atts.(atts{kk}) = newvar.atts.(atts{kk}).data;
            if isfield(newvar.atts.(atts{kk}),'type')
              oldvar.atts_type.(atts{kk}) = newvar.atts.(atts{kk}).type;
            end
          end
        end
        old.(flds{ll}) = oldvar;
      end
    end
        
    function old = new_to_simple(obj,new);
      
      old = struct;

      flds = fieldnames(new.vars);
      for ll = 1:length(flds)
        newvar = new.vars.(flds{ll});
        if isfield(newvar,'data')
          old.(flds{ll}) = newvar.data;
        end
      end
    end
        
    function new = old_to_new(obj,old);
      
      new = struct;
      if isfield(old,'dims')
        dims = fieldnames(old.dims);
        for ll = 1:length(dims)
          new.dims.(dims{ll}).data = old.dims.(dims{ll});
        end
      end
      if isfield(old,'atts')
        atts = fieldnames(old.atts);
        for ll = 1:length(atts)
          new.atts.(atts{ll}).data = old.atts.(atts{ll});
          if isfield(old,'atts_type') && isfield(old.atts_type,atts{ll})
            new.atts.(atts{ll}).type = old.atts_type.(atts{ll});
          end
        end
      end
      if isfield(old,'recdim')
        new.unlim_dims = cellify(old.recdim);
      end
      
      flds = obj.setdifford(fieldnames(old),{'atts','atts_type','dims','recdim'});
      for ll = 1:length(flds)
        oldvar = old.(flds{ll});
        if isfield(oldvar,'data')
          newvar.data = oldvar.data;
        end
        if isfield(oldvar,'dim')
          newvar.dims = oldvar.dim;
        end;
        if isfield(oldvar,'type')
          newvar.type = oldvar.type;
        end;
       if isfield(oldvar,'atts')
          atts = fieldnames(oldvar.atts);
          for kk = 1:length(atts)
            newvar.atts.(atts{kk}).data = oldvar.atts.(atts{kk});
            if isfield(oldvar,'atts_type') && isfield(oldvar.atts_type,atts{kk})
              newvar.atts.(atts{kk}).type = oldvar.atts_type.(atts{kk});
            end
          end
        end
        new.vars.(flds{ll}) = newvar;
      end
      
    end
      
  
  end
end
