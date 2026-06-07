{{ config(materialized='table') }}

with international_markets as (

    select distinct
        {{ hash_columns([
            "'international'",
            'country_code',
            'region_code'
        ]) }} as geo_market_key,
        'international' as market_scope,
        country_code,
        country_name,
        region_code,
        region_name,
        cast(null as int64) as us_market_id,
        cast(null as string) as us_market_name,
        concat(country_name, ' - ', region_name) as market_display_name
    from {{ ref('silver_international_top_terms') }}
    where country_code is not null
      and region_code is not null

    union distinct

    select distinct
        {{ hash_columns([
            "'international'",
            'country_code',
            'region_code'
        ]) }} as geo_market_key,
        'international' as market_scope,
        country_code,
        country_name,
        region_code,
        region_name,
        cast(null as int64) as us_market_id,
        cast(null as string) as us_market_name,
        concat(country_name, ' - ', region_name) as market_display_name
    from {{ ref('silver_international_top_rising_terms') }}
    where country_code is not null
      and region_code is not null

),

us_markets as (

    select distinct
        {{ hash_columns([
            "'us_dma'",
            'us_market_id'
        ]) }} as geo_market_key,
        'us_dma' as market_scope,
        'US' as country_code,
        'United States' as country_name,
        cast(null as string) as region_code,
        cast(null as string) as region_name,
        us_market_id,
        us_market_name,
        us_market_name as market_display_name
    from {{ ref('silver_us_top_terms') }}
    where us_market_id is not null

    union distinct

    select distinct
        {{ hash_columns([
            "'us_dma'",
            'us_market_id'
        ]) }} as geo_market_key,
        'us_dma' as market_scope,
        'US' as country_code,
        'United States' as country_name,
        cast(null as string) as region_code,
        cast(null as string) as region_name,
        us_market_id,
        us_market_name,
        us_market_name as market_display_name
    from {{ ref('silver_us_top_rising_terms') }}
    where us_market_id is not null

)

select * from international_markets
union distinct
select * from us_markets