# dbt_monzo

dbt project for BigQuery.

**Data flow:**
- **Source (read-only):** `analytics-take-home-test.monzo_datawarehouse` — raw data, referenced via `source('monzo_datawarehouse', 'table_name')`
- **Downstream (dbt output):** `psfs_ae_stg`, `psfs_ae_int`, `psfs_ae_mrt` — create once with `./scripts/create_psfs_ae_datasets.sh`

## Next steps (run these locally)

1. **Install Google Cloud SDK** (if you don’t have it).
   - **If `brew install --cask google-cloud-sdk` fails** with “Provided python path ... does not exist”:
     ```bash
     ./scripts/fix_gcloud_python.sh
     brew install --cask google-cloud-sdk
     ```
     The script creates the path the cask expects and re-runs the install.
   - **Otherwise** set Python and install:
     ```bash
     export CLOUDSDK_PYTHON=/usr/bin/python3
     brew install --cask google-cloud-sdk
     ```
   If the cask asks to add `gcloud` to your PATH, choose “Yes”. If `gcloud` is still not found after install, open a **new terminal** or run:
   ```bash
   source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
   ```
   (Use `path.bash.inc` and `~/.bash_profile` if you use bash.)

2. **Authenticate and run dbt** (from the `dbt_monzo` folder):
   ```bash
   ./scripts/setup_and_run.sh
   ```
   This will prompt you to log in in the browser (once), then run `dbt debug` and `dbt run`.

   Or do it manually:
   ```bash
   gcloud auth application-default login
   source .venv/bin/activate
   DBT_PROFILES_DIR=. dbt debug
   DBT_PROFILES_DIR=. dbt run
   ```

## Prerequisites

- Python 3.8+
- [dbt-bigquery](https://pypi.org/project/dbt-bigquery/) installed:  
  `pip install dbt-bigquery`
- Access to a Google Cloud project with BigQuery enabled

---

## Configuration checklist

Use this section to gather everything needed before running dbt.

### 1. BigQuery connection (profiles.yml)

Create your profile from the example:

```bash
mkdir -p ~/.dbt
cp profiles.yml.example ~/.dbt/profiles.yml
```

Edit `~/.dbt/profiles.yml` and set:

| Field | Description | Example |
|-------|-------------|---------|
| **project** | Your Google Cloud project ID | `my-gcp-project` |
| **dataset** | Default BigQuery dataset (schema) where dbt builds models | `dbt_dev` or `analytics` |
| **method** | Auth method: `oauth` (local) or `service_account` (CI/prod) | `oauth` |
| **keyfile** | Path to service account JSON key (only if `method: service_account`) | `/path/to/key.json` |

Optional:

- **threads**: Number of threads (default `4`).
- **location**: BigQuery dataset location, e.g. `EU` or `US`.
- **timeout_seconds**: Query timeout.

### 2. Authentication

**Development (oauth)**

- Run `dbt debug` or `dbt run`; you’ll be prompted to sign in with Google.
- Or: `gcloud auth application-default login` then use `method: oauth`.

**CI / production (service account)**

1. In GCP: IAM & Admin → Service accounts → Create.
2. Grant roles: **BigQuery Data Editor**, **BigQuery Job User** (and **BigQuery User** if required).
3. Create a JSON key and download it.
4. In `profiles.yml`: set `method: service_account` and `keyfile: "/path/to/key.json"` (or use `keyfile_json` with inline JSON).

### 3. Source vs downstream datasets

- **Source:** `monzo_datawarehouse` — define tables in `models/staging/_sources.yml` and use `{{ source('monzo_datawarehouse', 'table_name') }}` in models.
- **Downstream (per layer):** Create once with the script:
  ```bash
  ./scripts/create_psfs_ae_datasets.sh
  ```
  This creates (project `analytics-take-home-test`, location `US`, with descriptions):
  - **psfs_ae_stg** — staging (views)
  - **psfs_ae_int** — intermediate (views)
  - **psfs_ae_mrt** — marts (tables)

  Override project/location: `BQ_PROJECT_ID=myproject BQ_LOCATION=EU ./scripts/create_psfs_ae_datasets.sh`

### 4. Project layout (dbt_project.yml)

- **name**: `dbt_monzo`
- **profile**: `dbt_monzo`
- **Staging** → dataset `psfs_ae_stg` (views)
- **Intermediate** → dataset `psfs_ae_int` (views)
- **Marts** → dataset `psfs_ae_mrt` (tables)

### 5. Verify setup

From the project root (`dbt_monzo/`), use the project venv and profile:

```bash
source .venv/bin/activate
DBT_PROFILES_DIR=. dbt debug
```

If using OAuth, authenticate first: `gcloud auth application-default login`

This checks:

- Profile and connection to BigQuery
- That the default dataset exists (or can be created if you have permission)

Then:

```bash
dbt run
```

(Will succeed with no models; add models under `models/staging` and `models/marts` as needed.)

---

## Project structure

```
dbt_monzo/
├── dbt_project.yml
├── profiles.yml         # base dataset: psfs_ae → layers: psfs_ae_stg, _int, _mrt
├── models/
│   ├── staging/        # → psfs_ae_stg
│   │   ├── _sources.yml
│   │   └── *.sql
│   ├── intermediate/   # → psfs_ae_int
│   └── marts/          # → psfs_ae_mrt
├── scripts/
│   ├── create_psfs_ae_datasets.sh  # Create psfs_ae_stg, psfs_ae_int, psfs_ae_mrt in BQ
│   └── setup_and_run.sh
├── macros/, tests/, snapshots/, seeds/, analyses/
```

---

## Quick reference

| Task | Command |
|------|--------|
| Test connection | `dbt debug` |
| Run models | `dbt run` |
| Run tests | `dbt test` |
| Build docs | `dbt docs generate && dbt docs serve` |
| Use prod profile | `dbt run --target prod` |

Fill in **project**, **dataset**, and **method** (and **keyfile** for service account) in `~/.dbt/profiles.yml`, then run `dbt debug` to confirm everything is set.
