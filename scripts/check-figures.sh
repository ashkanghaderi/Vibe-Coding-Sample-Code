#!/usr/bin/env bash
# Regenerate the screenshots and confirm they still match the committed ones.
#
# This is the check that makes the book's central claim enforceable: a figure
# that no longer matches the code becomes a failing build rather than something
# a reader notices.
set -euo pipefail
cd "$(dirname "$0")/.."

# Pillow goes in a local venv rather than the system Python, which on recent
# macOS is externally managed and refuses installs (PEP 668). Self-contained
# beats "works if your machine happens to have it" - CI has neither.
VENV=".venv-figures"
if [ ! -x "$VENV/bin/python" ]; then
    echo "==> creating $VENV"
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet --upgrade pip
    "$VENV/bin/pip" install --quiet Pillow
fi

FRESH="$(mktemp -d)"
./scripts/shoot-ios.sh "$@"
cp screenshots/*.png "$FRESH/"

# Put the committed figures back before comparing, so this check never leaves
# the working tree dirty on success.
git checkout -- screenshots/ 2>/dev/null || true

"$VENV/bin/python" scripts/check-figures.py screenshots "$FRESH"
