with src as (
    select *
    from {{source("raw", "vix")}}
)

select
    trade_date::date as trade_date, 
    "close"::double as "close", 
    loaded_at::timestamp as loaded_at
from src