Delphi-Code-Examples by Leonid Glazyrin (L-G-)
===================

DumbTreeView.pas - Visual component for Delphi 7, a custom TreeView, written from scratch.

dumbtreeview.res - bitmap resources for the component.

The component class is inherited from TCustomControl and does not uses Windows TreeView control from comctl32.dll).

Compiles and works fine in Delphi XE2 (and probably other Unicode versions). 

These two files contains all that needed to compile the component and (optionally) to install it into Delphi IDE.

TreeTest*.* (7 files) - Demo project for DumbTreeView (open TreeTest.dpr in Delphi).

---

TrayMailCheck.dpr - Simple utility that periodically checks E-mail POP3 servers for undelivered messages and shows blinking envelope icon in system notification area of Windows tray.

Only Win32 API calls are used, without any Delphi VCL classes or functions.

This single file contains all the source code needed to compile the executable application.

---

threads.txt - an unfinished draft for an article on multythreading (in Russian)
