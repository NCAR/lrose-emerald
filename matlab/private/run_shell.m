function [r,o] = run_shell(command,varargin);
% run_shell  a wrapper for running dos/unix commands
%
% run_shell is an alternative to unix/dos/system commands.
% It allows the user to specify a "shell" program to run,
% putting the 'command's into a file to be run by the shell.  
% This avoids issues of 'expansions' by the default shell run
% by matlab.  Note that the default shell is still called
% in order to execute the given shell, but it should generally
% not matter.
%
% Note that shell's can be other programs that can execute commands
% either by 'executing' commands in a file (e.g. python, awk) or via
% stdin redirection (e.g. mysql, sqlite3, awk; see commands_from_stdin)
%
% usage: [r,o] = run_shell(command,'param1',value1,...);
%
% command is a string containing the command to execute  in
% the shell.  This can contain new line characters (e.g.
% sprintf('ls -1 foo*\necho DONE')).  Note that the sprintf
% turns the string '\n' into a new line character.  If sprintf
% wasn't used, it would leave \n in the command.
%
% r is the return result (int)
% o is the text output (char array)
%
% Optional parameters:
%   shell = '';  name of a shell (can also be any program
%                that accepts files as an input)
%   pipefail_on = 0;  for bash like shells, you may want to
%                     set this to 1.  If 1, the command
%                     that sets the pipefail option on will
%                     be invoked before the given 'command' 
%                     is executed.  In bash and its derivatives
%                     the default setting is that the return
%                     code of a piped series of commands is
%                     the return code of the last command.
%                     e.g. find badDirName | grep foo
%                     always returns 0 (no error).  If pipefail_on
%                     is set, then the return would be non-0.
%   tmp_dir = ''; Name of a temp directory to use.  If none is
%                 given, the matlab temp direectory will be used. 
%                 If that doesn't work, the current directory is used.
%   shell_args = ''; A listing of shell args.  e.g., '-f' turns off loading
%                    of startup files in tcsh.
%   output_file = ''; If nonempty, then the stdout output will be redirected
%                     to this file.
%   exit_command = ''; If nonempty, this command can be used to set the
%                      return code for the script.  This should be in the
%                      language of the shell.  E.g. 'exit $?' should give the 
%                      same as the default behavior in tcsh and bash
%   stdin_redirect = 1; If 1, this will cause a step to be taken to mitigate
%                       the problem where copying and pasting a series of 
%                       commands that include a unix/dos/system command
%                       to stick some of the pasted text into the output
%                       of the unix/dos/system command.  See below.  Unix only.
%   commands_from_stdin = 0; If 1, this overrides stdin_redirect.  This will
%                       cause the commands file to be redirected into the shell
%                       via '<', i.e. "shell shell_args < commands_file" rather
%                       than the default "shell shell_args commands_file".  
%                       This is useful, for example, for certain programs
%                       That do not accept a file as an argument.
%   debug = 0; If 1, then it will cause debug information to be printed, 
%              including the unix/dos/system command actually executed and
%              the contents of the file to be executed (which includes the
%              given commands.
%   delete_tmp = 1; If 1, then this script will clean up the temp file used.
%
%  Note that the options pipefail_on, output_file, and exit_command
%  are just helpers, that prepend or append to your command
%  as needed.  These options can be handled by yourself, if you need to.
%  e.g. [r,o] = run_shell(sprintf('set -o pipefail\nls -l foo*|grep -v fool > myfile'),'shell','bash') 
%  will give you the same as
%  e.g. [r,o] = run_shell('ls -l foo*|grep -v fool'),'shell','bash','pipefail_on',1,'output_file','myfile') 
%
%  Normal approach to running is basically
%   > shell shell_args file_containing_commands
%  If stdin_redirect = 1 then it becomes
%   > shell shell_args file_containing_commands </dev/null
%  which eliminates problems listed below.
%  If commands_from_stdin = 1 then it becomes
%   > shell shell_args < file_containing_commands
%
%  stdin_redirect: This will cause a step to be taken to mitigate
%  the problem where copying and pasting a series of 
%  commands that include a unix/dos/system command
%  to stick some of the pasted text into the output
%  of the unix/dos/system command.  e.g. In some cases
%  pasting:
%  [r,o] = unix(sprintf(' locate run_shell; sleep 1 '));
%  fprintf('foo\n');
%
% into matlab at the same moment (all 3 lines), will cause the following in 'o'
% o =
%
%
% fprintf('foo\n');
%
% /home/meymaris/cvs/apps/matlab/src/utils/#run_shell.m#
% /home/meymaris/cvs/apps/matlab/src/utils/.#run_shell.m
% /home/meymaris/cvs/apps/matlab/src/utils/run_shell.m
% /home/meymaris/cvs/apps/matlab/src/utils/run_shell.m~

% % % ** Copyright (c) 2015, University Corporation for Atmospheric Research
% % % ** (UCAR), Boulder, Colorado, USA.  All rights reserved. 


shell = '';
pipefail_on = 0;
tmp_dir = '';
shell_args = '';
output_file = '';
exit_command = '';
stdin_redirect = 1;
commands_from_stdin = 0;
%post_args = '';

debug = 0;
delete_tmp = 1;

paramparse(varargin);

if isempty(shell)
  if isunix
    shell = 'sh';
  else
    shell = 'cmd';
  end
end

if isempty(tmp_dir)
  tmp_dir = tempdir;
  global TEMPDIR
  if ~isempty(TEMPDIR)
    tmp_dir = TEMPDIR;
  end
  if isempty(tmp_dir)
    tmp_dir = '.';
  end
end

filename = tempname(tmp_dir);

try
  fid = fopen(filename,'wt');
  
  if pipefail_on
    command = sprintf('%s\n%s','set -o pipefail',command);
  end
  
  fprintf(fid,'%s\n%s\n',command,exit_command);
  fclose(fid);
  
  
  if commands_from_stdin
    exec_command = sprintf('%s %s < %s',shell,shell_args,filename);
  else
    exec_command = sprintf('%s %s %s',shell,shell_args,filename);
  end
  
  if isunix && stdin_redirect && ~commands_from_stdin
    exec_command = sprintf('%s < /dev/null',exec_command);
  end
  
  %  if ~isempty(post_args)
  %    exec_command = sprintf('%s %s',exec_command,post_args);
  %  end
    
  
  if ~isempty(output_file)
    exec_command = sprintf('%s > %s',exec_command,output_file);
  end
  if debug
    fprintf('Commands to execute (%s):\n',filename);
    type(filename);
    fprintf('Execute command: %s\n',exec_command);
  end
  [r,o] = unix(exec_command);
catch ME
  try
    type(filename);
  end
  try
    if delete_tmp
      delete(filename);
    end
  end
  rethrow(ME)
end

try
  if delete_tmp
    delete(filename);
  end
end
