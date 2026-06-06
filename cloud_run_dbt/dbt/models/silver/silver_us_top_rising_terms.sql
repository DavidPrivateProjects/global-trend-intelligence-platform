{{ config(
    materialized='incremental',
    unique_key='trend_history_key',
    incremental_strategy='merge',
    partition_by={
        "field": "refresh_date",
        "data_type": "date"
    },
    cluster_by=["trend_natural_key", "search_term"],
    on_schema_change='fail'
) }}

with source as (

    select *
    from {{ ref('src_top_rising_terms') }}

),

cleaned as (

    select
        cast(week as date) as week_start_date,
        cast(refresh_date as date) as refresh_date,
        cast(dma_id as int64) as us_market_id,
        {{ clean_string('dma_name') }} as us_market_name,
        lower({{ clean_string('term') }}) as search_term,
        {{ clean_string('term') }} as search_term_display,
        cast(rank as int64) as trend_rank,
        safe_cast(score as int64) as score,
        safe_cast(percent_gain as int64) as percent_gain
    from source
    where {{ clean_string('term') }} is not null
      and week is not null
      and refresh_date is not null
      and dma_id is not null

),

deduplicated as (

    {{ deduplicate(
        relation_name='cleaned',
        partition_by=[
            'refresh_date',
            'week_start_date',
            'us_market_id',
            'search_term'
        ],
        order_by=[
            'trend_rank asc'
        ]
    ) }}

),

{{ build_scd2_history(
    staged_cte='deduplicated',
    natural_key_columns=[
        'week_start_date',
        'us_market_id',
        'search_term'
    ],
    scd1_columns=[
        'us_market_name',
        'search_term_display'
    ],
    scd2_columns=[
        'trend_rank',
        'score',
        'percent_gain'
    ],
    effective_from_column='refresh_date'
) }}