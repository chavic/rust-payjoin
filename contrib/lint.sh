#!/usr/bin/env bash
set -e

source contrib/lockfile.sh
use_lockfile Cargo-recent.lock

# READMEs must carry the shared payjoin concept text verbatim
bash payjoin-ffi/contrib/sync-concept.sh --check

# Run clippy at top level for crates without feature-specific checks
echo "Running workspace lint..."
cargo clippy --locked --all-targets --keep-going --all-features -- -D warnings

# Lint independent feature sets
FEATURE_CRATES="payjoin payjoin-cli payjoin-ffi"

for crate in $FEATURE_CRATES; do
    echo "Running independent feature lints for $crate crate..."
    (
        cd "$crate"
        ./contrib/lint.sh
    )
done
