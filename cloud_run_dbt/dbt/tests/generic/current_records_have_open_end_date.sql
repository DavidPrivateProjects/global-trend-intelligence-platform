{% test current_records_have_open_end_date(model) %}

select *
from {{ model }}
where is_current = true
  and valid_to_refresh_date is not null

{% endtest %}