with base as (
select
    trade_date,
    ticker,
    "close",
    delta,
    gain,
    loss,
    rn,
    period_check,
    loaded_at
from {{ ref("int__price_changes")}}
),

rsi_sma as (
    select
        trade_date,
        ticker,
        "close",
        delta,
        gain,
        loss,
        avg(gain) over(
            partition by ticker 
            order by trade_date asc, loaded_at asc 
            rows between 13 preceding and current row) as sma_gain,
        avg(loss) over(
            partition by ticker 
            order by trade_date asc, loaded_at asc
            rows between 13 preceding and current row) as sma_loss,
        rn,
        loaded_at,
        period_check
    from base
)


select
    trade_date::date as trade_date,
    ticker::text as ticker,
    "close"::decimal(18,2) as "close",
    delta::decimal(18,2) as delta,
    gain::decimal(18,2) as gain,
    loss::decimal(18,2) as loss,
    sma_gain::decimal(18,2) as sma_gain,
    sma_loss::decimal(18,2) as sma_loss,
    rn::int as rn,
    loaded_at::timestamp as loaded_at,
    period_check::int as period_check
from rsi_sma
