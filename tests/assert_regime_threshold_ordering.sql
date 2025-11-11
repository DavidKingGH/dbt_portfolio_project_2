{{
    config(
        severity='error'
    )
}}

select
    version_id,
    complacent_max,
    normal_max,
    elevated_max
from {{ ref('regime_thresholds') }}
where not (complacent_max < normal_max and normal_max < elevated_max)