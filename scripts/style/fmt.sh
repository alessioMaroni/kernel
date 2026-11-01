#!/usr/bin/env bash
set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
IGNORE_FILE="$REPO_ROOT/.git-blame-ignore-revs"

echo "Formatting workspace with rustfmt..."
cargo fmt --all

if git diff --quiet; then
    echo "No formatting changes to save."
    exit 0
fi

git add -u
git commit -m "style: format workspace with rustfmt"

FMT_HASH=$(git rev-parse HEAD)

echo "" >> "$IGNORE_FILE"
echo "# rustfmt run" >> "$IGNORE_FILE"
echo "$FMT_HASH" >> "$IGNORE_FILE"

git add "$IGNORE_FILE"
git commit -m "build: ignore rustfmt commit $FMT_HASH in git blame"

echo "Formatting completed and hash $FMT_HASH added to .git-blame-ignore-revs!"