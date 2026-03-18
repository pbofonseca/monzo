-- SCD Type 2 invariant: no two rows for the same account may have overlapping [valid_from_at, valid_to_at].
-- Also checks valid_from_at < valid_to_at when valid_to_at is not null.
-- See docs/mart-testing-outline.md and dbt docs: https://docs.getdbt.com/docs/build/data-tests

with dim as (
    select
        account_sk,
        account_id_hashed,
        valid_from_at,
        valid_to_at
    from {{ ref('dim_account') }}
),

-- Rows where valid_from_at >= valid_to_at (invalid range when valid_to_at is set)
invalid_range as (
    select account_sk, account_id_hashed, valid_from_at, valid_to_at
    from dim
    where valid_to_at is not null
      and valid_from_at >= valid_to_at
),

-- Pairs of distinct rows for same account with overlapping periods
overlaps as (
    select
        a.account_sk as sk_a,
        b.account_sk as sk_b,
        a.account_id_hashed,
        a.valid_from_at as from_a,
        a.valid_to_at as to_a,
        b.valid_from_at as from_b,
        b.valid_to_at as to_b
    from dim a
    join dim b
        on a.account_id_hashed = b.account_id_hashed
        and a.account_sk < b.account_sk
    where
        (a.valid_to_at is null or a.valid_to_at > b.valid_from_at)
        and (b.valid_to_at is null or b.valid_to_at > a.valid_from_at)
)

select account_sk, account_id_hashed, valid_from_at, valid_to_at from invalid_range
union all
select sk_a, account_id_hashed, from_a, to_a from overlaps
