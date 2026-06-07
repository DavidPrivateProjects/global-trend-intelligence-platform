{{ config(materialized='table') }}

with terms as (

    select
        search_term,
        search_term_display,
        refresh_date
    from {{ ref('silver_international_top_terms') }}

    union all

    select
        search_term,
        search_term_display,
        refresh_date
    from {{ ref('silver_international_top_rising_terms') }}

    union all

    select
        search_term,
        search_term_display,
        refresh_date
    from {{ ref('silver_us_top_terms') }}

    union all

    select
        search_term,
        search_term_display,
        refresh_date
    from {{ ref('silver_us_top_rising_terms') }}

),

ranked as (

    select
        {{ hash_columns(['search_term']) }} as search_term_key,
        search_term,
        array_agg(search_term_display order by refresh_date desc limit 1)[offset(0)] as search_term_display,
        min(refresh_date) as first_seen_refresh_date,
        max(refresh_date) as last_seen_refresh_date,
        count(*) as trend_signal_count
    from terms
    where search_term is not null
    group by search_term

)

select * from ranked