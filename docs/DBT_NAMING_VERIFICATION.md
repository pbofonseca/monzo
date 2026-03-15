# dbt naming convention verification (marts)

Reference: [How we style our dbt models](https://docs.getdbt.com/best-practices/how-we-style/1-how-we-style-our-dbt-models).

## Standards applied

| Rule | Convention | Applied in marts |
|------|------------|-----------------|
| **Schema/table/column names** | `snake_case` | ✅ All model and column names use snake_case |
| **Dates** | Suffix `_date` (e.g. `created_date`) | ✅ `valid_from_date`, `valid_to_date`; `dim_date.date_day` (package) |
| **Timestamps** | Suffix `_at`, UTC (e.g. `created_at`) | ✅ `valid_from_at`, `valid_to_at` |
| **Booleans** | Prefix `is_` or `has_` | ✅ `is_current` |
| **Primary/surrogate keys** | Suffix `_id` or `_sk` | ✅ `account_sk` (surrogate), `account_id_hashed` (natural key) |
| **Column order** | ids → strings → numerics → booleans → dates → timestamps | ✅ `dim_account`: ids, account_type, is_current, valid_from_date, valid_to_date, valid_from_at, valid_to_at |
| **No abbreviations** | Full words | ✅ e.g. `account`, `valid`, `current` |
| **Reserved words** | Avoid | ✅ No reserved words used |

## Join: dim_account ↔ dim_date

- **dim_date** primary key: `date_day` (calendar date, one row per day).
- **dim_account** date columns for joining without transformation:
  - `valid_from_date` = `date(valid_from_at)` → use for “as of date” joins, e.g. `dim_account.valid_from_date = dim_date.date_day`.
  - `valid_to_date` = `date(valid_to_at)` (null when `is_current`) → use when filtering or joining on period end.

No expression in the join is required; use the pre-cast date columns.
