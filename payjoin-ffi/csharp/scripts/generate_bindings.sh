#!/usr/bin/env bash
set -euo pipefail

OS=$(uname -s)
echo "Running on $OS"

if [[ $OS == "Darwin" ]]; then
    LIBNAME=libpayjoin_ffi.dylib
elif [[ $OS == "Linux" ]]; then
    LIBNAME=libpayjoin_ffi.so
else
    echo "Unsupported os: $OS"
    exit 1
fi

cd ../
echo "Generating payjoin C#..."
cargo build --features _test-utils --profile dev -j2

# Use uniffi-bindgen-cs (assumes it's installed or use the local one)
UNIFFI_CS=${UNIFFI_CS:-~/Workspace/uniffi-bindgen-cs/target/debug/uniffi-bindgen-cs}

$UNIFFI_CS --library ../target/debug/$LIBNAME --out-dir csharp/src/

echo "All done!"
