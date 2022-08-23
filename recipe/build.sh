#!/bin/bash

set -ex

# Set extra compiler flags similar to upstream polars.
case "${target_platform}" in
    'linux-64')
        export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma';;
    'osx-64')
         export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3';;
    'osx-arm64')
         ;;
esac

case "${target_platform}" in
    'linux-64')
        maturin build --release --strip --compatibility off --interpreter="${PYTHON}";;
    'osx-64')
        maturin build --release --strip --interpreter="${PYTHON}";;
    'osx-arm64')
        maturin build --release --strip --target aarch64-apple-darwin --interpreter="${PYTHON}";;
esac

"${PYTHON}" -m pip install ${SRC_DIR}/target/wheels/polars*.whl --no-deps -vv

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
