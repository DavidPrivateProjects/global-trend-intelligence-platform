with source as (

    select
        cast(refresh_date as date) as refresh_date,
        cast(dma_name as string) as dma_name,
        cast(dma_id as int64) as dma_id,
        cast(term as string) as term,
        cast(week as date) as week,
        safe_cast(score as int64) as score,
        cast(rank as int64) as rank,
        safe_cast(percent_gain as int64) as percent_gain
    from {{ source('google_trends', 'top_rising_terms') }}
    where {{ google_trends_snapshot_filter('top_rising_terms') }}
    {{ google_trends_dev_filters('top_rising_terms') }}
)

select * from source