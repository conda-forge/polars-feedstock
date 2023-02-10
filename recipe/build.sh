#!/bin/bash

set -ex

EXTRA_ARGS=

if [[ "${target_platform}" == "linux-64" ]]; then
  # similar to settings upstream in polars
  export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma'
elif [[ "${target_platform}" == "osx-arm64" ]]; then
 EXTRA_ARGS="--target aarch64-apple-darwin"  
fi

maturin build --release --strip --manylinux off --interpreter "${PYTHON}" ${EXTRA_ARGS}

"${PYTHON}" -m pip install $SRC_DIR/target/wheels/polars*.whl --no-deps -vv

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
