with base as (
    select 
        trade_date,
        ticker,
        "close",
        loaded_at
    from {{ ref("src_stocks")}}
),

delta as (

    select
        trade_date,
        ticker,
        "close",
        "close" - lag("close", 1) over(partition by ticker order by trade_date asc, loaded_at asc) as delta,
        count(*) over(
            partition by ticker 
            order by trade_date asc, loaded_at asc 
            rows between 13 preceding and current row) as period_check,
        loaded_at
    from base 
),

final as (
    select
        trade_date,
        ticker,
        "close",
        delta,
        (case when delta > 0 then delta else 0 end) as gain,
        (case when delta < 0 then abs(delta) else 0 end) as loss,
        row_number() over(partition by ticker order by trade_date asc, loaded_at asc) as rn,
        period_check,
        loaded_at
    from delta
)

select
    trade_date::date as trade_date,
    ticker::text as ticker,
    "close"::decimal as "close",
    delta::decimal as delta,
    gain::decimal as gain,
    loss::decimal as loss,
    rn::int as rn,
    period_check::int as period_check,
    loaded_at::timestamp as loaded_at
from final