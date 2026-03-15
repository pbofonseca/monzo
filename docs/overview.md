{% docs __overview__ %}
# dbt_monzo — Analytics transformations for BigQuery (project root)

This dbt project transforms and models data in **BigQuery**, following the path from **source-conformed** (raw) to **business-conformed** (analytics-ready) layers.

## Data flow

- **Source:** `monzo_datawarehouse` (read-only)
- **Staging** (`psfs_ae_stg`): Light cleaning and typing
- **Intermediate** (`psfs_ae_int`): Business logic and joins
- **Marts** (`psfs_ae_mrt`): Analytics-ready tables for reporting

For full business context, setup, and configuration, see the project README in the repository.
{% enddocs %}
