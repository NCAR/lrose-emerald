function o = ghandle(h)


% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

if verLessThan('matlab','8.4.0') || isnumeric(h)
  o = h;
else
  o = repmat(NaN,size(h));
  for ll = 1:prod(size(h))
    if isprop(h(ll),'Number')
      o(ll) = h(ll).Number;
    elseif strcmp(class(h(ll)),'matlab.ui.Root')
      o(ll) = 0;
    end
  end
     
end
