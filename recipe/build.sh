#!/usr/bin/env bash

set -ex

if [[ "${target_platform}" == "linux-64" ]]; then
  # similar to settings upstream in polars
  export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma'
fi

echo rustc --version

if [[ ("${target_platform}" == "win-64" && "${build_platform}" == "linux-64") ]]; then
  # in a linux -> windows cross-compilation setting we cannot use python in host
  # because otherwise conda-build would try to do prefix replacement which is not possible on Windows
  export PYTHON="$BUILD_PREFIX/bin/python"
  # there are dependencies of polars that need a linux gnu c compiler at buildtime
  # thus we need to create custom cflags since the default ones are for clang
  export CFLAGS_x86_64_unknown_linux_gnu=""
  # we need to add the generate-import-lib feature since otherwise
  # maturin will expect libpython DSOs at PYO3_CROSS_LIB_DIR
  # which we don't have since we are not able to add python as a host dependency
  cargo add pyo3 \
      --manifest-path py-polars/Cargo.toml \
      --features "abi3-py38,extension-module,multiple-pymethods,generate-import-lib"
  maturin build -i "$PYTHON" --target x86_64-pc-windows-msvc
  mkdir -p $PREFIX/lib/python$PY_VER/site-packages
  pip install py-polars/target/wheels/polars*.whl --target $PREFIX/lib/site-packages --platform win_amd64
else
  # Run the maturin build via pip which works for direct and
  # cross-compiled builds.
  $PYTHON -m pip install . -vv
fi

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml
