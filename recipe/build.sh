#!/usr/bin/env bash

set -ex

export CARGO_PROFILE_RELEASE_STRIP=symbols

case "${target_platform}" in
  linux-aarch64|osx-arm64)
    arch="aarch64"
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
    features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt
    cfg="--cfg allocator=\"default\""
  elif [[ -n "${OSX_ARCH}" ]]; then
    features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma,+pclmulqdq
  else
    features=+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+avx2,+fma,+bmi1,+bmi2,+lzcnt,+pclmulqdq
  fi

  export RUSTFLAGS="-C target-feature=$features $cfg"
fi

if [[ "${PKG_NAME}" == "polars-lts-cpu" ]]; then
    sed -i.bak "s/^_LTS_CPU = False$/_LTS_CPU = True/g" $cpu_check_module
fi

sed -i.bak "s/^_POLARS_ARCH = \"unknown\"$/_POLARS_ARCH = \"$arch\"/g" $cpu_check_module
sed -i.bak "s/^_POLARS_FEATURE_FLAGS = \"\"$/_POLARS_FEATURE_FLAGS = \"$features\"/g" $cpu_check_module

# Use jemalloc on linux-aarch64
if [[ "${target_platform}" == "linux-aarch64" ]]; then
  export JEMALLOC_SYS_WITH_LG_PAGE=16
fi

rustc --version

if [[ ("${target_platform}" == "win-64" && "${build_platform}" != "win-64") ]]; then
  # we need to add the generate-import-lib feature since otherwise
  # maturin will expect libpython DSOs at PYO3_CROSS_LIB_DIR
  # which we don't have since we are not able to add python as a host dependency
  cargo feature pyo3 +generate-import-lib --manifest-path py-polars/Cargo.toml

  # cc-rs hardcodes ml64.exe as the MASM assembler for x86_64-pc-windows-msvc
  # We want to use LLVM's MASM assembler instead
  # https://github.com/rust-lang/cc-rs/issues/1022
  cat > $BUILD_PREFIX/bin/ml64.exe <<"EOF"
#!/usr/bin/env bash
llvm-ml -m64 $@
EOF

  chmod +x $BUILD_PREFIX/bin/ml64.exe

  export CC_x86_64_pc_windows_msvc="$BUILD_PREFIX/bin/clang"
  export CXX_x86_64_pc_windows_msvc="$BUILD_PREFIX/bin/clang++"
  export LD_x86_64_pc_windows_msvc="$BUILD_PREFIX/bin/lld-link"
  export LDFLAGS=${LDFLAGS/-manifest:no/}

  maturin build --release --strip --interpreter $RECIPE_DIR/mock-win-python.sh
  pip install target/wheels/polars*.whl --target $PREFIX/lib/site-packages --platform win_amd64
else
  # Run the maturin build via pip which works for direct and
  # cross-compiled builds.
  $PYTHON -m pip install . -vv
fi

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars
cargo-bundle-licenses --format yaml --output ../THIRDPARTY.yml
