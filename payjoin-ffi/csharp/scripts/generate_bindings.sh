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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate to payjoin-ffi directory (parent of csharp, which is parent of scripts)
cd "$SCRIPT_DIR/../.."

echo "Generating payjoin C#..."
cargo build --features _test-utils --profile dev -j2

# Use uniffi-bindgen-cs (assumes it's installed or use the local one)
UNIFFI_CS=${UNIFFI_CS:-$HOME/Workspace/uniffi-bindgen-cs/target/debug/uniffi-bindgen-cs}

# Clean output directory to prevent duplicate definitions
echo "Cleaning csharp/src/ directory..."
rm -f csharp/src/*.cs

# From payjoin-ffi/, library is at ../target/debug/ (workspace root target)
$UNIFFI_CS --library ../target/debug/$LIBNAME --out-dir csharp/src/

# Copy native library to csharp/lib/ directory for testing
echo "Copying native library..."
mkdir -p csharp/lib
cp ../target/debug/$LIBNAME csharp/lib/$LIBNAME

echo "All done!"
