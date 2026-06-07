with source as (

    select
        cast(week as date) as week,
        safe_cast(score as int64) as score,
        cast(rank as int64) as rank,
        cast(refresh_date as date) as refresh_date,
        cast(country_code as string) as country_code,
        cast(region_code as string) as region_code,
        cast(term as string) as term,
        cast(country_name as string) as country_name,
        cast(region_name as string) as region_name
    from {{ source('google_trends', 'international_top_terms') }}
    where {{ google_trends_snapshot_filter('international_top_terms') }}
    {{ google_trends_dev_filters('international_top_terms') }}
)

select * from source