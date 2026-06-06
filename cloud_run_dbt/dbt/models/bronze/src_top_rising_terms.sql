with latest_refresh_date as (

    select max(refresh_date) as refresh_date
    from {{ source('google_trends', 'top_rising_terms') }}

),

source as (

    select *
    from {{ source('google_trends', 'top_rising_terms') }}
    where refresh_date = (select refresh_date from latest_refresh_date)

)

select * from source