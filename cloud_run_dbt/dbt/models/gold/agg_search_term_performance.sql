{{ config(materialized='table') }}

with fact as (

    select *
    from {{ ref('fact_trend_rank_history') }}
    where is_current = true

),

aggregated as (

    select
        refresh_date,
        search_term_key,
        any_value(search_term) as search_term,
        any_value(search_term_display) as search_term_display,
        count(*) as trend_signal_count,
        count(distinct geo_market_key) as markets_seen_count,
        count(distinct if(market_scope = 'international', geo_market_key, null)) as international_markets_seen_count,
        count(distinct if(market_scope = 'us_dma', geo_market_key, null)) as us_markets_seen_count,
        countif(trend_type = 'top') as top_appearances,
        countif(trend_type = 'rising') as rising_appearances,
        min(trend_rank) as best_rank,
        avg(trend_rank) as avg_rank,
        max(percent_gain) as max_percent_gain,
        avg(percent_gain) as avg_percent_gain
    from fact
    group by
        refresh_date,
        search_term_key

)

select * from aggregated