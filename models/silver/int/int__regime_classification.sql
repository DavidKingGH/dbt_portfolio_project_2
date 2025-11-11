with base as (
    select
        trade_date,
        "close",
        loaded_at,
        version_id,
        version_name,
        complacent_max,
        normal_max,
        elevated_max,
        effective_date
from {{ ref("stg__vix_with_versions")}}
),

final as (
    select
        trade_date, 
        "close", 
        (case 
            when "close" <= complacent_max then 'complacent'
            when "close" > complacent_max and close <= normal_max then 'normal'
            when "close" > normal_max and "close" <= elevated_max then 'elevated'
            when "close" > elevated_max then 'crisis'
        end) as regime, 
        loaded_at
    from base b
)

select
    trade_date::date as trade_date,
    "close"::decimal as "close", 
    regime::text as regime, 
    loaded_at::timestamp as loaded_at
from final
