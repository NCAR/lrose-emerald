classdef emerald_databuffer
% emerald_databuffer  A container for functions for handling the Emerald databuffer
%
% The Emerald databuffer is where all of the datasets are stored.  The databuffer is
% is (currently) a global structure.  Do not 'clear all' or 'clear global' or else
% the databuffer will be destroyed.  It is not recommended that you access the global
% structure directly.  Instead, use the unterface functions provided in this library 
% to retrieve and store data.  This is to shield you from possible changes to the
% databuffer at some point in the future.
%
% Object oriented classes here are only used to lump the dataset functions into a single
% container.  This class does not need to be instantiated.  To call any function, 
% just call like:
% OUTARGS = emerald_databuffer.FUNCTION(INARGS)
%
% available functions:
% Databuffer Maintainance:
%   create_databuffer: create the databuffer
%   clear_databuffer: clear the databuffer
%   rebuild_index: rebuild the index for the databuffer
%   check_databuffer: run diagnostic checks on the databuffer
% Databuffer info:
%   databuffer_inventory: get the databuffer inventory
%   databuffer_length: get the length of the databuffer
%   print_databuffer_inventory: print the databuffer inventory to the screen
%   databuffer_inventory_string: return the databuffer inventory string
% Working with datasets within the buffer
%   get_dataset: return a dataset from the databuffer
%   fetch_by_filename_sweep: add 1 or more sweeps to the databuffer from files
%   check_dataset_loaded: check to see if a dataset is already loaded
%   add_to_databuffer: add a dataset to the databuffer
%   check_dataset: run a check to see if a dataset it ok for the databuffer
%   delete_dataset: delete dataset(s) from the databuffer
%   replace_dataset: replace a dataset with a new dataset.
%
% to see help on any of these:
% >> help emerald_databuffer.FUNCTION
%

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


% $Revision: 1.6 $
  
% The databuffer is currently stored as a struct with fields 'datasets' (cell array of emerald_dataset structs) and 'index'
% a struct

  properties (Constant = true)
    dataset_index_fields = {'time_coverage_start_mld','time_start_mld','time','sweep_number','elevation','azimuth','fixed_angle'}; % fields that should exist in the meta_data of the dataset.
    index_fields = {'instrument_name','time_coverage_start','time_start','sweep_number','elevation','azimuth','fixed_elevation_angle','fixed_azimuth_angle'}; % the fields stored in the index
  end
  
  
  methods (Static = true)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% create_databuffer
    function create_databuffer(varargin)
    % create_databuffer: Create a new databuffer.
    % usage: create_databuffer('param1',value1,...)
    % optional params:
    %  clobber = 0; % if 1, then an existing databuffer will be overwritten (lost).
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %

      clobber = 0;
      
      paramparse(varargin);
      
      global EMERALD_DATABUFFER
      
      if ~clobber
        [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER,'check_datasets',1);
        if ~result
        %  warning('The emerald_databuffer already exists and checks out.  Turn clobber on if desired.');
          return
        end
      end
      
      EMERALD_DATABUFFER = struct;
      EMERALD_DATABUFFER.datasets = {};
      EMERALD_DATABUFFER.index = struct;
      EMERALD_DATABUFFER.index = emerald_databuffer.build_index(EMERALD_DATABUFFER);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%
    %%%%
    %%% clear_databuffer
    function clear_databuffer(varargin)
    % clear_databuffer: Clear the databuffer.
    % usage: clear_databuffer
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
     
      paramparse(varargin);
      
      emerald_databuffer.create_databuffer('clobber',1);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% rebuild_index
    function rebuild_index
    % rebuild_index: Rebuild the databuffer index
    % usage: rebuild_index
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %

    % don't bother checking index since we are building it.  The field is checked but it can be an emtpy struct.
    % check datasets 
      global EMERALD_DATABUFFER
      EMERALD_DATABUFFER.index = emerald_databuffer.build_index(EMERALD_DATABUFFER);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% check_databuffer
    function [result,msg] = check_databuffer(varargin)
    % check_databuffer: Do a check on the databuffer
    % usage: [result,msg] = check_databuffer('param1',value1,...)
    % optional params:
    %  check_datasets = 0; % if 1, check the datasets as well as the buffer
    %  check_index = 1; % if 1, check the index
    %
    % outputs:
    %  result: error number, if found.  0 for no error.
    %  msg: string of error found.  
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER,varargin{:});
    end
    

    %%%%%%%%%%%%%%%%%%%
    %% fetch_by_filename_sweep
    function fetch_by_filename_sweep(files,vars,varargin)
    % fetch_by_filename_sweep: fetch (add to buffer) sweeps specfied by filename 
    % usage: fetch_by_filename_sweep(files,vars,'param1',value1,...)
    %   files: cell array of filenames
    %   vars: cell array of field names or can be 'all_fields' to load allcell array of field names
    % optional params:
    %   see help for emerald_dataset.load_cfradial
    %   (sweeps are specified by the sweep_number or sweep_index args.)
    %
    % This will add datasets if not already there.
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      
      files = cellify(files);
      for ll = 1:length(files)
        data = emerald_dataset.load_cfradial(files{ll},vars,'do_check',0,varargin{:});
        for kk = 1:length(data)
          [result,msg] = emerald_databuffer.check_dataset(data(kk));
          if result
            error('Loaded data fails checks:\n%s',msg);
          end
          if emerald_databuffer.check_dataset_loaded(data(kk))
            fprintf('Already Loaded\n');
          else
            emerald_databuffer.add_to_databuffer(data(kk));
          end
        end
      end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%
    %% check_dataset_loaded
    function result = check_dataset_loaded(data);
    % check_dataset_loaded: check to see if a dataset is already loaded
    % usage: result = check_dataset_loaded(data)
    %   data: a emerald_dataset struct
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('Databuffer fails checks:\n%s',msg);
      end
      inds = strcmp(data.file_info.filename,EMERALD_DATABUFFER.index.filename) & data.meta_data.sweep_number==EMERALD_DATABUFFER.index.sweep_number;
      if sum(inds)>0
        result = true;
      else
        result = false;
      end
    end

    %%%%%%%%%%%%%%%%%%%%
    %% add_to_databuffer
    function add_to_databuffer(dataset,afterind)
    % add_to_databuffer: add to buffer a given emerald_dataset struct
    % usage: add_to_databuffer(dataset,afterind)
    %   dataset: a emerald_dataset struct
    %   afterind: an index from 0 to the length of the databuffer.  Indicates
    %             the index after which this new databuffer will be inserted.
    %             An index of 0 indicates that the new dataset will be put
    %             first in the databuffer.
    %
    % This will add a dataset if not already there.
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      [result,msg] = emerald_databuffer.check_dataset(dataset);
      if result
        error('Dataset fails checks:\n%s',msg);
      end
      index_info = emerald_databuffer.get_index_info(dataset);
      
      db = EMERALD_DATABUFFER;
      
      if nargin<2 || isempty(afterind)
        afterind = length(db.datasets);
      end
        
      rebuild = 0;
      if afterind>=length(db.datasets)
        db.datasets{end+1} = dataset;
        db.index = struct_cat(cat(1,EMERALD_DATABUFFER.index,index_info),'cat_mode','any','dim',2);
      elseif afterind==0
        db.datasets = cat(2,{dataset},db.datasets);
        db.index = struct_cat(cat(1,index_info,EMERALD_DATABUFFER.index),'cat_mode','any','dim',2);
      else
        db.datasets = cat(2,db.datasets(1:afterind),{dataset},db.datasets((afterind+1):end));
        rebuild = 1;
      end
      
      EMERALD_DATABUFFER = db;
      if rebuild
        emerald_databuffer.rebuild_index;
      end
    end  
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %% replace_dataset
    function replace_dataset(dataset,replaceind)
    % replace_dataset: replace dataset in buffer a given emerald_dataset struct
    % usage: repalce_dataset(dataset,replaceind)
    %   dataset: a emerald_dataset struct
    %   replaceind: an index from 1 to the length of the databuffer.  Indicates
    %             the index that this dataset will replace.
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      [result,msg] = emerald_databuffer.check_dataset(dataset);
      if result
        error('Dataset fails checks:\n%s',msg);
      end
      index_info = emerald_databuffer.get_index_info(dataset);
      
      db = EMERALD_DATABUFFER;
      
      if nargin<2 || isempty(replaceind)
        error('''replaceind'' must be supplied');
      end
        
      if replaceind>length(db.datasets) || replaceind<0 || replaceind~=round(replaceind)
        error('replaceind must be a valid index of the databuffer');
      end
        
      db.datasets{replaceind} = dataset;
      
      EMERALD_DATABUFFER = db;
      emerald_databuffer.rebuild_index;
      
    end
    
    %%%%%%%%%%%%%%%%%%%%
    %% add_to_databuffer
    function delete_dataset(deleteind)

      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      
      db = EMERALD_DATABUFFER;
      
      if ~islogical(deleteind)
        keep_inds = logical(ones(size(db.datasets)));
        try
          keep_inds(deleteind) = 0;
        catch
          error('deleteind is bad');
        end
      else
        keep_inds = ~delete_ind;
      end
      db.datasets = db.datasets(keep_inds);
      db.index = struct_ind(db.index,keep_inds);
      EMERALD_DATABUFFER = db;

    end  

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% check_dataset
    function [result,msg] = check_dataset(dataset)
    % check_dataset: check to see if a given dataset is ok for emerald_databuffer
    % usage: [result,msg] = check_dataset(dataset)
    %   dataset: a emerald_dataset struct
    %
    % This function performs an emerald_dataset.check_dataset and then performs
    % a few more checks to make sure that it meets emerald_databuffer requirements
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
     
      [result,msg] = emerald_dataset.check_dataset(dataset);
      if result
        return
      end
      
      [missing_fields,msg] = emerald_utils.check_fields_exist(dataset.meta_data,emerald_databuffer.dataset_index_fields);
      if ~isempty(missing_fields)
        result = emerald_errorcodes.STRUCT_MISSING_REQ; 
        msg = sprintf('The following fields are missing from the meta_data:\n%s',msg);
        return
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%
    %%% databuffer_inventory
    function s = databuffer_inventory
    % databuffer_inventory: get inventory for databuffer
    % usage: s = databuffer_inventory
    %
    % This function generates an inventory (returns the index) from the databuffer.
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      s = EMERALD_DATABUFFER.index;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%
    %%% databuffer_length
    function len = databuffer_length
    % databuffer_length: returns the number of datasets in the databuffer
    % usage: len = databuffer_length
    %
    % This function returns the number of datasets in the databuffer
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      len = sum(~cellfun(@isempty,EMERALD_DATABUFFER.datasets));
    end

    %%%%%%%%%%%%%%%%%%%%%%%
    %%% print_databuffer_inventory
    function print_databuffer_inventory(varargin)
    % print_databuffer_inventory: Print the databuffer inventory
    % usage: print_databuffer_inventory
    % optional params:
    %  dataset = []; % array of indexes in the databuffer to inventory.  If [], then all are inventoried
    %  mode = 1; % if mode==1, then produces more info in column format.  If mode==2, then
    %    produces only strings with start times, and sweep numbers.
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      s = emerald_databuffer.databuffer_inventory_string(varargin{:});
      fprintf('%s',s);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%
    %%% print_databuffer_inventory
    function out = databuffer_inventory_string(varargin)
    % databuffer_inventory_string: returns the databuffer inventory string
    % usage: out = databuffer_inventory_string('param1',value1,...)
    % optional params:
    %  dataset = []; % array of indexes in the databuffer to inventory.  If [], then all are inventoried
    %  mode = 1; % if mode==1, then produces more info in column format.  If mode==2, then
    %    produces only strings with start times, and sweep numbers.
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      dataset = [];
      mode = 1;
      paramparse(varargin);
      
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      s = EMERALD_DATABUFFER.index;
      
      if mode==1
        out = sprintf('Name %-19s %-19s Swp MdEl  MdAz  TEl  TAz  Filename\n','Volume Start Time','Sweep Start Time');
      else
        out = '';
      end
      
      if isempty(dataset)
        inds = 1:length(s.time_coverage_start);
      else
        inds = reshape(dataset,1,[]);
      end
      for ll = inds
        ss = struct_ind(s,ll);
        
        switch mode
          case 1
            out = [out sprintf('%4s %s %s %3i  %4.1f %5.1f %4.1f %5.1f %s\n',ss.instrument_name{1},datestr(ss.time_coverage_start,31),datestr(ss.time_start,31),ss.sweep_number,ss.elevation,ss.azimuth,ss.fixed_elevation_angle,ss.fixed_azimuth_angle,ss.filename{1})];
          case 2
            if isnan(ss.fixed_elevation_angle)
              ang_str = sprintf('Az: %5.1f deg',ss.fixed_azimuth_angle);
            else
              ang_str = sprintf('El: %4.1f deg',ss.fixed_elevation_angle);
            end
            out = [out sprintf('%s, Volume Start Time: %s, Sweep Start Time: %s, Sweep Number: %i, %s',ss.instrument_name{1},datestr(ss.time_coverage_start,31),datestr(ss.time_start,31),ss.sweep_number,ang_str)];
        end
      end
    end
 
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %% get_dataset
    function data = get_dataset(ind)
    % get_dataset: returns the dataset corresponding to index: ind 
    % usage: data = get_dataset(ind)
    %
    % Currently, the databuffer is stored in a global variable called EMERALD_DATABUFFER
    % Do not use this variable directly.  'clear all' and 'clear global' will clear the
    % buffer!
    %
      global EMERALD_DATABUFFER
      [result,msg] = emerald_databuffer.check_given_databuffer(EMERALD_DATABUFFER);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      data = EMERALD_DATABUFFER.datasets{ind};
    end
    
    
    

  end
  
  methods (Static = true, Access = private)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% build_index
    function [index] = build_index(db)
    % build_index: returns the index for the databuffer db
    % usage: [index] = build_index(db)
    %
        
    % don't bother checking index since we are building it.  The field is checked but it can be an emtpy struct.
    % check datasets 
      [result,msg] = emerald_databuffer.check_given_databuffer(db,'check_index',0,'check_datasets',1);
      if result
        error('The databuffer is invalid:\n%s',msg);
      end
      
      index = cell2struct(repmat({[]},size(emerald_databuffer.index_fields)),emerald_databuffer.index_fields,2);
      index.filename = {};
      
      if length(db.datasets)==0
        return
      end
      %index_info = struct;
      for ll = 1:length(db.datasets)
        index_info(ll) = emerald_databuffer.get_index_info(db.datasets{ll});
      end
      index = struct_cat(index_info,'dim',2);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% check_given_databuffer
    function [result,msg] = check_given_databuffer(db,varargin)
    % check_given_databuffer: Check the databuffer given as an arg
    % usage: [result,msg] = check_given_databuffer(db,varargin)
    %
    %  check_datasets = 0; % if 1, check the datasets as well as the buffer
    %  check_index = 1; % if 1, check the index
    % 
      
      check_datasets = 0;
      check_index = 1;
      
      paramparse(varargin);

      result = emerald_errorcodes.OK;

      if ~isstruct(db)
        result = emerald_errorcodes.STRUCT_BAD; 
        msg = 'The Emerald databuffer should be a struct.';
        return
      end
      
      % check that the required fields exist
      [missing_fields,msg] = emerald_utils.check_fields_exist(db,{'datasets','index'});
      if ~isempty(missing_fields)
        result = emerald_errorcodes.STRUCT_MISSING_REQ; 
        msg = sprintf('The following fields are missing from the Emerald databuffer structure:\n%s',msg);
        return
      end

      if ~iscell(db.datasets)
        result = emerald_errorcodes.WRONG_DATATYPE;
        msg = sprintf('The field ''datasets'' in the Emerald databuffer structure is not a cell array'); 
        return
      end     
      
      if ~isstruct(db.index)
        result = emerald_errorcodes.STRUCT_BAD; 
        msg = 'The Emerald databuffer field ''index'' should be a struct.';
        return
      end

      if check_index
        % check that the required fields exist
        [missing_fields,msg] = emerald_utils.check_fields_exist(db.index,cat(2,emerald_databuffer.index_fields,{'filename'}));
        if ~isempty(missing_fields)
          result = emerald_errorcodes.STRUCT_MISSING_REQ; 
          msg = sprintf('The following fields are missing from ''index'' in the Emerald databuffer structure:\n%s',msg);
          return
        end
      
        len = length(db.datasets);
        iflds = fieldnames(db.index);
        for ll = 1:length(iflds)
          if length(db.index.(iflds{ll}))~=len
            result = emerald_errorcodes.SIZE_MISMATCH;
            msg = sprintf('The index field ''%s'' does not have the same length as the number of datasets',iflds{ll});
            return;
          end
        end
      end
      
      if check_datasets
        for ll = 1:length(db.datasets)
          [result,msg] = emerald_databuffer.check_dataset(db.datasets{ll});
          if result
            msg = sprintf('In the emerald databuffer, dataset{%i} is invalid\n%s',ll,msg);
            return
          end
        end
      end
    end    
   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %% get_index_info
    function index_info = get_index_info(cstr)
    % index_info: returns the index info for a given dataset
    % usage: index_info = get_index_info(cstr)
    %
      
      [result,msg] = emerald_databuffer.check_dataset(cstr);
      if result
        error('Dataset fails checks:\n%s',msg);
      end
      
      index_info.filename = {cstr.file_info.filename};
      try
        index_info.instrument_name = {cstr.file_info.atts.instrument_name.data};
      catch
        index_info.instrument_name = 'UNKNOWN';
      end
      index_info.time_coverage_start = cstr.meta_data.time_coverage_start_mld;
      index_info.time_start = cstr.meta_data.time_start_mld;
      index_info.sweep_number = cstr.meta_data.sweep_number;
      index_info.azimuth = cstr.meta_data.elevation;
      
      sweep_mode = strrep(cstr.meta_data.sweep_mode,char(0),'');
      
      if any(strcmp(sweep_mode,{'sector','vertical_pointing','azimuth_surveillance','pointing', 'manual_ppi'}))
        index_info.elevation = median(cstr.meta_data.elevation);
        index_info.fixed_elevation_angle = cstr.meta_data.fixed_angle;
      else
        index_info.elevation = NaN;
        index_info.fixed_elevation_angle = NaN;
      end

      if any(strcmp(sweep_mode,{'rhi', 'vertical_pointing','elevation_surveillance','pointing','manual_rhi'}))
        index_info.azimuth = median(cstr.meta_data.azimuth);
        index_info.fixed_azimuth_angle = cstr.meta_data.fixed_angle;
      else
        index_info.azimuth = NaN;
        index_info.fixed_azimuth_angle = NaN;
      end

    end
    
  end
end
