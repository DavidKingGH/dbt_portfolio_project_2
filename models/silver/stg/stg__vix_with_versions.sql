with src_vix as (
select
    trade_date, 
    "close", 
    loaded_at
from {{ref("src_vix")}}
), 

thresholds as (
    select *
    from {{ ref("regime_thresholds") }}
),

vix_with_all_versions as (
    select
        v.trade_date, 
        v."close", 
        v.loaded_at,
        t.version_id, 
        t.version_name, 
        t.complacent_max, 
        t.normal_max, 
        t.elevated_max, 
        t.effective_date, 
        row_number() over(partition by v.trade_date order by t.effective_date desc) as version_rank
    from src_vix v
    join thresholds t on v.trade_date >= t.effective_date

)

select
    trade_date::date as trade_date,
    "close"::decimal as "close",
    loaded_at::timestamp as loaded_at,
    version_id::int as version_id,
    version_name::text as version_name,
    complacent_max::int as complacent_max,
    normal_max::int as normal_max,
    elevated_max::int as elevated_max,
    effective_date::date as effective_date, 
    version_rank::int as version_rank
from vix_with_all_versions
where version_rank = 1


