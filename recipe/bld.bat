%PYTHON% -m pip install . -vv
cd py-polars
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml
