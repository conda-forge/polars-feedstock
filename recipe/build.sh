#!/bin/bash

set -ex

if [[ "${target_platform}" == "linux-64" ]]; then
  # similar to settings upstream in polars
  export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma'
fi

echo "${target_platform}" # For debug, will remove

if [[ "${target_platform}" == "osx-64" ]]; then
  export SYSTEM_VERSION_COMPAT=0
fi

maturin build --release --strip --manylinux off --interpreter="${PYTHON}"

"${PYTHON}" -m pip install $SRC_DIR/target/wheels/polars*.whl --no-deps -vv

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
