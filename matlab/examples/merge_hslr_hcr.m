function [hcr_regrid,hsrl,hcr] = merge_hslr_hcr(hsrl_file,hcr_files)
% merge_hslr_hcr: routine to merge hsrl file with hcr files
%
% usage: hsrl_merge = merge_hslr_hcr(hsrl_file,hcr_files)
%  where:
%   hsrl_file is a string containing the filename of an hsrl dataset (netcdf)
%   hcr_files is a cell array of strings containing the filenames of the
%             hcr datasets (netcdf)
%
%   The result is hsrl_merge, which is the hsrl data (emerald dataset format)
%   but including matching hcr data.
%
% This function regrids and copies over the hcr data into an hsrl dataset.
% It simply picks the nearest ray in time from the hcr data to each ray
% in the hsrl dataset.  Likewise, it picks the closest range in the hcr 
% when copying.  Note that the hcr data has both higher temporal and spatial
% (along range) resolution.  Note that if the hcr range is more than
% 2 times the median size of the range gate spacing in the hsrl data, 
% the values will be censored.  Likewise for the ray times.
%

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


% load the whole hsrl_file
hsrl = emerald_dataset.load_cfradial(hsrl_file,'all_fields','sweep_index',inf,'do_check',0,'convert_coords',0);

hcr_files = cellify(hcr_files);
%if ~iscell(hcr_files)
%  hcr_files = findfiles(sprintf('%s -name "*.nc"|sort',hcr_files));
%end

% grab all the times from all the hcr datasets to be merged so that we can find
% the best times
for ll = 1:length(hcr_files)
  % load an hcr file with no moment data (not yet)
  hcr = emerald_dataset.load_cfradial(hcr_files{ll},{},'sweep_index',inf,'do_check',0,'convert_coords',0);
  % compute the datenum of the rays (note that hcr.meta_data.time is in seconds which needs to be converted to days)
  meta(ll).times = hcr.meta_data.time_coverage_start_mld+hcr.meta_data.time/24/3600;
  % note the file_index and ray indices (so that when we match the time later
  % we will know what file to load and what ray to use
  meta(ll).file_index = repmat(ll,size(meta(ll).times));
  meta(ll).ray_index = reshape(1:length(meta(ll).times),[],1);
end
% concatenate the struct array into a single struct
meta = struct_cat(meta,'cat_mode','any');

% just ensure that the times are ascending
[meta.times,sortinds] = sort(meta.times);
meta.file_index = meta.file_index(sortinds);
meta.ray_index = meta.ray_index(sortinds);

% compute the datenum for all the hsrl rays
hsrl_times = hsrl.meta_data.time_coverage_start_mld+hsrl.meta_data.time/24/3600;

% For each hsrl ray time, find the nearest hcr ray time
inds = interp1(meta.times,1:length(meta.times),hsrl_times,'nearest','extrap');
% censor any where the time difference is to big, and keep track of which 'inds' are not nan ('nnan')
bad = abs(hsrl_times-meta.times(inds))>= 2*median(diff(hsrl.meta_data.time/24/3600));
inds(bad) = NaN;
nnan = find(~isnan(inds));

% load in the first needed file for info
current_file_index = meta.file_index(inds(nnan(1)));
hcr = emerald_dataset.load_cfradial(hcr_files{current_file_index},'all_fields','sweep_index',inf,'do_check',0,'convert_coords',0);

hcr_regrid = hcr;

% Make note in the hsrl dataset of the filenames, ray indexes and times for each hsrl ray
% for future reference.
hcr_regrid.meta_data.hcr_files = repmat({''},length(inds),1);
hcr_regrid.meta_data.hcr_files(nnan) = hcr_files(meta.file_index(inds(nnan)));
hcr_regrid.meta_data.hcr_ray_index = repmat(NaN,length(inds),1);
hcr_regrid.meta_data.hcr_ray_index(nnan) = meta.ray_index(inds(nnan));
hcr_regrid.meta_data.time = hsrl.meta_data.time;
hcr_regrid.meta_data.range = hsrl.meta_data.range;

% initialize the new moments in the hsrl file and copy over the moment_info data
sz = [length(hsrl.meta_data.time) length(hsrl.meta_data.range)];
hcr_regrid.file_info.time.data = sz(1);
hcr_regrid.file_info.range.data = sz(2);
moment_fields = fieldnames(hcr.moments);
meta_fields = fieldnames(hcr.meta_data);
for ll = 1:length(meta_fields)
  if ischar(hcr.meta_data.(meta_fields{ll}))
    meta_field_type{ll} = 'cell';
  elseif any(strcmp(meta_fields{ll},{'range','time'}))
    meta_field_type{ll} = 'skip';
  elseif isequal(size(hcr.meta_data.(meta_fields{ll})),[hcr.file_info.dims.time.data 1])
    meta_field_type{ll} = 'subvector';
  elseif length(hcr.meta_data.(meta_fields{ll}))==1
    meta_field_type{ll} = 'vector';
  else
    meta_field_type{ll} = 'cell';
  end
  switch meta_field_type{ll} 
    case 'cell'
      hcr_regrid.meta_data.(meta_fields{ll}) = repmat({''},[sz(1) 1]);
    case {'subvector','vector'}
      hcr_regrid.meta_data.(meta_fields{ll}) = repmat(NaN,[sz(1) 1]);
    case 'range'
      hcr_regrid.meta_data.(meta_fields{ll}) = hsrl.meta_data.range;
  end      
end
for ll = 1:length(moment_fields)
  hcr_regrid.moments.(moment_fields{ll}) = repmat(NaN,sz);
end

% loop over all rays in hsrl to actually do the copying
for ll = 1:length(inds)
  if isnan(inds(ll))
    continue;
  end
  % get the file_index for this hsrl ray.
  file_index = meta.file_index(inds(ll));
  % figure out if we need to load in a new hcr, or else just use what we already have
  if file_index~=current_file_index
    % need to load it since it changed from last time
    current_file_index = file_index;
    hcr = emerald_dataset.load_cfradial(hcr_files{file_index},'all_fields','sweep_index',inf,'do_check',0,'convert_coords',0);
  end
  % For each hsrl range, find the nearest hcr range
  range_inds = interp1(hcr.meta_data.range, 1:length(hcr.meta_data.range), hsrl.meta_data.range,'nearest','extrap');
  % censor any that are too far away and keep track of which 'range_inds' are not nan ('nnri')
  bad = abs(hsrl.meta_data.range-hcr.meta_data.range(range_inds))> 2*median(diff(hsrl.meta_data.range));
  range_inds(bad) = NaN;
  nnri = ~isnan(range_inds);
 
  % get the correct ray index
  ray_index = meta.ray_index(inds(ll));
  for kk = 1:length(meta_fields)
    % for each moment_field copy over the data
    switch meta_field_type{kk}
      case 'cell'
        hcr_regrid.meta_data.(meta_fields{kk}){ll} = hcr.meta_data.(meta_fields{kk});
      case 'vector'
        hcr_regrid.meta_data.(meta_fields{kk})(ll) = hcr.meta_data.(meta_fields{kk});
      case 'skip'
        1;
      case 'subvector'
        hcr_regrid.meta_data.(meta_fields{kk})(ll) = hcr.meta_data.(meta_fields{kk})(ray_index);
    end        
  end
  for kk = 1:length(moment_fields)
    % for each moment_field copy over the data
    hcr_regrid.moments.(moment_fields{kk})(ll,nnri) = hcr.moments.(moment_fields{kk})(ray_index,range_inds(nnri));
  end
end

