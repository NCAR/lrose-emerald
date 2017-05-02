function v = circ_arith(val,nyq)


% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

v = mod(val+nyq,2*nyq)-nyq;
