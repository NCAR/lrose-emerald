function fun = make_feval_able(fun)
% MAKE_FEVAL_ABLE - makes strings able to be feval'ed, using inline if needed
%
%  usage: outfun = make_feval_able(fun)
% 
%  fun is either a string or an INLINE. INLINES pass right through this
%  function.  If it is a string, it looks to see if it contains any 
%  characters other than an alpha or numeric.  If it does, it 'INLINE's
%  it.  If it is all alpha's and numeric's it will INLINE it only if
%  the string is not the name of a function.  It is determined to be
%  a function if the non-variable results from WHICH are not empty

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


if isstr(fun) & (any(fun<48) | any(fun>=91 & fun<=94))
  % if char and contains anything other than alphanumeric, then inline it
  fun = inline(fun);
elseif  ischar(fun) 
  % if char and is not an m-file name in the path
  s = which(fun,'-all');
  s = s(~strcmp('variable',s));
  if isempty(s)
    fun = inline(fun);
  end;
end
