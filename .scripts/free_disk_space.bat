setlocal enableextensions enabledelayedexpansion

set CLEANUP_DIRS=^
C:\hostedtoolcache\windows;^
;

mkdir C:\empty
for %%f in (%CLEANUP_DIRS:;= %) do (
    if not [%%f] == [] (
        echo Removing %%f
        dir %%f
        robocopy /mir /mt /zb /ns /nc /nfl /ndl /np /njh /njs C:\empty %%f > nul 2>&1
        rmdir /q %%f
    )
)
rmdir /q C:\empty

wmic logicaldisk get size,freespace,caption
exit /b
