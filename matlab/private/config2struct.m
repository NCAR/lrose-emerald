function str = config2struct(XXXXXfile,XXXXXnoerrFile)
% config2struct   Evaluates a config file and returns the entries as a struct
%
%  usage str = config2struct(mfilename);
%  mfilename should be a string containing a filname of a script.
%     Filename can have path information or not, and accepts '.m' or not.
%     All variables set in the script are returned in
%     str.

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved.

%If file has no .m extension, add one
[p,f,e] = fileparts(XXXXXfile);
if isempty(e)
    XXXXXfile = fullfile(p,f);
    XXXXXfile = [XXXXXfile '.m'];
end

clear p f e;

if exist(XXXXXfile,'file')
    run(XXXXXfile);
    str = varstruct({},{'XXXXXfile','XXXXXnoerrFile'});
elseif nargin>1 && ~isempty(XXXXXnoerrFile) && strcmp(XXXXXnoerrFile,XXXXXfile)
    str = {};
else
  error(sprintf('Parameter file "%s" does not exist',file));
end

