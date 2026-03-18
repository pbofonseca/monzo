# One-current-per-account: deep dive

## What was builded

`dim_account` must **never show overlapping open periods for a single account**. At any point in time an account can be either closed (no current row) or open (exactly one current row), **but never open twice**. Formally: for each account_id_hashed, current_count <= 1, where current_count is the number of rows in dim_account with is_current = true.

---

## Mart logic (why 0 vs 2+ happens)

In `dim_account`:

- **Periods** come from `int_account_status_history`: each **created** or **reopened** is a period start; each **closed** is a period end.
- **valid_to_at** = next close after that start (or null if never closed after that start).
- **is_current** = `(valid_to_at is null)`.

So:

- **Valid closed-only accounts**: `current_count = 0` (account was opened and later closed, never reopened after final close).
- **Valid open accounts**: `current_count = 1` (account has a single open period with no closing event after the last open).
- **Invalid / data issue**: `current_count > 1` (multiple open periods overlap, typically a reopened without an intervening closed).

---

## Diagnostics added

| Asset | Purpose |
|-------|--------|
| **`analyses/diagnostics/diagnose_dim_account_current_breakdown.sql`** | View: for each `current_count` (0, 2, 3, …), how many accounts. Run with `dbt show --select diagnose_dim_account_current_breakdown`. |
| **`analyses/diagnose_one_current_breakdown.sql`** | Same logic; compile and run in BigQuery if you prefer. |
