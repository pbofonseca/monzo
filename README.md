## About me

Hi! I’m [Pablo Stéfano](https://www.linkedin.com/in/pbostefano/) :)
I’m originally from Minas Gerais, but I currently live in Florianópolis (you should Google it. It’s amazing!).
I’m also Alberto’s proud tutor 🐶

In the next sections, I’ll walk you through Monzo’s take-home test

## Repository Structure

This project follows a layered architecture:

- `sources/`: raw data definitions
- `staging/`: cleaned and standardized tables
- `intermediate/`: business logic transformations
- `marts/`: final analytical models

```
monzo/
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── stg_accounts_created.sql
│   │   ├── stg_accounts_closed.sql
│   │   ├── stg_accounts_reopened.sql
│   │   ├── stg_accounts_transactions.sql
│   │   └── _staging__models.yml
│   ├── intermediate/
│   │   ├── int_account_status_history.sql
│   │   ├── int_user_activity_daily.sql
│   │   ├── int_open_users_daily.sql
│   │   └── test_support/
│   │       └── expected_dim_account_periods.sql
│   ├── marts/
│   │   ├── dim/
│   │   │   ├── dim_account.sql
│   │   │   ├── dim_date.sql
│   │   │   └── _dim__models.yml
│   │   ├── fct/
│   │   │   ├── fct_user_metrics_daily.sql
│   │   │   └── fct_user_metrics_daily.yml
│   │   └── _marts__models.yml
├── tests/
│   ├── dim_account_one_current_per_account.sql
│   └── dim_account_no_overlapping_periods.sql
├── analyses/
│   ├── diagnose_one_current_breakdown.sql
│   └── diagnose_one_current_example_history.sql
├── docs/
│   ├── FAILED_TESTS_WALKTHROUGH
│   └── sources-layer.md
├── dbt_project.yml
├── packages.yml
├── README.md
└── .gitignore
```

---

## Introduction

This project implements two data models based on the `monzo_datawarehouse` dataset:

1. A reliable and complete account dimension (`dim_account`)
2. A daily fact table to compute user activity (`fct_user_metrics_daily`)

The goal is to provide models that are:

- Accurate and deterministic
- Easy to understand and use
- Robust to upstream data issues
- Efficient to run at scale

Throughout the project, I prioritized clear logic, explicit assumptions, data reliability, and deterministic approaches.

---

## Data Sources

The project is based on four raw tables:

- `account_created`
- `account_closed`
- `account_reopened`
- `account_transactions`

These tables are append-only logs refreshed daily and may change over time.

All sources are declared in the `sources` layer and include basic data quality tests such as `not_null` checks.

---

## Assumptions

Since the source data is not validated and may evolve, I made the following assumptions:

- Account lifecycle events (`created`, `closed`, `reopened` statuses) define state transitions.
- Accounts may be reopened multiple times but must not have overlapping active periods.
  - Each account must have a single `created` event and alternate between `closed` and `reopened` states.
  - The `event_ts` timestamp defines the event order and must reflect the correct sequence of state transitions.
- A user is considered "eligible" if they have at least one open account on a given day.
- Users with only closed accounts are excluded from the metric (only `closed` events).
- Transaction activity is recorded at the account level and must be aggregated to the user level.
- Late-arriving data must be accounted for in the incremental design.

These assumptions are enforced through modelling logic and tests where possible.

---

## Task 1: Accounts Model

### Overview

The `dim_account` model represents the full lifecycle of accounts using a Type 2 Slowly Changing Dimension (SCD).

Each row corresponds to a period where an account is in a specific state.

### Key Features

- Tracks account lifecycle over time
- Prevents overlapping validity periods
- Identifies the current state of each account
- Handles reopened accounts correctly

### Grain

(account_id_hashed, valid_from_at)

### Why this design?

The source data is event-based, so I transformed it into a period-based model to:

- Make temporal analysis easier
- Ensure consistency in downstream models
- Avoid ambiguous interpretations of account state

---

### Data Quality Tests (Task 1)

To ensure reliability, I implemented the following key tests:

1. One `created` event per account (ensures valid lifecycle start)
2. No overlapping account periods
3. At most one current record per account
4. Accepted values for `account_type` (aligned with source domain)
  4.1. If the source does not provide a value, `account_type` defaults to not_informed
5. Row count consistency between expected and generated periods

Additionally, diagnostic models were created to investigate failures and support debugging.

---

## Task 2: 7-day Active Users

### Definition

7-day active rate:

seven_day_active_rate =
seven_day_active_users / users_with_open_account

Where:

- Numerator: users with at least one transaction in the last 7 days
- Denominator: users with at least one open account on that day

---

### Model Design

The solution is composed of:

- `int_user_activity_daily` : user-level daily activity. Also used as an incremental boundary is defined by this source data, not downstream tables. This prevents propagating corrupted state and ensures deterministic results.
- `int_open_users_daily`: users with open accounts per day. Defines the eligible population. Stateless and deterministic, using a bounded time window to generate recent partitions only.
- `fct_user_metrics_daily`: final aggregated metrics. Uses incremental logic with repair window to recomputes last 14 days. Ensures correct handling of rolling window, protection against late-arriving data, and stable historical results.

### Grain

(date_day)

### Design Decisions

- Aggregation is done at user level (not account level) to avoid double counting
- A rolling 7-day window is computed using a date-driven join
- The denominator is precomputed to ensure consistency and reuse

---

## Incremental Strategy

The fact table is implemented as an incremental model with a repair window. The design was one of the most critical and challenging parts of this project.
The final solution reflects multiple iterations to balance correctness, determinism, and cost efficiency.

### Problem 1: Rolling window dependency

The 7-day metric depends on a rolling window, meaning:

- Activity on a given day affects the following 6 days
- Late-arriving data can affect previously computed metrics

### Problem 2: Partition explosion in intermediate models

The `int_open_users_daily` model expands SCD ranges into daily rows using `generate_date_array`.

A naive implementation caused:

- Full history expansion on every run
- Thousands of partitions rewritten

BigQuery quota errors:

`Quota exceeded: Number of partition modifications`

### Attempted approaches

1. Full rebuild (table materialization):

- Simple but not scalable
- Failed due to partition limits

1. Filtering input rows

- Tried limiting accounts using:
  - valid_to_date >= max(date_day)
  - Result:
    - Still expanded full historical ranges
    - Did not reduce partition writes

1. Using {{ this }} in intermediate model

- Used previous state to define incremental boundary.
  - Issues:
    - Introduced state dependency
    - Broke determinism
    - Made debugging harder
    - Still did not solve partition explosion

### Final solution (adopted)

- Recompute the last 14 days on each run
- This window is larger than the 7-day metric window to capture late events
- Data before the repair window is never modified

### Important Detail

The incremental boundary is based on source data (`int_user_activity_daily`), not the target table.

This ensures:

- Deterministic results
- Protection against corrupted historical data
- Stable and reproducible metrics

### Outcome

- Constant-cost pipeline
- Correct handling of late-arriving data
- No full refresh required after initial build

---

## Data Quality (Task 2)

The following validations were implemented:

- Unique constraint on `date_day`
- Not null constraints on key metrics
- Metric bounds validation (0 ≤ rate ≤ 1)
- Logical validation: active users ≤ eligible users

These tests ensure both technical correctness and business consistency.

---

## Performance Considerations

- Partitioned by `date_day`
- Clustered by `date_day`
- Incremental processing with bounded repair window

This ensures:

- Efficient scans in BigQuery
- Predictable cost over time
- Scalability as data grows

---

## How to Run

Install dependencies:

`dbt deps`

Run full build:

`dbt build`

Run specific model:

`dbt build --select fct_user_metrics_daily`

Run tests:

`dbt test`

---

## Conclusion

This project focuses on building reliable and intuitive data models rather than just producing outputs.

Key priorities were:

- Determinism: results should always be reproducible
- Clarity: models should be easy to understand and use
- Robustness: models should handle imperfect and evolving data
- Scalability: pipelines should remain efficient over time

**Incremental modeling is not just about filtering data. It requires an understanding of how transformations can expand row counts and affect execution performance at scale. Failing to anticipate these expansion patterns can lead to inefficient queries and unexpected compute costs. Cross joins in BigQuery do not imply efficiency.**

The goal was to reflect how data models are built and maintained in a real production environment. The final design incorporates trade-offs to ensure correctness while respecting system constraints, similar to what is required in production.

---

## References

[Monzo article: Mapping our data journey with column lineage](https://medium.com/data-monzo/mapping-our-data-journey-with-column-lineage-56209c00606d)
[Monzo article: The many layers of data lineage](https://medium.com/data-monzo/the-many-layers-of-data-lineage-2eb898709ad3)
[Monzo article: An introduction to Monzo’s data stack](https://medium.com/data-monzo/an-introduction-to-monzos-data-stack-827ae531bc99)
[Monzo article: How we use incremental modelling to handle billions of events every day](https://monzo.com/blog/how-we-use-incremental-modelling-to-handle-billions-of-events-every-day)
[dbt documents: Add snapshot to your DAG](https://docs.getdbt.com/docs/build/snapshots?version=1.12)
[dbt documents: How we style our dbt models](https://docs.getdbt.com/best-practices/how-we-style/1-how-we-style-our-dbt-models?version=1.12)
[dbt documents: Add data tests to your DAG](https://docs.getdbt.com/docs/build/data-tests)
[dbt documents: dbt-expectations](https://hub.getdbt.com/calogica/dbt_expectations/latest/)
[dbt documents: Generic data tests](https://docs.getdbt.com/docs/build/data-tests#generic-data-tests)
[dbt documents: unique / not_null](https://docs.getdbt.com/reference/resource-properties/data-tests)
[greatexpectations documents: GX + dbt tutorial](https://docs.greatexpectations.io/docs/reference/learn/integrations/dbt_tutorial/)

---

## Next steps

- Improve SCD Type 2 dimensions using dbt snapshots
- Create `dim_user`
- Convert `fct_user_metrics_daily` to an aggregate model
- Replace all foreign keys (FKs) in the mart model with surrogate keys (SKs)
- Reevaluate `int_account_status_history`
- Set up `DEV` and `PROD` environments
- Add common Bash commands to scripts/
- Expand Great Expectations coverage
- Improve lineage

