#!/usr/bin/env bash
# Fix "Provided python path ... does not exist" when installing google-cloud-sdk via Homebrew.
# The cask expects: /opt/homebrew/opt/python@3.13/libexec/bin/python3
# Run this script, then run: brew install --cask google-cloud-sdk

set -e

EXPECTED_DIR="/opt/homebrew/opt/python@3.13/libexec/bin"
EXPECTED_PYTHON="${EXPECTED_DIR}/python3"

# Find a suitable python3 (Homebrew's python@3.13 or system)
if [[ -x "/opt/homebrew/opt/python@3.13/bin/python3" ]]; then
  REAL_PYTHON="/opt/homebrew/opt/python@3.13/bin/python3"
elif [[ -x "/opt/homebrew/bin/python3" ]]; then
  REAL_PYTHON="/opt/homebrew/bin/python3"
else
  REAL_PYTHON=$(which python3 2>/dev/null || true)
fi

if [[ -z "$REAL_PYTHON" || ! -x "$REAL_PYTHON" ]]; then
  echo "Could not find python3. Install with: brew install python@3.13"
  exit 1
fi

if [[ -x "$EXPECTED_PYTHON" ]]; then
  echo "Path already exists: $EXPECTED_PYTHON"
  exit 0
fi

echo "Creating $EXPECTED_DIR and symlinking python3 -> $REAL_PYTHON"
sudo mkdir -p "$EXPECTED_DIR"
sudo ln -sf "$REAL_PYTHON" "$EXPECTED_PYTHON"
echo "Done. Run: brew install --cask google-cloud-sdk"
