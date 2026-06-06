with actual as (

    select
        case_id,
        col_a,
        col_b,
        {{ hash_columns(['col_a', 'col_b']) }} as row_hash
    from {{ ref('hash_columns_cases') }}

),

assertions as (

    select
        'same inputs should produce one hash' as failure_reason
    from (select 1)
    where (
        select count(distinct row_hash)
        from actual
        where case_id in ('same_1', 'same_2')
    ) != 1

    union all

    select
        'different inputs should produce different hashes' as failure_reason
    from (select 1)
    where (
        select count(distinct row_hash)
        from actual
    ) != 2

)

select *
from assertions