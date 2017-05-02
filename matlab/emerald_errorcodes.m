classdef emerald_errorcodes
% CLass for defining emerald errorcodes.  

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  
% $Revision: 1.3 $
  
  properties (Constant = true)
    OK = 0;
    STRUCT_BAD = 1;
    STRUCT_MISSING_REQ = 2;
    
    WRONG_DATATYPE = 50;
    
    FILENAME_MISMATCH = 100;
    SWEEP_MISMATCH = 101;
    
    SIZE_MISMATCH = 200;
    
    NO_DATA = 500;
    NO_DATASET_SELECTED = 501;
    
    NO_EMERALD_FIGURE = 1000;
    EMERALD_FIGURE_KILLED = 1001;
    BAD_EMERALD_FIGURE_HANDLE = 1002;
    NOT_EMERALD_FIGURE = 1003;
    
    NO_AXES = 1100;
    BAD_AXES_HANDLES = 1101;
    BAD_AXES_HANDLE = 1102;
    
    NO_PLOTS = 1200;
    WRONG_NUMBER_OF_PLOTS = 1201;
    
    
    
    
  end
  
  methods (Static = true)
    function prop = findcode(ec)
      p = properties(emerald_errorcodes);
        for ll = 1:length(p)
          if ec==emerald_errorcodes.(p{ll})
            prop = p{ll};
            return
          end
        end
        error('error code %i not found',ec);
      end
  end
  
  
end


