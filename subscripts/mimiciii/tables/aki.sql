WITH aki AS
(
    select
        s.icustay_id,
        (select array_agg(struct(charttime, aki_stage_creat, aki_stage_uo) order by charttime) from unnest(aki) where aki is not null) aki,
    from (
        select 
        g.icustay_id,
        array_agg(struct(g.charttime, g.aki_stage_creat, g.aki_stage_uo)) aki
        from `physionet-data.mimiciii_derived.kdigo_stages` g
        group by g.icustay_id
    ) s
)
SELECT
-- blood product administration
    ad.icustay_id as stay_id
    , aki.aki as aki
 FROM
`physionet-data.mimiciii_derived.icustay_detail` ad
LEFT JOIN aki on ad.ICUSTAY_ID = aki.ICUSTAY_ID
FILTER_HERE
