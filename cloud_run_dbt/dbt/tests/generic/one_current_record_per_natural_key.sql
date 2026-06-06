{% test one_current_record_per_natural_key(model) %}

select
    trend_natural_key
from {{ model }}
where is_current = true
group by trend_natural_key
having count(*) > 1

{% endtest %}