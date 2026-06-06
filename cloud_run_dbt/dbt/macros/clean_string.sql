{% macro clean_string(column_name) -%}
    nullif(trim(cast({{ column_name }} as string)), '')
{%- endmacro %}