#!/usr/bin/env bash
# Create the downstream dataset for dbt models in BigQuery.
# Run once before the first dbt run. Requires gcloud/bq and permissions to create datasets.
set -e
PROJECT="analytics-take-home-test"
DATASET="dbt_monzo"
LOCATION="US"
echo "Creating dataset ${PROJECT}.${DATASET} (location: ${LOCATION})..."
bq mk --project_id="${PROJECT}" --location="${LOCATION}" "${PROJECT}:${DATASET}"
echo "Done. You can now run: DBT_PROFILES_DIR=. dbt run"
