with source as (
    select *
    from `bigquery-public-data.google_trends.top_rising_terms`
    where refresh_date = "2026-05-13"
    limit 100 -- limit does not impact big-query costs!
)

select * from source