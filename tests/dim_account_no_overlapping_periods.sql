-- SCD Type 2 invariant: no two rows for the same account may have overlapping [valid_from, valid_to].
-- Also checks valid_from < valid_to when valid_to is not null.
-- See docs/MART_TESTING_OUTLINE.md and dbt docs: https://docs.getdbt.com/docs/build/data-tests

with dim as (
    select
        account_sk,
        account_id_hashed,
        valid_from,
        valid_to
    from {{ ref('dim_account') }}
),

-- Rows where valid_from >= valid_to (invalid range when valid_to is set)
invalid_range as (
    select account_sk, account_id_hashed, valid_from, valid_to
    from dim
    where valid_to is not null
      and valid_from >= valid_to
),

-- Pairs of distinct rows for same account with overlapping periods
overlaps as (
    select
        a.account_sk as sk_a,
        b.account_sk as sk_b,
        a.account_id_hashed,
        a.valid_from as from_a,
        a.valid_to as to_a,
        b.valid_from as from_b,
        b.valid_to as to_b
    from dim a
    join dim b
        on a.account_id_hashed = b.account_id_hashed
        and a.account_sk < b.account_sk
    where
        (a.valid_to is null or a.valid_to > b.valid_from)
        and (b.valid_to is null or b.valid_to > a.valid_from)
)

select account_sk, account_id_hashed, valid_from, valid_to from invalid_range
union all
select sk_a, account_id_hashed, from_a, to_a from overlaps
