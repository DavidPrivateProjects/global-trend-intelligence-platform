with source_data as (

    select *
    from {{ ref('my_first_dbt_model') }}

)

select *
from source_data
where id = 1
