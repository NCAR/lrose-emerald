function radar15(base_file,em,varargin);

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 

  saveit = 1;
  datamenu = [50 50];
  data_fetchall = [50 20];
  data_select = [70 -50];
  plotmenu  = [100 50];
  plot_select = [100 20];
  datacursor = [300 -270];
  polygonmenu = [150 50];
  polygon_select = [150 20];

  paramparse(varargin);

  % script
  
  if base_file(1) ~= filesep
    base_file = fullfile(pwd,base_file);
  end
  
  unix('unsetenv LD_LIBRARY_PATH; ksnapshot&');
  pause(1);
  unix('unsetenv LD_LIBRARY_PATH; qdbus org.kde.ksnapshot-`pidof -s ksnapshot` /KSnapshot setGrabMode 1');
  unix('unsetenv LD_LIBRARY_PATH; qdbus org.kde.ksnapshot-`pidof -s ksnapshot` /KSnapshot setTime 0');

  fprintf('Adjust\n');
  eval_pause;
  
  top_left_fig = get_top_left_fig(em.fig);
  
  % snapshot of main
  setup_capture(base_file,'emptymain',1);
  set(0,'PointerLocation',top_left_fig+datamenu); 
  capture;
  save_capture;
  
  % snapshot with data menu
  setup_capture(base_file,'datamenu_fetchall',1);
  set(0,'PointerLocation',top_left_fig+datamenu); 
  lclick
  set(0,'PointerLocation',top_left_fig+data_fetchall); 
  capture;
  save_capture;

  % snapshot with select file dialog 
  setup_capture(base_file,'datamenu_getfile',0);
  fprintf('Move the dialog and Capture the screen shot.  Hit Cancel on the dialog to resume.\n');
  lclick
  save_capture;
  

  %em.fetch_by_filename_sweep('/d2/shared/RV/cfradial/20111016/cfrad.20111016_000031.930_to_20111016_000528.061_SPOL_v3971_SUR.nc','all_fields','sweep_index',inf);
  

  
  % snapshot with select dataset
  setup_capture(base_file,'datamenu_select',1);
  set(0,'PointerLocation',top_left_fig+datamenu); 
  lclick
  set(0,'PointerLocation',top_left_fig+data_select); 
  capture;
  save_capture;
  
  % snapshot with pick dataset dialog
  fprintf('Press Cancel after the image is saved to resume\n');
  setup_capture(base_file,'datamenu_selectdialog',1);
  lclick
  capture;
  save_capture;

  % snapshot of plots
  setup_capture(base_file,'plotsmenu',1);
  set(0,'PointerLocation',top_left_fig+plotmenu); 
  lclick
  set(0,'PointerLocation',top_left_fig+plot_select); 
  capture;
  save_capture;
  
  % snapshot including pick plots dialog
  fprintf('Press OK after the image is saved.  THen Hit enter to resume\n');
  setup_capture(base_file,'plots_selectdialog',1);
  lclick
  capture;
  save_capture;
  eval_pause;
  set(0,'PointerLocation',top_left_fig);

  % snapshot of main with plots
  setup_capture(base_file,'main_ppi',1);
  capture;
  save_capture;
  
  % snapshot of zoom
  h = em.axes_handles(1,1);
  axis([-81.4656   59.6683   15.6941  122.9368]);
  drawnow;
  setup_capture(base_file,'main_ppizoom',saveit);
  capture;
  save_capture;
  
  % snapshot of data cursor
  datacursormode(em.fig,'on')
  drawnow;
  set(0,'PointerLocation',top_left_fig+datacursor);
  fprintf('Click then hit enter to resume\n');
  eval_pause;
  set(0,'PointerLocation',top_left_fig);
  setup_capture(base_file,'main_datacursor',saveit);
  capture;
  save_capture;
  datacursormode(em.fig,'off')
  
  % snapshot of polygon menu
  setup_capture(base_file,'polygonmenu',saveit);
  set(0,'PointerLocation',top_left_fig+polygonmenu); 
  lclick
  set(0,'PointerLocation',top_left_fig+polygon_select); 
  capture;
  save_capture;

  % snapshot of including polygon
  lclick
  fprintf('Make Polygon then hit enter to resume\n');
  eval_pause;
  set(0,'PointerLocation',top_left_fig);
  setup_capture(base_file,'polygon',saveit);
  capture;
  save_capture;

  % snaphot of histogram
  em.plot_window_hist_from_polygon
  top_left_fig = get_top_left_fig(2);
  set(0,'PointerLocation',top_left_fig);
  setup_capture(base_file,'hist',1);
  capture;
  save_capture;


%eval_pause;


end

function out = get_top_left_fig(fig)
  p = get(fig,'Position');
  out = [p(1) p(2)+p(4)];
end

function press_esc
  robot = java.awt.Robot;
  robot.keyPress  (java.awt.event.KeyEvent.VK_ESCAPE);
  robot.keyRelease(java.awt.event.KeyEvent.VK_ESCAPE);
  pause(.1);

end
function lclick
  pause(.1);
  robot = java.awt.Robot;
  robot.mousePress  (java.awt.event.InputEvent.BUTTON2_MASK);
  robot.mouseRelease(java.awt.event.InputEvent.BUTTON2_MASK);
  pause(.1);
end 
function setup_capture(b,suf,delay);
  if nargin<3
    delay = 0;
  end
  fprintf('Setup Snapshot\n');
  fn = [b '_' suf '.png'];
  if exist(fn,'file')
    delete(fn);
  end
  unix(sprintf('unsetenv LD_LIBRARY_PATH; qdbus org.kde.ksnapshot-`pidof -s ksnapshot` /KSnapshot setURL %s',fn));
  unix(sprintf('unsetenv LD_LIBRARY_PATH; qdbus org.kde.ksnapshot-`pidof -s ksnapshot` /KSnapshot setTime %i',delay));
  
end
function capture;
  fprintf('Capturing Snapshot\n');
  unix('unsetenv LD_LIBRARY_PATH; qdbus org.kde.ksnapshot-`pidof -s ksnapshot` /KSnapshot slotGrab');
end
function save_capture;
  pause(5);
  fprintf('Saving Snapshot\n');
  unix('unsetenv LD_LIBRARY_PATH; qdbus org.kde.ksnapshot-`pidof -s ksnapshot` /KSnapshot slotSave');
  
end


