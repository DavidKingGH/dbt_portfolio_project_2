-- asserts the seed matches SMA at rn=14
with w as (
  select ticker, trade_date, wilder_gain, wilder_loss
  from {{ ref('int__rsi_wilder') }}
  where rn = 14
),
s as (
  select ticker, trade_date, sma_gain, sma_loss
  from {{ ref('int__rsi_sma') }}
  where rn = 14
)
select
  w.ticker,
  w.trade_date
from w
join s using (ticker, trade_date)
where abs(w.wilder_gain - s.sma_gain) > 1e-9
   or abs(w.wilder_loss - s.sma_loss) > 1e-9
