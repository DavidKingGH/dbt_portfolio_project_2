with RECURSIVE wilder as (
    -- seed row: first complete window per ticker
    select
        r.ticker,
        r.rn,
        r.trade_date,
        r.gain,
        r.loss,
        r.sma_gain as wilder_gain,
        r.sma_loss as wilder_loss
    from {{ ref("int__rsi_sma") }} r
    where r.rn = 14

    union all

    -- recursive step: carry previous wilder_* forward
    select
        nxt.ticker,
        nxt.rn,
        nxt.trade_date,
        nxt.gain,
        nxt.loss,
        (prev.wilder_gain * 13 + nxt.gain) / 14.0 as wilder_gain,
        (prev.wilder_loss * 13 + nxt.loss) / 14.0 as wilder_loss
    from {{ ref("int__rsi_sma") }} nxt
    join wilder prev
      on nxt.ticker = prev.ticker
     and nxt.rn = prev.rn + 1
)

select
    ticker::text as ticker,
    rn::int as rn,
    trade_date::date as trade_date,
    gain::decimal(18,2) as gain,
    loss::decimal(18,2) as loss,
    wilder_gain::decimal(18,2) as wilder_gain,
    wilder_loss::decimal(18,2) as wilder_loss
from wilder