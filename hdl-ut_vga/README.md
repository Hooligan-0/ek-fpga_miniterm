VGA unit-test (HDL)
===================

  This is a HDL (verilog) project used to test the VGA interface. It contains
the sync-IP and the character generator pre-loaded with a small splash screen.

How to make
-----------

1) Using ISE IDE
  This project can be opened using Xilinx-ISE IDE. In the left toolbar, the
module hierarchy is displayed with "main" as top module. Select it with a
single click. At the bottom of the toolbar, three processes are now available
(Synthesize, Implement Design and Generate Programming File). Double click on
the third to run it. This can take some minutes. After each step, icons are
replaced with green flags.
  A binary file "ut_vga.bit" is now ready to load.

2) Using makefile
  The syn directory contains a makefile script. you can type "make" and wait
some minutes. The build process has five steps, each create a log-x-name file
(where x is the step number, and name is the process name).
