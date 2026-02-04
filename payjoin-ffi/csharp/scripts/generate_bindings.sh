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

# Use uniffi-bindgen-cs. Prefer a globally installed binary from the fork/branch we track.
UNIFFI_CS=${UNIFFI_CS:-$HOME/.cargo/bin/uniffi-bindgen-cs}

if [[ ! -x "$UNIFFI_CS" ]]; then
    echo "Installing uniffi-bindgen-cs (patched via workspace Cargo.toml patch)..."
    cargo install --locked uniffi-bindgen-cs
fi

# Clean output directory to prevent duplicate definitions
echo "Cleaning csharp/src/ directory..."
rm -f csharp/src/*.cs

# From payjoin-ffi/, library is at ../target/debug/ (workspace root target)
$UNIFFI_CS --library ../target/debug/$LIBNAME --out-dir csharp/src/

# UniFFI marks foreign handles via the low bit. Ensure the generated handle map only issues
# odd-valued handles so the runtime can recognize them as foreign.
python3 - <<'PY'
from pathlib import Path

path = Path("csharp/src/payjoin.cs")
text = path.read_text()
text = text.replace("ulong currentHandle = 0;", "ulong currentHandle = 1;")
text = text.replace(
    "currentHandle += 1;\n            map[currentHandle] = obj;\n            return currentHandle;",
    "var handle = currentHandle;\n            currentHandle += 2;\n            map[handle] = obj;\n            return handle;"
)
path.write_text(text)
PY

# Copy native library to csharp/lib/ directory for testing
echo "Copying native library..."
mkdir -p csharp/lib
cp ../target/debug/$LIBNAME csharp/lib/$LIBNAME

echo "All done!"
