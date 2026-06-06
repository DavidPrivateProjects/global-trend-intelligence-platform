{% test valid_scd2_date_ranges(model) %}

select *
from {{ model }}
where valid_to_refresh_date is not null
  and valid_to_refresh_date < valid_from_refresh_date

{% endtest %}