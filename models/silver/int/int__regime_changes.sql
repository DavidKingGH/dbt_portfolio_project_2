with regime_classifications as (
    SELECT
        trade_date, 
        "close", 
        regime, 
        loaded_at
    FROM {{ ref("int__regime_classification") }}
), 

prev_regime as (
select
    trade_date, 
    regime, 
    loaded_at, 
    lag(regime) over(order by trade_date asc, loaded_at asc) as prev_regime
from regime_classifications
),

regime_changes as (
    select 
        trade_date, 
        regime, 
        loaded_at, 
        prev_regime,
        (case
            when regime != prev_regime or prev_regime is null then 1
            else 0
        end) as changed
    from prev_regime
),

regime_change_count as (
    select
        trade_date, 
        regime, 
        loaded_at, 
        prev_regime,
        changed,
        sum(changed) over(
                        order by trade_date asc, loaded_at asc 
                        rows between unbounded preceding and currnent row
                        ) as regime_period_id
    from regime_changes
), 

final as (
    select
        regime, 
        regime_period_id,
        count(*) as days_in_regime, 
        min(trade_date) as "start_date",
        max(trade_date) as end_date
    from regime_change_count
    where regime is not null
    group by regime_period_id, regime
)

select
    regime::text as regime, 
    regime_period_id::int as regime_period_id,
    days_in_regime::int as days_in_regime, 
    "start_date"::date as "start_date",
    end_date::date as end_date
from final
order by "start_date" asc
