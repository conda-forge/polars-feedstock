#!/bin/bash

set -ex

if [[ "${target_platform}" == "linux-64" ]]; then
  # similar to settings upstream in polars
  export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma'
fi

echo rustc --version

# Run the maturin build via pip which works for direct and
# cross-compiled builds.
$PYTHON -m pip install . -vv

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml
