with source as (
    select *
    from `bigquery-public-data.google_trends.international_top_terms`
    where refresh_date = "2026-05-13"
    limit 100
)

select * from source