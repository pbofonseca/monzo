-- Business rule: account status lifecycle must be 1-created, then 2-closed, 3-reopened.
-- After reopened, an account can be closed again. There must be exactly one 'created' per account.
-- This test fails if: (a) any account has != 1 'created' event, or (b) the first event (by event_ts) is not 'created'.

with history as (
    select
        account_id_hashed,
        event_ts,
        account_status
    from {{ ref('int_account_status_history') }}
),

-- Fail when an account does not have exactly one 'created' event
created_count_violations as (
    select
        account_id_hashed,
        cast(countif(account_status = 'created') as string) as violation_type
    from history
    group by account_id_hashed
    having countif(account_status = 'created') != 1
),

-- Fail when the first event (by event_ts) per account is not 'created'
first_event_not_created as (
    select
        account_id_hashed,
        'first_event_not_created' as violation_type
    from (
        select
            account_id_hashed,
            account_status,
            row_number() over (partition by account_id_hashed order by event_ts) as rn
        from history
    )
    where rn = 1 and account_status != 'created'
)

select account_id_hashed, violation_type from created_count_violations
union all
select account_id_hashed, violation_type from first_event_not_created
