#!/usr/bin/env bash

set -euxo pipefail

export CARGO_PROFILE_RELEASE_STRIP=symbols

# see https://github.com/pola-rs/polars/blob/main/.github/workflows/release-python.yml

case "${target_platform}" in
  linux-aarch64|osx-arm64)
    arch="aarch64"
    ;;
  linux-ppc64le)
    arch="powerpc64le"
    ;;
  *)
    arch="x86_64"
    ;;
esac

export
cpu_check_module="py-polars/polars/_cpu_check.py"
features=""

if [[ ${arch} == "x86_64" ]]; then
  cfg=""
  if [[ "${PKG_NAME}" == "polars-lts-cpu" ]]; then
    features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b
    cc_features="-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16"
    cfg="--cfg allocator=\"default\""
  else
    features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+cmpxchg16b,+avx,+avx2,+fma,+bmi1,+bmi2,+lzcnt,+pclmulqdq,+movbe
    cc_features="-msse3 -mssse3 -msse4.1 -msse4.2 -mpopcnt -mcx16 -mavx -mavx2 -mfma -mbmi -mbmi2 -mlzcnt -mpclmul -mmovbe"
  fi

  export RUSTFLAGS="-C target-feature=$features $cfg"
  export CFLAGS="$CFLAGS $cc_features"
elif [[ ${arch} == "powerpc64le" ]]; then
  cfg="--cfg allocator=\"default\""
  export RUSTFLAGS="$cfg"
fi

sed -i.bak "s/^_POLARS_ARCH = \"unknown\"$/_POLARS_ARCH = \"$arch\"/g" $cpu_check_module
sed -i.bak "s/^_POLARS_FEATURE_FLAGS = \"\"$/_POLARS_FEATURE_FLAGS = \"$features\"/g" $cpu_check_module

if [[ "${PKG_NAME}" == "polars-lts-cpu" ]]; then
    sed -i.bak "s/^_POLARS_LTS_CPU = False$/_POLARS_LTS_CPU = True/g" $cpu_check_module
fi

# Use jemalloc on linux-aarch64
if [[ "${target_platform}" == "linux-aarch64" ]]; then
  export JEMALLOC_SYS_WITH_LG_PAGE=16
fi

cat $cpu_check_module

$PYTHON -m pip install . -vv

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml
