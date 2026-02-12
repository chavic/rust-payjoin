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

# Use uniffi-bindgen-cs from the fork/branch we track, installed via cargo (no manual clone).
UNIFFI_CS=${UNIFFI_CS:-$HOME/.cargo/bin/uniffi-bindgen-cs}

if [[ ! -x $UNIFFI_CS ]]; then
    echo "Installing uniffi-bindgen-cs from https://github.com/chavic/uniffi-bindgen-cs.git#chavic/csharp-handle-fix..."
    cargo install --git https://github.com/chavic/uniffi-bindgen-cs.git --branch chavic/csharp-handle-fix --locked uniffi-bindgen-cs
fi

# Clean output directory to prevent duplicate definitions
echo "Cleaning csharp/src/ directory..."
rm -f csharp/src/*.cs

# From payjoin-ffi/, library is at ../target/debug/ (workspace root target)
$UNIFFI_CS --library ../target/debug/$LIBNAME --out-dir csharp/src/

# UniFFI marks foreign handles via the low bit. Older generators needed a patch to start at 1 and
# increment by 2. If the expected patterns are missing, assume upstream fixed it and skip.
python3 - <<'PY'
from pathlib import Path

path = Path("csharp/src/payjoin.cs")
text = path.read_text()
replaced = 0

replacements = [
    ("ulong currentHandle = 0;", "ulong currentHandle = 1;"),
    ("currentHandle += 1;\n            map[currentHandle] = obj;\n            return currentHandle;",
     "var handle = currentHandle;\n            currentHandle += 2;\n            map[handle] = obj;\n            return handle;"),
]

for old, new in replacements:
    updated = text.replace(old, new, 1)
    if updated != text:
        replaced += 1
        text = updated

if replaced:
    path.write_text(text)
    print(f"Applied handle-map patch ({replaced} replacements).")
else:
    print("Handle-map patch not needed (generator already emits odd handles).")
PY

# Copy native library to csharp/lib/ directory for testing
echo "Copying native library..."
mkdir -p csharp/lib
cp ../target/debug/$LIBNAME csharp/lib/$LIBNAME

echo "All done!"
