WITH readmit as (
    select
        array_agg(icu.intime) as time_array
        , icu.hadm_id
    from 
        `physionet-data.mimiciii_derived.icustay_detail` icu
    group by hadm_id
)
SELECT
    icu.icustay_id as stay_id
    , CASE WHEN
    ARRAY_LENGTH(readmit.time_array) > 1
    THEN
    (select array_agg(icu.intime) from unnest(readmit.time_array) 
     where icu.intime > ft.postop_intime)
    ELSE null END readmit_times
FROM readmit
RIGHT JOIN `physionet-data.mimiciii_derived.icustay_detail` icu on readmit.hadm_id = icu.hadm_id
FILTER_HERE
