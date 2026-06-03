setlocal enableextensions enabledelayedexpansion

bash -c "rm -rf C:\hostedtoolcache\windows"

wmic logicaldisk get size,freespace,caption
exit /b
