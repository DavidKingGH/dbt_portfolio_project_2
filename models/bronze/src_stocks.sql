with src as (
    select *
    from {{ source("raw", "stocks") }}
)

select 
    trade_date::date as trade_date, 
    ticker::text as ticker, 
    "open"::decimal(18,2) as "open", 
    high::decimal(18,2) as high, 
    low::decimal(18,2) as low, 
    "close"::decimal(18,2) as "close", 
    volume::decimal(18,2) as volume, 
    loaded_at::timestamp as loaded_at
from src
