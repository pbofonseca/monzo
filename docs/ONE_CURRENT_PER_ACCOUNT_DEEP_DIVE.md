# One-current-per-account: deep dive

## What was builded

1. **Ran a diagnostic** to see how the 3902 failing accounts broke down by `current_count` (0 vs 2+).
2. **Result:** All 3902 had **current_count = 0**. No accounts had 2+ current rows.
3. **Conclusion:** Every failure was a **closed-only** account (created → closed, never reopened). The test required "exactly one" current row, which is wrong for closed accounts.
4. **Fix:** Relaxed the test to fail only when `current_count > 1` (allow 0 or 1 current row per account).

---

## Mart logic (why 0 vs 2+ happens)

In `dim_account`:

- **Periods** come from `int_account_status_history`: each **created** or **reopened** is a period start; each **closed** is a period end.
- **valid_to** = next close after that start (or null if never closed after that start).
- **is_current** = `(valid_to is null)`.

So:

- **0 current:** Account has only closed periods (e.g. created @ T1, closed @ T2). One row, `valid_to = T2` → `is_current = false`. Valid for closed-only accounts.
- **1 current:** Account has one open period (e.g. created @ T1, no close; or created, closed, reopened @ T3 with no close after T3). One row with `valid_to` null. Correct.
- **2+ current:** Two or more open periods for the same account. Happens when there is a **reopened** event but **no closed** event between **created** and **reopened**. Then both (T1, null) and (T2, null) exist → bug or data issue.

---

## Diagnostics added

| Asset | Purpose |
|-------|--------|
| **`models/marts/_diagnose_one_current_breakdown.sql`** | View: for each `current_count` (0, 2, 3, …), how many accounts. Run with `dbt show --select _diagnose_one_current_breakdown`. |
| **`analyses/diagnose_one_current_breakdown.sql`** | Same logic; compile and run in BigQuery if you prefer. |
| **`analyses/diagnose_one_current_example_history.sql`** | Returns up to 10 accounts with `current_count >= 2`; use one of these to inspect event history if you ever see 2+ current. |

---

## Test change

**Before:** `where current_count != 1` → failed for 0 or 2+.

**After:** `where current_count > 1` → fails only for 2+ (reopened-without-close or similar).

`tests/schema.yml` and the test file comment were updated to describe the new behaviour.
