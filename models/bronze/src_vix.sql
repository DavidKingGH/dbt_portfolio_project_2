with src as (
    select *
    from {{source("raw", "vix")}}
)

select
    trade_date::date as trade_date, 
    "close"::double as "close"
from src