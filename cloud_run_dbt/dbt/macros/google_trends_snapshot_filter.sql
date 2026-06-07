{% macro google_trends_snapshot_filter(source_table_name, relation_alias=None) -%}
    {%- set env_var_name = 'DBT_' ~ (source_table_name | upper) ~ '_REFRESH_DATE' -%}
    {%- set configured_refresh_date = env_var(env_var_name, '') -%}
    {%- set column_prefix = relation_alias ~ '.' if relation_alias else '' -%}

    {%- if configured_refresh_date -%}
        {{ column_prefix }}refresh_date = date('{{ configured_refresh_date }}')
    {%- else -%}
        {{ column_prefix }}refresh_date = (
            select max(refresh_date)
            from {{ source('google_trends', source_table_name) }}
        )
    {%- endif -%}
{%- endmacro %}