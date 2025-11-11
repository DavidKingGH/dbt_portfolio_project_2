with base as (
    select *
    from {{ ref("src_stocks") }}
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
from base
where 1=1

-- remove closed trading days
    and "close" is not null

-- assert prices greater than zero
    and "open" > 0
    and high > 0
    and low > 0
    and "close" > 0
    and volume >= 0

-- assert prices reasonable
    and "close" between low and high
    and "open" between low and high

-- assert no future dates
    and trade_date <= current_date
    and loaded_at <= current_timestamp
