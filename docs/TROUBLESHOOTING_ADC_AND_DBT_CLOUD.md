# Troubleshooting: dbt Cloud CLI and BigQuery permission errors

## Symptom

After configuring or using the dbt Cloud CLI (e.g. downloading the credentials file to `~/.dbt/dbt_cloud.yml`), running dbt locally fails with:

```
Caller does not have required permission to use project <your-project>.
Grant the caller the roles/serviceusage.serviceUsageConsumer role...
```

Even though you have BigQuery access and could run dbt before.

## Cause

- **dbt Cloud CLI** and/or **`gcloud auth application-default set-quota-project <project>`** can set a **quota project** in your Application Default Credentials (ADC) file: `~/.config/gcloud/application_default_credentials.json`.
- When `quota_project_id` is present, Google APIs require the caller to have the **Service Usage Consumer** role on that project. Your account may have BigQuery roles but not that one, so the check fails.

## Fix

**Option A – Remove quota project from ADC (recommended for local dev)**

Run once (edits the ADC file and removes `quota_project_id`):

```bash
python3 -c "
import json
path = '\${HOME}/.config/gcloud/application_default_credentials.json'
with open(path) as f:
    d = json.load(f)
d.pop('quota_project_id', None)
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
print('Removed quota_project_id from ADC.')
"
```

Then run dbt as usual with the project profile (e.g. `DBT_PROFILES_DIR=. .venv/bin/dbt run`). BigQuery still uses the project from `profiles.yml`; only the extra quota-project permission check is avoided.

**Option B – Grant the role in GCP**

If you prefer to keep the quota project set, grant your user (or the account in ADC) the **Service Usage Consumer** role on the project in [Google Cloud Console → IAM](https://console.cloud.google.com/iam-admin/iam).

## Using dbt locally without dbt Cloud

- Use the **project venv** and **project profiles**:  
  `DBT_PROFILES_DIR=. .venv/bin/dbt run`  
  so dbt uses the repo’s `profiles.yml`, not dbt Cloud.
- If you renamed `~/.dbt/dbt_cloud.yml` to `.bak` to avoid Cloud CLI errors, keep using `DBT_PROFILES_DIR=.` and `.venv/bin/dbt` so the local profile is always used.
