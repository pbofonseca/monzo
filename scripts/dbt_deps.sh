#!/usr/bin/env bash
# Install dbt packages (uses project venv + local profiles to avoid dbt_cloud.yml requirement).
# Run from repo root: ./scripts/dbt_deps.sh

set -e
cd "$(dirname "$0")/.."

DBT_PROFILES_DIR=. .venv/bin/dbt deps
