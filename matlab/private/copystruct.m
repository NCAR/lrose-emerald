function y = copystruct(x,y,varargin)
% copystruct: Use this to copy fields of 1 struct into another
%
% usage y = copystruct(x,y,'param',value,...)
%
% copy flds of x into y.  Valid params are:
%
% flds = {}; cellarray of fields to copy over.  If {} then will copy all
%            bases on copy_if_noexist, etc. (These should be valid fields 
%            in x).
%
% copy_if_noexist = 1; if 1 then always copy fields.  If 0, then only copy
%            fields in x over to y IF the field already exists in y.
% warn_if_noexist = 0; if 1 then warn when a field in x does not exist in y
%
% recurse_structs = 0; If 1 then recursively copy structures; If 0 then
%            the whole field is just copied over - wiping out the 
%            existing structure
% dest_field_fun = @(x) x; % a function handle to mangle the field name in x
%            when saving into y.  e.g. @(x) sprintf('prefix_%s_suffix',x).
%            This allows you to modify the names easily when copying.  This
%            setting does not recurse.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


copy_if_noexist = 1;
warn_if_noexist = 0;

recurse_structs = 0;
flds = {};
dest_field_fun = @(x) x;

paramparse(varargin);

params = varstruct([],{'x','y'});
params.dest_field_fun = @(x) x;

if isempty(x)
  return;
end;

if iscell(x)
  x = struct(x{:});
end;

flds = cellify(flds);

xflds = fieldnames(x);
yflds = fieldnames(y);

if ~isempty(flds)
  leftovers = setdiff(flds,xflds);
  if length(leftovers)>0
    warning('The following fields were not in x');
    fprintf('%s  ',leftovers{:});
  end;
  xflds = intersect(xflds,flds);
end;

if warn_if_noexist
  % figure out which "mangled" xnames are not in y
  [~,inds] = setdiff(icellfun(xflds,dest_field_fun),yflds);
  for ll = 1:length(inds)
    warning(sprintf('Field %s does not exist in y (accounting for field mangling if applicable)',xflds{inds(ll)}));
  end
end

if ~copy_if_noexist
  % figure out which "mangled" xnames are in y
  [~,inds] = intersect(icellfun(xflds,dest_field_fun),yflds);
  % restrict ourselves to that list of "premangled" xnames;
  xflds = xflds(inds);
end;

for l = 1:length(xflds)
  outname = dest_field_fun(xflds{l});
  % if recurse is on, both fields exist and are structs then recurse in
  if recurse_structs & isstruct(x.(xflds{l})) & ...
        isfield(y,outname) & isstruct(y.(outname))
    y.(outname) = copystruct(x.(xflds{l}),y.(outname),params);
  else
    y.(outname) = x.(xflds{l});
  end;
end;
