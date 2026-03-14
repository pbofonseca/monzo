#!/usr/bin/env bash
# Next steps: authenticate with BigQuery, then run dbt.
# Run from repo root: ./scripts/setup_and_run.sh

set -e
cd "$(dirname "$0")/.."

echo "==> Activating venv..."
source .venv/bin/activate

echo "==> Checking Google auth..."
if command -v gcloud &>/dev/null; then
  if ! gcloud auth application-default print-access-token &>/dev/null; then
    echo "Running: gcloud auth application-default login (browser will open)"
    gcloud auth application-default login
  else
    echo "Application default credentials found."
  fi
else
  echo "gcloud CLI not found. Install it for OAuth:"
  echo "  brew install --cask google-cloud-sdk"
  echo "Then run: gcloud auth application-default login"
  echo ""
  echo "Or use a service account: in profiles.yml set method: service_account and keyfile: /path/to/key.json"
  exit 1
fi

echo "==> Running dbt debug..."
DBT_PROFILES_DIR=. dbt debug

echo "==> Running dbt run..."
DBT_PROFILES_DIR=. dbt run

echo "==> Done."
