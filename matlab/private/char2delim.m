function result = char2delim(ch,delim,varargin)
% usage result = char2delim(ch,delim,'param',paramvalue,...)
%  This function converts a character array or cell array
%  to a delimited 1xN character array, or vice versa.
%
%  ch - the cell or character array to convert
%  delim - the delimter to use.  If [] or missing, the 
%    default is '\n' (Note that this is 2 characters.
%    If you really do want the ascii return code, 10 on 
%    some systems, than set delim to sprintf('\n')
%  
%    Params:
%      RightTrim - can be 1, or 0.  If 1 then
%        the whitespace is trimmed from right side of
%        each row before concatenation.  Default is 1.  
%      LeftTrim - same as RightTrim, except for
%        the trimming occurs on left as well.  Default
%        in 0.
%      Reverse - can be 'tocell', 'tochar', or 'off'.  
%        If 'tochar', then a 1xN delimited char array is 
%        converted to a char matrix array.
%        If 'tocell', then the result is a cell array.
%        If 'off' then the char/cell array is converted
%        to a delimited 1xN char array.
%        
%        When in reverse mode, RightTrim and LeftTrim
%        have the same meaning as above.  But if 
%        Reverse='tochar' and RightTrim=1, whitespace 
%        may still be padded onto right side, in order 
%        to make the char array rectangular. 
%
%      PadEnds - can be 1 or 0.  If 1 then the 1xN char array
%        is padded with delimiters on both ends.  If in
%        Reverse mode, this is done before any other processing
%        If not in Reverse mode, this is done after any other
%        processing.  The default depends on the mode.  If
%        in Reverse mode, the default is 1.  Thus, if ch begins
%        with a delimiter, the default behaviour is that the first 
%        string in the char array or cell array will be blank.  
%        If not in Reverse mode, the default is 0.  Thus the
%        result will begin with the first row in the char array
%        or cell array.  NOTE: IGNOREREPEATED IMPACTS THE 
%        BEHAVIOUR.
%
%      IgnoreRepeated - can be 1 or 0.  If 1, then repeated
%        delimiters are considered the same as one.  The default 
%        is 0.  This is only used if in Reverse mode.  Note: THIS
%        HAS AN IMPACT ON THE BEHAVIOUR OF PADENDS.  If this in
%        on, then 
%        char2delim('\nfool',[],'Reverse','tocell','IgnoreRepeated',1)
%        results in {'fool'}.  Whereas
%        char2delim('\nfool',[],'Reverse','tocell',1)
%        results in the more expected {'' ; 'fool'}
%
%      InternalDelimChar - can be any character.  Default is char(1).  This
%        is the character used internally *if* delim is longer than
%        one character.  This should have no external effect unless
%        char(1) is a character that appears in the string. When used 
%        in Reverse mode, CHAR2DELIM converts all delim->char(1).  So if 
%        there already are char(1)'s in the string, these too will 
%        also be considered as delimiters. 
%        
%
%    examples
%     s = char2delim(strvcat('fool','  stool','kool','slanoool'))
%       returns   'fool\n  stool\nkool\nslanoool'
%     then:
%     r = char2delim(s,[],'Reverse','tochar')
%       returns a 4x8 char array
%        fool    
%          stool 
%        kool    
%        slanoool
%     s = char2delim(strvcat('fool','  stool','kool', ...
%                    'slanoool'),[],'LeftTrim',1)
%       returns   'fool\nstool\nkool\nslanoool'
%     char2delim('fool\n\nto\toll\n\n \n',[],'Reverse','tochar', ...
%                'RightTrim',0,'IgnoreRepeated',1)
%       returns a 3x7 char array
%        fool   
%        to\toll
%             
%
%    Note about the alogrithm:  When used in Reverse mode, 
%    CHAR2DELIM converts all delim->char(1).  So if there 
%    already are char(1)'s in the string, these too will 
%    also be considered to be delimiters. Set InternalDelimChar
%    to fix this problem.
%

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 



if nargin < 2 | isempty(delim)
  delim = '\n';
end;

if nargin < 3 | isempty(varargin)
  varargin = {};
end;

Reverse = 'off';

paramparse(varargin,'Reverse');

Reverse = lower(Reverse);
PadEnds = ~strcmp(Reverse,'off');
RightTrim = 1;
LeftTrim = 0;
IgnoreRepeated = 0;
InternalDelimChar = char(1);

paramparse(varargin);

if IgnoreRepeated
  tokfun = 'strtok';
else
  tokfun = 'single_strtok';
end;

if ~any(strcmp(Reverse,{'tocell','tochar','off'}))
  error(['Unknown option for ''Reverse'': ' Reverse]);
  result = '';
  return;
end;

if length(InternalDelimChar)~=1
  error('InternalDelimChar must have length 1');
  return;
end;

if strcmp(Reverse,'off') & ~RightTrim & ~LeftTrim & ischar(ch)
  method = 'FAST';
elseif strcmp(Reverse,'off')
  method = 'FROMCELL';
  if ischar(ch)
    ch1 = ch;
    ch = cell(size(ch1,1),1);
    for k = 1:size(ch1,1)
      ch{k} = ch1(k,:);
    end;
  end;
else
  method = upper(Reverse);
end

switch method
 case 'FAST'
  bigdelim = delim(ones(size(ch,1),1),:);
  bigdelim(end,:)=' ';
  ch = [ch,bigdelim]';
  result = ch(:)';
  result = result(1:(end-length(delim)));
  if PadEnds
    result = [delim result delim];
  end;
  return;
 case 'FROMCELL'
  result = '';
  if RightTrim
    ch = deblank(ch);
  end;
  for k = 1:length(ch)
    if LeftTrim
      [tok1,remain]=strtok(ch{k});
      ch{k} = [tok1 remain];
    end;
    result = [result delim ch{k}];
  end;
  result = result((length(delim) + 1):end);
  if PadEnds
    result = [delim result delim];
  end;
  return;
 case 'TOCELL'
  if size(ch,1)>1
    ch = ch';
    ch = ch(:)';
  end;
  if PadEnds
    ch = [delim ch delim];
  end;
  
  if length(delim) > 1
    thedelim = InternalDelimChar;
  else
    thedelim = delim;
  end;
  ch = strrep(ch,delim,thedelim);
  [tok1,remain] = feval(tokfun,ch,thedelim);
  result{1} = char(tok1);
  while ~(isempty(tok1) & isempty(remain))
    [tok1,remain] = feval(tokfun,remain,thedelim);
    if ~(isempty(tok1) & isempty(remain))
      result{end+1,1} = char(tok1);
    end;
  end;

  if LeftTrim
    for k = 1:length(result)
      [tok1,remain]=strtok(result{k});
      result{k} = char([tok1 remain]);
    end;
  end;
  if RightTrim
    result = deblank(result);
  end;
  return;
 case 'TOCHAR'
  if size(ch,1)>1
    ch = ch';
    ch = ch(:)';
  end;
  
  if PadEnds
    ch = [delim ch delim];
  end;

  if length(delim) > 1
    thedelim = InternalDelimChar;
  else
    thedelim = delim;
  end;
  ch = strrep(ch,delim,thedelim);
  [tok1,remain] = feval(tokfun,ch,thedelim);
  result{1} = char(tok1);
  while ~(isempty(tok1) & isempty(remain))
    [tok1,remain] = feval(tokfun,remain,thedelim);
    if ~(isempty(tok1) & isempty(remain))
      result{end+1,1} = char(tok1);
    end;
  end;

  if LeftTrim
    for k = 1:length(result)
      [tok1,remain]=strtok(result{k});
      result{k} = char([tok1 remain]);
    end;
  end;
  if RightTrim
    result = deblank(result);
  end;
  result = strvcat(result);
  return;
%  [tok1,remain] = feval(tokfun,ch,retchar);
%  if isempty(tok1) & ~isempty(remain)
%    tok1 = ' ';
%  end;
%  newch = tok1;
%  while ~(isempty(tok1) & isempty(remain))
%    [tok1,remain] = feval(tokfun,remain,retchar);
%    if isempty(tok1) & ~isempty(remain)
%      tok1 = ' ';
%    end;
%    newch = strvcat(newch,tok1);
%  end;
  
%  if LeftTrim
%    %    result = '';
%    %    for k = 1:size(newch,1)
%    %      [tok1,remain]=strtok(newch(k,:));
%    %      if isempty(tok1) & isempty(remain)
%    %	tok1 = ' ';
%    %      end;
%    %      result = strvcat(result,[tok1 remain]);
%    %    end;
%    result = fliplr(strvcat(cellstr((fliplr(newch)))));
%  else
%    result = newch;
%  end;

%  if RightTrim
%    result = strvcat(cellstr((result)));
%  end;
%  return;

end;

function [token, remainder] = single_strtok(string, delimiters)
%SINGLE_STRTOK Find token in string.
%   SINGLE_STRTOK(S) returns the first token in the string S delimited
%   by "white space".   Any leading white space characters are ignored.
%
%   SINGLE_STRTOK(S,D) returns the first token delimited by one of the 
%   characters in D.  Any leading delimiter characters are ignored.
%
%   [T,R] = SINGLE_STRTOK(...) also returns the remainder of the original
%   string.
%   If the token is not found in S then R is an empty string and T
%   is same as S. 
% 
%   See also ISSPACE.

token = []; 
remainder = [];

len = length(string);
if len == 0
  return
end

if (nargin == 1)
  delimiters = [9:13 32]; % White space characters
end

if (any(string(1) == delimiters))
  i = 2;
  if (i > len)
    return
  end
  if any(string(2)==delimiters)
    remainder = string(2:end);
    return;
  end;
else
  i = 1;
end

start = i;
while (~any(string(i) == delimiters))
  i = i + 1;
  if (i > len), break, end
end
finish = i - 1;

token = string(start:finish);

if (nargout == 2)
  remainder = string(finish + 1:length(string));
end
