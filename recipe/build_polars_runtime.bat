cd %PKG_NAME%
if %ERRORLEVEL% neq 0 exit 1

powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace | Format-Table -AutoSize"

if "%target_platform%"=="win-arm64" (
    set arch=aarch64
) else (
    set arch=x86_64
)

@rem Remove this wrapper once https://github.com/conda-forge/rust-activation-feedstock/pull/79 is merged
copy %RECIPE_DIR%\cargo-auditable-wrapper.bat %BUILD_PREFIX%\Library\bin\cargo-auditable-wrapper.bat
if %ERRORLEVEL% neq 0 exit 1
set "CARGO=cargo-auditable-wrapper.bat"

rem see https://github.com/pola-rs/polars/blob/main/.github/workflows/release-python.yml
set COMPAT_TUNE_CPU=
set COMPAT_FEATURES=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b
set COMPAT_CC_FEATURES=-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16

set NONCOMPAT_TUNE_CPU=skylake
set NONCOMPAT_FEATURES=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b,+avx,+avx2,+fma,+bmi1,+bmi2,+lzcnt,+pclmulqdq,+movbe
set NONCOMPAT_CC_FEATURES=-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16 -mavx -mavx2 -mfma -mbmi -mbmi2 -mlzcnt -mpclmul -mmovbe

set tune_cpu=
set features=
set cc_features=
set cfg=

rem aarch64 has no baseline feature/tuning split, leave RUSTFLAGS and CFLAGS as they are
if not "%arch%"=="x86_64" goto :build

if "%PKG_NAME%"=="polars-runtime-compat" (
    set tune_cpu=%COMPAT_TUNE_CPU%
    set features=%COMPAT_FEATURES%
    set cc_features=%COMPAT_CC_FEATURES%
    set cfg=--cfg allocator="default"
) else (
    set tune_cpu=%NONCOMPAT_TUNE_CPU%
    set features=%NONCOMPAT_FEATURES%
    set cc_features=%NONCOMPAT_CC_FEATURES%
)

if "%tune_cpu%"=="" (
    set RUSTFLAGS=-C target-feature=%features% %cfg%
    set CFLAGS=%CFLAGS% %cc_features%
) else (
    set RUSTFLAGS=-C target-feature=%features% -Z tune-cpu=%tune_cpu% %cfg%
    set CFLAGS=%CFLAGS% %cc_features% -mtune=%tune_cpu%
)

:build
%PYTHON% -m pip install . -vv
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%

cd .\py-polars\runtime
cargo-bundle-licenses --format yaml --output ..\..\THIRDPARTY.yml
