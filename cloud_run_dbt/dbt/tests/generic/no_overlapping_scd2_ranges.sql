{% test no_overlapping_scd2_ranges(model) %}

with ordered_history as (

    select
        trend_natural_key,
        valid_from_refresh_date,
        coalesce(valid_to_refresh_date, date '9999-12-31') as valid_to_refresh_date,
        lead(valid_from_refresh_date) over (
            partition by trend_natural_key
            order by valid_from_refresh_date
        ) as next_valid_from_refresh_date
    from {{ model }}

),

invalid_ranges as (

    select *
    from ordered_history
    where next_valid_from_refresh_date is not null
      and valid_to_refresh_date >= next_valid_from_refresh_date

)

select *
from invalid_ranges

{% endtest %}