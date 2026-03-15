# dbt_monzo

dbt project for transforming and modeling data in **BigQuery**. This project follows dbt best practices: moving data from **source-conformed** (raw) to **business-conformed** (analytics-ready) layers.

---

## Business context & objectives

<!--
  Add here the business needs and objectives from your requirements document.
  Source: https://drive.google.com/file/d/1J6me8K3I-u-5eSM4reKA4SwIFl5KN4bh/view

  Suggested sections to fill from the PDF:
  - Business goals (e.g. reporting, self-serve analytics, compliance)
  - Key stakeholders and consumers of the data
  - Main metrics and definitions the business cares about
  - Scope (which domains, sources, or use cases this project covers)
  - Success criteria or SLAs if any
-->

**Business goals**

- *(Describe the main business goals this project supports — e.g. unified reporting, self-serve analytics, regulatory reporting.)*

**Key stakeholders & consumers**

- *(Who uses these models? Analytics, finance, product, etc.)*

**Main metrics & definitions**

- *(List the main metrics and their business definitions so the project stays aligned with the same language.)*

**Scope**

- *(Which data domains, sources, or use cases are in scope for this project.)*

**Success criteria**

- *(How we know the project is successful — e.g. report coverage, freshness, adoption.)*

---

## Data flow

| Layer | BigQuery dataset | Purpose |
|-------|------------------|---------|
| **Source** (read-only) | `monzo_datawarehouse` | Raw data; referenced in dbt via `source('monzo_datawarehouse', 'table_name')` |
| **Staging** | `psfs_ae_stg` | Light cleaning, renaming, typing — source-conformed building blocks |
| **Intermediate** | `psfs_ae_int` | Business logic, joins, and transformations (not exposed to end users) |
| **Marts** | `psfs_ae_mrt` | Analytics-ready tables for reporting and consumption |

Create the downstream datasets once:

```bash
./scripts/create_psfs_ae_datasets.sh
```

Override project/location: `BQ_PROJECT_ID=myproject BQ_LOCATION=EU ./scripts/create_psfs_ae_datasets.sh`

---

## Project structure

```
.
├── README.md                 # This file — project overview and business context
├── dbt_project.yml           # Project config; staging/int/marts → psfs_ae_*
├── profiles.yml              # BigQuery connection (project, dataset, auth)
├── models/
│   ├── staging/              # → psfs_ae_stg (views)
│   │   ├── _sources.yml      # Source definitions for monzo_datawarehouse
│   │   └── *.sql
│   ├── intermediate/        # → psfs_ae_int (views)
│   └── marts/               # → psfs_ae_mrt (tables)
├── scripts/
│   ├── create_psfs_ae_datasets.sh
│   └── setup_and_run.sh
├── macros/, tests/, snapshots/, seeds/, analyses/
```

---

## Getting started

All runs use the repo’s `profiles.yml`.

> **Tip:** Run every dbt command with `DBT_PROFILES_DIR=.` (or use `./scripts/setup_and_run.sh`). That makes dbt use this project’s `profiles.yml` instead of `~/.dbt`.

### 1. Prerequisites

- Python 3.8+
- [dbt-bigquery](https://pypi.org/project/dbt-bigquery/) (e.g. via project venv: `pip install -r requirements.txt` or `pip install dbt-bigquery`)
- Access to Google Cloud with BigQuery enabled

### 2. Google Cloud SDK (if needed)

If `brew install --cask google-cloud-sdk` fails with "Provided python path ... does not exist":

```bash
./scripts/fix_gcloud_python.sh
brew install --cask google-cloud-sdk
```

Otherwise:

```bash
export CLOUDSDK_PYTHON=/usr/bin/python3
brew install --cask google-cloud-sdk
```

If `gcloud` is not in PATH after install:

```bash
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
```

### 3. Authenticate and run dbt

From the project root:

```bash
./scripts/setup_and_run.sh
```

Or manually:

```bash
gcloud auth application-default login
source .venv/bin/activate
DBT_PROFILES_DIR=. dbt deps   # install packages (e.g. dbt_expectations, dbt_date); required so dbt uses local profiles
DBT_PROFILES_DIR=. dbt debug
DBT_PROFILES_DIR=. dbt run
```

**Note:** Always set `DBT_PROFILES_DIR=.` when running dbt from this project so the local `profiles.yml` is used.

---

## Maintaining dbt

- **Upgrade dbt:** `pip install -U dbt-bigquery` (or `pip install -U -r requirements.txt`). Check [dbt-bigquery releases](https://pypi.org/project/dbt-bigquery/#history).
- **Install/refresh packages:** `DBT_PROFILES_DIR=. dbt deps` (installs packages from `packages.yml`; run after clone or when `packages.yml` changes).
- **Daily workflow:** `DBT_PROFILES_DIR=. dbt run`, `DBT_PROFILES_DIR=. dbt test`, `DBT_PROFILES_DIR=. dbt build` (run + test). Use `./scripts/setup_and_run.sh` for a full run from a clean state.
- **Docs:** `DBT_PROFILES_DIR=. dbt docs generate` then `dbt docs serve`.

---

## Configuration

### BigQuery connection (`profiles.yml`)

Use the project's `profiles.yml` (or copy from `profiles.yml.example` to `~/.dbt/profiles.yml`). Set:

| Field | Description | Example |
|-------|-------------|---------|
| **project** | GCP project ID | `analytics-take-home-test` |
| **dataset** | Base dataset (schema) for dbt; layers get suffixes | `psfs_ae` → psfs_ae_stg, _int, _mrt |
| **method** | `oauth` (local) or `service_account` (CI/prod) | `oauth` |
| **keyfile** | Path to service account JSON (only if `method: service_account`) | `~/.config/gcloud/dbt-sa-key.json` |

Optional: `threads`, `location` (e.g. `US`), `timeout_seconds`.

### Authentication

- **Development:** `gcloud auth application-default login` then `method: oauth`.
- **CI/production:** Create a service account with **BigQuery Data Editor** and **BigQuery Job User**, download a JSON key, set `method: service_account` and `keyfile` in `profiles.yml`.

### Verify setup

```bash
source .venv/bin/activate
DBT_PROFILES_DIR=. dbt debug
```

Then:

```bash
DBT_PROFILES_DIR=. dbt run
```

---

## Documentation (dbt docs)

Generate and serve the dbt docs site (model DAG, descriptions, tests):

```bash
DBT_PROFILES_DIR=. dbt docs generate
DBT_PROFILES_DIR=. dbt docs serve
```

Add `description:` and column-level docs in your YAML (e.g. `_sources.yml`, model schema files) so the generated docs are useful for stakeholders.

---

## Quick reference

| Task | Command |
|------|---------|
| Test connection | `DBT_PROFILES_DIR=. dbt debug` |
| Run models | `DBT_PROFILES_DIR=. dbt run` |
| Run tests | `DBT_PROFILES_DIR=. dbt test` |
| Build docs | `DBT_PROFILES_DIR=. dbt docs generate && dbt docs serve` |
| Production target | `DBT_PROFILES_DIR=. dbt run --target prod` |

Run all commands from the project root with the venv activated and `DBT_PROFILES_DIR=.` so the project's `profiles.yml` is used.
