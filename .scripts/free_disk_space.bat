setlocal enableextensions enabledelayedexpansion

set CLEANUP_DIRS=^
C:\hostedtoolcache\windows;^
;

rem https://stackoverflow.com/questions/186737/whats-the-fastest-way-to-delete-a-large-folder-in-windows
powershell -Command "Remove-Item -LiteralPath 'C:\hostedtoolcache\windows' -Force -Recurse"


wmic logicaldisk get size,freespace,caption
exit /b
