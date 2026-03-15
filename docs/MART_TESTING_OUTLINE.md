# Mart testing outline: five high-impact tests

This document outlines five tests to implement for the mart layer (`dim_account`, built from `int_account_status_history`) to build confidence in the output **when upstream tables change and source data is not validated with contracts**.

References:
- **dbt data tests**: [Add data tests to your DAG](https://docs.getdbt.com/docs/build/data-tests) — generic tests (`unique`, `not_null`, `accepted_values`, `relationships`) and singular tests (SQL that returns failing rows).
- **Great Expectations / dbt-expectations**: [dbt-expectations](https://hub.getdbt.com/calogica/dbt_expectations/latest/) ports GX-style expectations into dbt (e.g. row count comparisons, value ranges). [GX + dbt tutorial](https://docs.greatexpectations.io/docs/reference/learn/integrations/dbt_tutorial/).

---

## 1. Primary key uniqueness and not-null (surrogate key)

**Why it matters**  
Upstream schema or join logic changes can introduce duplicate dimension rows or null keys. This test ensures the mart’s primary key is a valid, unique identifier.

**What to test**
- `account_sk` is **unique** and **not_null**.

**Implementation**
- dbt generic tests: `unique` and `not_null` on `dim_account.account_sk`.
- GX analogue: `expect_column_values_to_be_unique`, `expect_column_values_to_not_be_null`.

**How to run**
```bash
dbt test --select dim_account --grep "unique|not_null"
# or run all dim_account tests:
dbt test --select dim_account
```

**dbt reference**: [Generic data tests](https://docs.getdbt.com/docs/build/data-tests#generic-data-tests), [unique / not_null](https://docs.getdbt.com/reference/resource-properties/data-tests).

---

## 2. Row count / reconciliation with upstream

**Why it matters**  
Upstream changes (new columns, filters, or table swaps) can drop or duplicate “periods”. A reconciliation test catches missing or extra rows even when the schema still looks correct.

**What to test**
- Row count (or count per key) of `dim_account` matches the expected number of active periods derived from `int_account_status_history` (e.g. one row per `(account_id_hashed, valid_from_at)` from the intermediate logic).

**Implementation**
- dbt-expectations macro `expect_table_row_count_to_equal_other_table` comparing `dim_account` to model `_expected_dim_account_periods` (one row per period from `int_account_status_history`). See `_marts__models.yml` and `models/marts/_expected_dim_account_periods.sql`.

**How to run**
```bash
# Ensure the compare model exists (e.g. run marts first)
dbt run --select _expected_dim_account_periods
dbt test --select dim_account --grep "expect_table_row_count_to_equal_other_table"
# or run all dim_account tests:
dbt test --select dim_account
```

**GX analogue**: `expect_table_row_count_to_equal`, `expect_table_row_count_to_equal_other_table`.

---

## 3. SCD Type 2 invariants (one current row, no overlaps)

**Why it matters**  
The mart is SCD Type 2. Bugs or upstream changes can break invariants: multiple current rows per account, overlapping validity windows, or invalid `valid_from_at`/`valid_to_at` ordering.

**What to test**
- For each `account_id_hashed`, exactly one row has `is_current = true`.
- For each account, no two rows have overlapping `[valid_from_at, valid_to_at]` (and `valid_from_at < valid_to_at` when `valid_to_at` is not null).

**Implementation**
- Singular data test(s): SQL that returns any row/account where (a) `count(*) where is_current` ≠ 1 per account, or (b) overlaps exist (e.g. self-join on `account_id_hashed` with overlapping intervals).

**How to run**
```bash
dbt test --select dim_account_one_current_per_account dim_account_no_overlapping_periods
# or run all dim_account tests:
dbt test --select dim_account
```

**GX analogue**: Custom expectations or `expect_compound_columns_to_be_unique` for (account_id_hashed, valid_from_at); plus custom logic for “one current per account” and no overlaps.

---

## 4. Referential consistency with the intermediate layer

**Why it matters**  
If the intermediate model’s grain or filters change, the mart might reference accounts or events that no longer exist, or miss accounts that should be present. This keeps the mart aligned with the single source of truth (intermediate).

**What to test**
- Every `account_id_hashed` in `dim_account` exists in `int_account_status_history` and has exactly one `created` event (already enforced on the intermediate model).
- Optionally: every account that has at least one “start” (created or reopened) in the intermediate appears in `dim_account` (no missing accounts).

**Implementation**
- dbt generic test: `relationships` from `dim_account.account_id_hashed` to a model that represents the set of valid account IDs (e.g. `select distinct account_id_hashed from int_account_status_history where account_status = 'created'`). If you don’t have that as a model, use a singular test that left-joins `dim_account` to the intermediate and returns rows where the join fails.
- GX analogue: `expect_column_values_to_be_in_set` (values in mart column must be in the list from the other table).

**How to run**
```bash
dbt test --select dim_account --grep "relationships"
# or run all dim_account tests:
dbt test --select dim_account
```

**dbt reference**: [relationships](https://docs.getdbt.com/reference/resource-properties/data-tests).

---

## 5. Domain / accepted values for critical attributes

**Why it matters**  
Upstream systems can add new enum values (e.g. new `account_type`). Without contracts on sources, those values will flow into the mart and can break reports or downstream logic. This test fails when unexpected values appear.

**What to test**
- `account_type` (and any other status/type columns) only contain values from an agreed list (e.g. from a seed or a fixed list).
- `is_current` is strictly boolean (if stored as non-boolean type, still only true/false).

**Implementation**
- dbt generic test: `accepted_values` on `dim_account.account_type` (and similar columns) with the canonical list. Keep the list in one place (e.g. seed or var) so it’s easy to update when the domain intentionally changes.
- GX analogue: `expect_column_values_to_be_in_set`.

**How to run**
```bash
dbt test --select dim_account --grep "accepted_values"
# or run all dim_account tests:
dbt test --select dim_account
```

**dbt reference**: [accepted_values](https://docs.getdbt.com/reference/resource-properties/data-tests).

---

## Summary

| # | Test focus              | Protects against              | Main implementation              |
|---|--------------------------|-------------------------------|----------------------------------|
| 1 | PK unique & not null     | Duplicate/null surrogate keys | dbt `unique`, `not_null`         |
| 2 | Row count reconciliation| Upstream drops/duplicates      | **dbt-expectations** `expect_table_row_count_to_equal_other_table` (recommended; implemented) |
| 3 | SCD Type 2 invariants   | Multiple current / overlaps   | Singular test(s)                  |
| 4 | Referential consistency | Orphan / missing accounts     | dbt `relationships` or singular  |
| 5 | Accepted values         | New enum values from upstream | dbt `accepted_values`            |

With these in place, you get confidence that the mart’s grain, keys, and domain stay correct as upstream tables and source data evolve.

---

## Implementation in this project

- **Package**: [metaplane/dbt_expectations](https://hub.getdbt.com/metaplane/dbt_expectations/latest/) (maintained fork) is in `packages.yml`. Run `dbt deps` so row-count and other GX-style tests are available.

- **Test 1 (PK)**: Generic tests in `_marts__models.yml` on `dim_account`: `unique` and `not_null` on `account_sk`.

- **Test 2 (Row count — recommended)**: dbt-expectations macro `expect_table_row_count_to_equal_other_table` on `dim_account` with `compare_model: ref('_expected_dim_account_periods')`. The model `_expected_dim_account_periods` (view) computes the expected period count from `int_account_status_history` (one row per created/reopened). Build it before testing: `dbt run --select _expected_dim_account_periods` (or run all marts).

- **Test 3 (SCD Type 2)**: Singular tests in `tests/`: `dim_account_one_current_per_account.sql` (at most one current row per account), `dim_account_no_overlapping_periods.sql` (no overlapping validity periods). Descriptions in `tests/schema.yml`.

- **Test 4 (Referential)**: Generic test `relationships` from `dim_account.account_id_hashed` to `ref('int_account_status_history')` in `_marts__models.yml`.

- **Test 5 (Accepted values)**: Generic test `accepted_values` on `dim_account.account_type` in `_marts__models.yml`. Update the values list to match your domain (e.g. `uk_retail_pot`, `uk_retail`, `uk_retail_joint`).
