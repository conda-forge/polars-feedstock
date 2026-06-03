setlocal enableextensions enabledelayedexpansion

powershell -Command "Remove-Item -LiteralPath 'C:\hostedtoolcache\windows' -Force -Recurse"

wmic logicaldisk get size,freespace,caption
exit /b
