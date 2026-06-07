with source as (

    select
        safe_cast(score as int64) as score,
        cast(rank as int64) as rank,
        cast(refresh_date as date) as refresh_date,
        cast(dma_name as string) as dma_name,
        cast(dma_id as int64) as dma_id,
        cast(term as string) as term,
        cast(week as date) as week
    from {{ source('google_trends', 'top_terms') }}
    where {{ google_trends_snapshot_filter('top_terms') }}
    {{ google_trends_dev_filters('top_terms') }}
)

select * from source