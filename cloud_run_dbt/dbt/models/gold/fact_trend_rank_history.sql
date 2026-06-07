{{ config(materialized='table') }}

with international_top as (

    select
        trend_history_key,
        trend_natural_key,
        {{ hash_columns(['search_term']) }} as search_term_key,
        {{ hash_columns([
            "'international'",
            'country_code',
            'region_code'
        ]) }} as geo_market_key,
        'top' as trend_type,
        'international' as market_scope,
        week_start_date,
        refresh_date,
        search_term,
        search_term_display,
        trend_rank,
        score,
        cast(null as int64) as percent_gain,
        valid_from_refresh_date,
        valid_to_refresh_date,
        is_current
    from {{ ref('silver_international_top_terms') }}

),

international_rising as (

    select
        trend_history_key,
        trend_natural_key,
        {{ hash_columns(['search_term']) }} as search_term_key,
        {{ hash_columns([
            "'international'",
            'country_code',
            'region_code'
        ]) }} as geo_market_key,
        'rising' as trend_type,
        'international' as market_scope,
        week_start_date,
        refresh_date,
        search_term,
        search_term_display,
        trend_rank,
        score,
        percent_gain,
        valid_from_refresh_date,
        valid_to_refresh_date,
        is_current
    from {{ ref('silver_international_top_rising_terms') }}

),

us_top as (

    select
        trend_history_key,
        trend_natural_key,
        {{ hash_columns(['search_term']) }} as search_term_key,
        {{ hash_columns([
            "'us_dma'",
            'us_market_id'
        ]) }} as geo_market_key,
        'top' as trend_type,
        'us_dma' as market_scope,
        week_start_date,
        refresh_date,
        search_term,
        search_term_display,
        trend_rank,
        score,
        cast(null as int64) as percent_gain,
        valid_from_refresh_date,
        valid_to_refresh_date,
        is_current
    from {{ ref('silver_us_top_terms') }}

),

us_rising as (

    select
        trend_history_key,
        trend_natural_key,
        {{ hash_columns(['search_term']) }} as search_term_key,
        {{ hash_columns([
            "'us_dma'",
            'us_market_id'
        ]) }} as geo_market_key,
        'rising' as trend_type,
        'us_dma' as market_scope,
        week_start_date,
        refresh_date,
        search_term,
        search_term_display,
        trend_rank,
        score,
        percent_gain,
        valid_from_refresh_date,
        valid_to_refresh_date,
        is_current
    from {{ ref('silver_us_top_rising_terms') }}

)

select * from international_top
union all
select * from international_rising
union all
select * from us_top
union all
select * from us_rising