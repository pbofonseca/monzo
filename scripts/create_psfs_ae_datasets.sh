#!/usr/bin/env bash
# Create BigQuery datasets for dbt layers (best practices: location, description, labels).
# Run once. Requires bq and permissions to create datasets.
set -e

PROJECT="${BQ_PROJECT_ID:-analytics-take-home-test}"
LOCATION="${BQ_LOCATION:-US}"

create_dataset() {
  local dataset_id=$1
  local description=$2
  echo "Creating ${PROJECT}.${dataset_id} ..."
  bq mk \
    --project_id="${PROJECT}" \
    --dataset \
    --location="${LOCATION}" \
    --description="${description}" \
    "${PROJECT}:${dataset_id}"
}

create_dataset "psfs_ae_stg" "Staging: raw data cleaned and lightly transformed (dbt views)"
create_dataset "psfs_ae_int" "Intermediate: business logic, not exposed to end users (dbt views/tables)"
create_dataset "psfs_ae_mrt" "Marts: analytics-ready tables for consumption (dbt tables)"

echo "Done. Datasets: psfs_ae_stg, psfs_ae_int, psfs_ae_mrt"
