WITH vitals AS 
(
    select 
        s.icustay_id,
        (select array_agg(struct(charttime, HeartRate as value) order by charttime)
        from (select distinct * from unnest(vit) where HeartRate is not null)) hr,
        (select array_agg(struct(charttime, SysBP as value) order by charttime)
        from (select distinct * from unnest(vit) where SysBP is not null)) sbp,
        (select array_agg(struct(charttime, DiasBP as value) order by charttime)
        from (select distinct * from unnest(vit) where DiasBP is not null)) dbp,
        (select array_agg(struct(charttime, MeanBP as value) order by charttime)
        from (select distinct * from unnest(vit) where MeanBP is not null)) meanbp,
        (select array_agg(struct(charttime, RespRate as value) order by charttime)
        from (select distinct * from unnest(vit) where RespRate is not null)) rr,
        (select array_agg(struct(charttime, TempC as value) order by charttime)
        from (select distinct * from unnest(vit) where TempC is not null)) temp,
        (select array_agg(struct(charttime, SpO2 as value) order by charttime)
        from (select distinct * from unnest(vit) where SpO2 is not null)) spo2
    from (
        select
            t.icustay_id,
            array_agg(struct(t.charttime, t.HeartRate, t.SysBP, t.DiasBP, t.MeanBP, t.RespRate, t.TempC, t.SpO2, t.Glucose)) vit
        from `physionet-data.mimiciii_derived.pivoted_vital` t
        group by t.icustay_id
    ) s
)
, cardiac_index AS
(
    select
        s.icustay_id,
        (select array_agg(struct(charttime, ci) order by charttime) from (select distinct * from unnest(ci) where ci is not null)) ci,
    from (
        select 
            g.icustay_id,
            array_agg(struct(g.charttime, g.valuenum as ci)) ci
        from `physionet-data.mimiciii_clinical.chartevents` g
        where 
            itemid in (228177, 226859, 228368, 226859, 116, 7610)
            and ERROR is distinct from 1
        group by g.icustay_id
    ) s
)
SELECT
-- vitals
    vitals.icustay_id as stay_id
    , vitals.hr as hr
    , vitals.sbp as sbp
    , vitals.dbp as dbp
    , vitals.meanbp as meanbp
    , vitals.rr as rr
    , vitals.temp as temp
    , vitals.spo2 as spo2
    , cardiac_index.ci as cardiac_index
FROM
`physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN cardiac_index ON icu.icustay_id = cardiac_index.icustay_id
LEFT JOIN vitals ON vitals.icustay_id = cardiac_index.icustay_id
FILTER_HERE
