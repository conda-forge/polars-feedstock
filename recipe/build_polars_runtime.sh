#!/usr/bin/env bash

set -euxo pipefail

cd $PKG_NAME

# Remove this wrapper once https://github.com/conda-forge/rust-activation-feedstock/pull/79 is merged
mkdir -p ${BUILD_PREFIX}/bin
cp ${RECIPE_DIR}/cargo-auditable-wrapper.sh ${BUILD_PREFIX}/bin/cargo-auditable-wrapper
export CARGO="cargo-auditable-wrapper"
export CARGO_PROFILE_RELEASE_STRIP=symbols

# see https://github.com/pola-rs/polars/blob/main/.github/workflows/release-python.yml
COMPAT_TUNE_CPU=''
COMPAT_FEATURES='+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b'
COMPAT_CC_FEATURES='-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16'

NONCOMPAT_TUNE_CPU='skylake'
NONCOMPAT_FEATURES='+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b,+avx,+avx2,+fma,+bmi1,+bmi2,+lzcnt,+pclmulqdq,+movbe'
NONCOMPAT_CC_FEATURES='-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16 -mavx -mavx2 -mfma -mbmi -mbmi2 -mlzcnt -mpclmul -mmovbe'


case "${target_platform}" in
  linux-aarch64|osx-arm64)
    arch="aarch64"
    ;;
  *)
    arch="x86_64"
    ;;
esac

if [[ $arch == "x86_64" ]]; then
  if [[ $PKG_NAME == "polars-runtime-compat" ]]; then
    TUNE_CPU="$COMPAT_TUNE_CPU"
    FEATURES="$COMPAT_FEATURES"
    CC_FEATURES="$COMPAT_CC_FEATURES"
  else
    TUNE_CPU="$NONCOMPAT_TUNE_CPU"
    FEATURES="$NONCOMPAT_FEATURES"
    CC_FEATURES="$NONCOMPAT_CC_FEATURES"
  fi

  if [[ $PKG_NAME == polars-runtime-compat ]]; then
    CFG='--cfg allocator="default"'
  fi

  if [[ -z "${TUNE_CPU:-}" ]]; then
    export RUSTFLAGS="-C target-feature=$FEATURES ${CFG:-}"
    export CFLAGS="$CFLAGS $CC_FEATURES"
  else
    export RUSTFLAGS="-C target-feature=$FEATURES -Z tune-cpu=$TUNE_CPU ${CFG:-}"
    export CFLAGS="$CFLAGS $CC_FEATURES -mtune=$TUNE_CPU"
  fi
fi



if [[ $target_platform == "linux-aarch64" ]]; then
  export JEMALLOC_SYS_WITH_LG_PAGE=16
fi

$PYTHON -m pip install . -vv

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars/runtime
cargo-bundle-licenses --format yaml --output ../../THIRDPARTY.yml
