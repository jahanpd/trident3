WITH readmit as (
    select
        array_agg(struct(icu.icu_intime as t) order by icu_intime) as time_array
        , icu.hadm_id
    from 
        `physionet-data.mimic_derived.icustay_detail` icu
    group by hadm_id
)
SELECT
    icu.stay_id as stay_id
    , array_length(
        (select array_agg(t order by t) from unnest(readmit.time_array)
    where t > ft.postop_intime)
    ) readmissions
    , (select array_agg(t order by t) from unnest(readmit.time_array)
    where t > ft.postop_intime) readmit_times
    , (
        (select array_agg(t order by t) from unnest(readmit.time_array)
    where t > ft.postop_intime)
    )[ORDINAL(1)] first_readmission
FROM readmit
RIGHT JOIN `physionet-data.mimic_derived.icustay_detail` icu on readmit.hadm_id = icu.hadm_id
FILTER_HERE
