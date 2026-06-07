{{ config(materialized='table') }}

select
    trend_history_key,
    trend_natural_key,
    search_term_key,
    geo_market_key,
    market_scope,
    week_start_date,
    refresh_date,
    search_term,
    search_term_display,
    trend_rank,
    score,
    percent_gain,
    is_current,
    valid_from_refresh_date,
    valid_to_refresh_date
from {{ ref('fact_trend_rank_history') }}
where trend_type = 'rising'