{% test closed_records_have_end_date(model) %}

select *
from {{ model }}
where is_current = false
  and valid_to_refresh_date is null

{% endtest %}