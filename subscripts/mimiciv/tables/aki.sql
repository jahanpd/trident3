WITH aki AS
(
    select
        s.stay_id as stay_id,
        (select array_agg(struct(charttime, aki_stage_creat, aki_stage_uo) order by charttime) from unnest(aki) where aki is not null) aki,
    from (
        select 
        g.stay_id,
        array_agg(struct(g.charttime, g.aki_stage_creat, g.aki_stage_uo)) aki
        from `physionet-data.mimic_derived.kdigo_stages` g
        group by g.stay_id
    ) s
)
SELECT
    icu.stay_id
    , (select array_agg(
            struct(charttime, aki_stage_creat, aki_stage_uo) 
            order by charttime) 
    from (select distinct * from unnest(aki.aki))
    where charttime >= ft.postop_intime and charttime < icu.icu_outtime
    ) as aki
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN aki ON icu.stay_id = aki.stay_id
FILTER_HERE
