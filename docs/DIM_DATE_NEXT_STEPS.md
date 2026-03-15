# dim_date – next steps

Use the **godatadriven/dbt_date** package (already in `packages.yml`) to add a date dimension to the marts layer.

## 1. Set time zone (required by the package)

In `dbt_project.yml`, under `vars:`, add:

```yaml
vars:
  "dbt_date:time_zone": "UTC"   # source timestamps are UTC
```

Override at runtime if needed: `--vars '{"dbt_date:time_zone": "UTC"}'`

## 2. Create the dim_date model

Add `models/marts/dim_date.sql` that calls the package macro with a start and end date:

```sql
{{ config(materialized='table') }}

{{ dbt_date.get_date_dimension('2020-01-01', '2030-12-31') }}
```

Adjust the date range to match your data (e.g. min/max dates from your events).

## 3. Document the model

In `models/marts/_marts__models.yml`, add a `dim_date` entry with a short description and any column-level docs or tests (e.g. `date_day` unique, not_null).

## 4. Run and test

From the project root:

```bash
DBT_PROFILES_DIR=. dbt run --select dim_date
DBT_PROFILES_DIR=. dbt test --select dim_date
```

## 5. Use in other models

Join to the dimension by date, e.g.:

- `ref('dim_date')` and join on `date_day` (or the date column your facts use).
- Use columns like `day_of_week`, `week_of_year`, `month_name`, `prior_year_date` for reporting.

## Package reference

- **Macro:** `dbt_date.get_date_dimension(start_date, end_date)`  
- **Docs:** [dbt_date on GitHub](https://github.com/godatadriven/dbt-date)  
- **Columns:** `date_day`, `day_of_week`, `day_name`, `week_of_year`, `month_of_year`, `month_name`, `quarter_of_year`, `year_number`, `prior_year_date`, and more.
