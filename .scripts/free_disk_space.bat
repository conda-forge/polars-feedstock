setlocal enableextensions enabledelayedexpansion

set CLEANUP_DIRS=^
C:\hostedtoolcache\windows;^
;

del /f/s/q %CLEANUP_DIRS% > nul
rmdir /s/q %CLEANUP_DIRS%

wmic logicaldisk get size,freespace,caption
exit /b
