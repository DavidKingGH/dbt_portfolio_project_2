{{
  config(
    materialized = 'incremental',
    unique_key = ['trade_date', 'ticker'],
    incremental_strategy = 'merge',
    on_schema_change = 'fail'
    
  )
}}


with regimes as (
    select
    regime, 
    regime_period_id,
    days_in_regime, 
    "start_date",
    end_date
from {{ ref("int__regime_changes") }}
), 


src_stocks as (
    select 
        trade_date, 
        ticker, 
        "open", 
        high, 
        low, 
        "close", 
        volume, 
        loaded_at
    from {{ ref("src_stocks") }}
    where 1 = 1 
        and "close" > 0
        and volume >= 0
        and trade_date <= current_date
        {% if is_incremental() %}
        and trade_date > (select max(trade_date) from {{ this }})
        {% endif %}
)

select
    s.trade_date, 
    s.ticker, 
    s."open", 
    s.high, 
    s.low, 
    s."close", 
    s.volume, 
    r.regime
from src_stocks s
left join regimes r on s.trade_date BETWEEN r."start_date" and coalesce(r.end_date, '9999-12-31')

    
