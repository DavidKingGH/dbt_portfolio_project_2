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
        volume
    from {{ ref("stg__stocks") }}
    {% if is_incremental() %}
    where trade_date > (select max(trade_date) from {{ this }})
    {% endif %}
)

select
    s.trade_date::date as trade_date, 
    s.ticker::text as ticker, 
    s."open"::decimal(18,2) as "open", 
    s.high::decimal(18,2) as high, 
    s.low::decimal(18,2) as low, 
    s."close"::decimal(18,2) as "close", 
    s.volume::decimal(18,0) as volume, 
    r.regime::text as regime
from src_stocks s
left join regimes r on s.trade_date BETWEEN r."start_date" and coalesce(r.end_date, date '9999-12-31')

    
