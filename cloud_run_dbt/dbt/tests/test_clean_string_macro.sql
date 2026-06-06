with actual as (

    select
        case_id,
        raw_value,
        expected_value,
        {{ clean_string('raw_value') }} as cleaned_value
    from {{ ref('clean_string_cases') }}

)

select *
from actual
where coalesce(cleaned_value, '__dbt_null__') != coalesce(expected_value, '__dbt_null__')