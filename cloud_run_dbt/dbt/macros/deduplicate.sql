{% macro deduplicate(relation_name, partition_by, order_by) -%}
    select *
    from {{ relation_name }}
    qualify row_number() over (
        partition by
            {{ partition_by | join(', ') }}
        order by
            {{ order_by | join(', ') }}
    ) = 1
{%- endmacro %}