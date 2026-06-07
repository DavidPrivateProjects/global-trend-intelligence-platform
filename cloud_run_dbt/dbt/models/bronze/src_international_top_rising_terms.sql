with source as (

    select
        cast(region_name as string) as region_name,
        cast(region_code as string) as region_code,
        cast(term as string) as term,
        cast(week as date) as week,
        safe_cast(score as int64) as score,
        safe_cast(percent_gain as int64) as percent_gain,
        cast(country_name as string) as country_name,
        cast(country_code as string) as country_code,
        cast(rank as int64) as rank,
        cast(refresh_date as date) as refresh_date
    from {{ source('google_trends', 'international_top_rising_terms') }}
    where {{ google_trends_snapshot_filter('international_top_rising_terms') }}
    {{ google_trends_dev_filters('international_top_rising_terms') }}
)

select * from source