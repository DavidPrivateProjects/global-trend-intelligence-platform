{% macro google_trends_dev_filters(source_table_name) -%}
    {%- set country_codes = env_var('DBT_DEV_COUNTRY_CODES', '') -%}
    {%- set us_market_ids = env_var('DBT_DEV_US_MARKET_IDS', '') -%}

    {%- if source_table_name in ['international_top_terms', 'international_top_rising_terms'] and country_codes -%}
        and country_code in (
            {%- for country_code in country_codes.split(',') -%}
                '{{ country_code.strip().upper() }}'
                {%- if not loop.last -%}, {% endif -%}
            {%- endfor -%}
        )
    {%- endif -%}

    {%- if source_table_name in ['top_terms', 'top_rising_terms'] and us_market_ids -%}
        and cast(dma_id as string) in (
            {%- for us_market_id in us_market_ids.split(',') -%}
                '{{ us_market_id.strip() }}'
                {%- if not loop.last -%}, {% endif -%}
            {%- endfor -%}
        )
    {%- endif -%}
{%- endmacro %}