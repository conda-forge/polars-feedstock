set "PYO3_PYTHON=%PYTHON%"

set "CMAKE_GENERATOR=NMake Makefiles"
set "RUSTFLAGS=-C codegen-units=4"
maturin build -v --jobs 1 --release --strip --manylinux off --interpreter=%PYTHON%
if errorlevel 1 exit 1

FOR /F "delims=" %%i IN ('dir /s /b target\wheels\*.whl') DO set polars_wheel=%%i
%PYTHON% -m pip install --ignore-installed --no-deps %polars_wheel% -vv
if errorlevel 1 exit 1

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
