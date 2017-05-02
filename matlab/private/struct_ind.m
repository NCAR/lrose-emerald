function x = struct_ind(x,ind)
% struct_ind: downsample each field in the struct.
% usage x = struct_ind(x,ind)

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

flds = fieldnames(x);

for kk = 1:length(x)
  for l = 1:length(flds)
    try
      x(kk).(flds{l}) = x(kk).(flds{l})(ind);
    end;
  end;
end
