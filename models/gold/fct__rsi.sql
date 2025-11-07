with sma as (
select
    trade_date,
    ticker,
    gain,
    loss,
    sma_gain,
    sma_loss, 
    period_check
from {{ ref('int__rsi_sma') }} 
), 

wilder_sma as (
select
    ticker,
    rn,
    trade_date,
    gain,
    loss,
    wilder_gain,
    wilder_loss
from {{ ref("int__rsi_wilder") }}
),

rsi as (
    select
        s.trade_date,
        s.ticker,
        (s.sma_gain / nullif(s.sma_loss,0)) as sma_rs,
        100 - (100 / (1 + (s.sma_gain / nullif(s.sma_loss,0)))) as sma_rsi,
        (case 
            when ws.wilder_loss = 0 and ws.wilder_gain > 0 then 100
            when ws.wilder_loss > 0 and ws.wilder_gain =  0 then 0
            else (ws.wilder_gain / nullif(ws.wilder_loss,0))
        end) as wilder_rs,
        (case 
        when ws.wilder_loss = 0 and ws.wilder_gain > 0 then 100
        when ws.wilder_loss > 0 and ws.wilder_gain =  0 then 0
        else 100 - (100 / (1 + (ws.wilder_gain / nullif(ws.wilder_loss,0)))) 
        end) as wilder_rsi, 
        s.period_check                
    from sma s
    left join wilder_sma ws on s.trade_date = ws.trade_date and s.ticker = ws.ticker
), 

final as ( 
    select 
        trade_date,
        ticker,
        (case when period_check < 14 then null else sma_rs end) as sma_rs, 
        (case when period_check < 14 then null else sma_rsi end) as sma_rsi, 
        (case when period_check < 14 then null else wilder_rs end) as wilder_rs, 
        (case when period_check < 14 then null else wilder_rsi end) as wilder_rsi, 
    from rsi 
    )

select
    trade_date::date as trade_date,
    ticker::text as ticker,
    sma_rs::decimal as sma_rs, 
    sma_rsi::decimal as sma_rsi, 
    wilder_rs::decimal as wilder_rs, 
    wilder_rsi::decimal as wilder_rsi
from final