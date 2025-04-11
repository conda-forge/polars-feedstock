rem see https://github.com/pola-rs/polars/blob/main/.github/workflows/release-python.yml

set arch=x86_64
set cpu_check_module=py-polars\polars\_cpu_check.py

if "%arch%"=="x86_64" (
    set cfg=
    set features=
    set cc_features=

    if "%PKG_NAME%"=="polars-lts-cpu" (
        set features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b
        set cc_features=-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16
        set cfg=--cfg allocator="default"
    ) else (
        set features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b,+avx,+avx2,+fma,+bmi1,+bmi2,+lzcnt,+pclmulqdq,+movbe
        set cc_features=-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16 -mavx -mavx2 -mfma -mbmi -mbmi2 -mlzcnt -mpclmul -mmovbe
    )

    set RUSTFLAGS=-C target-feature=%features% %cfg%
    set CFLAGS=%CFLAGS% %cc_features%
)

rem Using PowerShell for the sed-like functionality since cmd.exe doesn't have native equivalent
powershell -Command "(Get-Content %cpu_check_module%) -replace '^_POLARS_ARCH = \"unknown\"$', '_POLARS_ARCH = \"%arch%\"' | Set-Content %cpu_check_module%.new"
powershell -Command "Move-Item -Force %cpu_check_module%.new %cpu_check_module%"

powershell -Command "(Get-Content %cpu_check_module%) -replace '^_POLARS_FEATURE_FLAGS = \"\"$', '_POLARS_FEATURE_FLAGS = \"%features%\"' | Set-Content %cpu_check_module%.new"
powershell -Command "Move-Item -Force %cpu_check_module%.new %cpu_check_module%"

if "%PKG_NAME%"=="polars-lts-cpu" (
    powershell -Command "(Get-Content %cpu_check_module%) -replace '^_POLARS_LTS_CPU = False$', '_POLARS_LTS_CPU = True' | Set-Content %cpu_check_module%.new"
    powershell -Command "Move-Item -Force %cpu_check_module%.new %cpu_check_module%"
)

type %cpu_check_module%

%PYTHON% -m pip install . -vv

cd py-polars
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml
