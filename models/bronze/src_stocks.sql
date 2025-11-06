with src as (
    select *
    from {{ source("raw", "stocks") }}
)

select 
    trade_date::date as trade_date, 
    ticker::text as ticker, 
    "open"::double as "open", 
    high::double as high, 
    low::double as low, 
    "close"::double as "close", 
    volume::double as volume, 
    loaded_at::timestamp as loaded_at
from src