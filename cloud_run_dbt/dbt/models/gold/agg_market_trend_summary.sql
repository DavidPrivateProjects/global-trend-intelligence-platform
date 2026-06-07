{{ config(materialized='table') }}

with fact as (

    select *
    from {{ ref('fact_trend_rank_history') }}
    where is_current = true

),

aggregated as (

    select
        refresh_date,
        geo_market_key,
        market_scope,
        count(*) as trend_signal_count,
        count(distinct search_term_key) as unique_search_terms,
        countif(trend_type = 'top') as top_terms_count,
        countif(trend_type = 'rising') as rising_terms_count,
        min(trend_rank) as best_rank,
        avg(trend_rank) as avg_rank,
        max(percent_gain) as max_percent_gain,
        avg(percent_gain) as avg_percent_gain
    from fact
    group by
        refresh_date,
        geo_market_key,
        market_scope

)

select * from aggregated