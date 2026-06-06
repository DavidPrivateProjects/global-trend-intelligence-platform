{% macro hash_columns(columns, relation_alias=None) -%}
to_hex(md5(concat(
    {%- for column in columns %}
        coalesce(cast({% if relation_alias %}{{ relation_alias }}.{% endif %}{{ column }} as string), '')
        {%- if not loop.last %}, '|', {% endif -%}
    {%- endfor %}
)))
{%- endmacro %}