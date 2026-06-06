with actual as (

    {{ deduplicate(
        relation_name=ref('deduplicate_cases'),
        partition_by=['natural_key'],
        order_by=['priority asc']
    ) }}

),

assertions as (

    select
        'expected two deduplicated rows' as failure_reason
    from (select 1)
    where (select count(*) from actual) != 2

    union all

    select
        'expected priority 1 record to survive for natural_key 1' as failure_reason
    from (select 1)
    where exists (
        select 1
        from actual
        where natural_key = 1
          and record_name != 'duplicate_high_priority'
    )

)

select *
from assertions