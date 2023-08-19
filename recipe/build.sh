#!/bin/bash

set -ex

if [[ "${target_platform}" == "linux-64" ]]; then
  # similar to settings upstream in polars
  export RUSTFLAGS='-C target-feature=+fxsr,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt,+avx,+fma'
fi


# Use mold as the linker
mkdir -p .cargo
cat <<EOF > .cargo/config
[target.${rustc_target}]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=${$PREFIX}/bin/mold"]
EOF

# Run the maturin build via pip which works for direct and
# cross-compiled builds.
$PYTHON -m pip install . -vv

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
