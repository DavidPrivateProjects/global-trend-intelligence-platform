{% macro build_scd2_history(
    staged_cte,
    natural_key_columns,
    scd1_columns,
    scd2_columns,
    effective_from_column
) -%}

staged_scd as (

    select
        {{ hash_columns(natural_key_columns) }} as trend_natural_key,
        {{ hash_columns(scd2_columns) }} as scd2_hash,
        {{ hash_columns(natural_key_columns + scd2_columns + [effective_from_column]) }} as trend_history_key,
        {{ effective_from_column }} as valid_from_refresh_date,
        cast(null as date) as valid_to_refresh_date,
        true as is_current,
        current_timestamp() as inserted_at,
        current_timestamp() as updated_at,
        *
    from {{ staged_cte }}

)

{% if is_incremental() %}

, current_records as (

    select *
    from {{ this }}
    where is_current = true

),

scd2_records_to_close as (

    select
        existing.* replace (
            date_sub(staged.valid_from_refresh_date, interval 1 day) as valid_to_refresh_date,
            false as is_current,
            current_timestamp() as updated_at
        )
    from current_records as existing
    inner join staged_scd as staged
        on staged.trend_natural_key = existing.trend_natural_key
    where staged.scd2_hash != existing.scd2_hash

),

scd2_records_to_insert as (

    select staged.*
    from staged_scd as staged
    left join current_records as existing
        on staged.trend_natural_key = existing.trend_natural_key
    where existing.trend_natural_key is null
       or staged.scd2_hash != existing.scd2_hash

),

scd1_records_to_update as (

    select
        staged.* replace (
            existing.trend_history_key as trend_history_key,
            existing.valid_from_refresh_date as valid_from_refresh_date,
            existing.valid_to_refresh_date as valid_to_refresh_date,
            existing.inserted_at as inserted_at,
            current_timestamp() as updated_at
        )
    from staged_scd as staged
    inner join current_records as existing
        on staged.trend_natural_key = existing.trend_natural_key
    where staged.scd2_hash = existing.scd2_hash
      and {{ hash_columns(scd1_columns, 'staged') }} != {{ hash_columns(scd1_columns, 'existing') }}

)

select * from scd2_records_to_close
union all
select * from scd2_records_to_insert
union all
select * from scd1_records_to_update

{% else %}

select * from staged_scd

{% endif %}

{%- endmacro %}