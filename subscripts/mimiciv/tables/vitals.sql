WITH vitals AS 
(
    select 
        s.stay_id,
        (select array_agg(struct(charttime, heart_rate as value) order by charttime)
        from (select distinct * from unnest(vit) where heart_rate is not null)) hr,
        (select array_agg(struct(charttime, sbp as value) order by charttime)
        from (select distinct * from unnest(vit) where sbp is not null)) sbp,
        (select array_agg(struct(charttime, dbp as value) order by charttime)
        from (select distinct * from unnest(vit) where dbp is not null)) dbp,
        (select array_agg(struct(charttime, mbp as value) order by charttime)
        from (select distinct * from unnest(vit) where mbp is not null)) meanbp,
        (select array_agg(struct(charttime, resp_rate as value) order by charttime)
        from (select distinct * from unnest(vit) where resp_rate is not null)) rr,
        (select array_agg(struct(charttime, temperature as value) order by charttime)
        from (select distinct * from unnest(vit) where temperature is not null)) temp,
        (select array_agg(struct(charttime, spo2 as value) order by charttime)
        from (select distinct * from unnest(vit) where spo2 is not null)) spo2
    from (
        select
            t.stay_id,
            array_agg(struct(t.charttime, t.heart_rate, t.sbp, t.dbp, t.mbp, t.resp_rate, t.temperature, t.spo2, t.glucose)) vit
        from `physionet-data.mimic_derived.vitalsign` t
        group by t.stay_id
    ) s
)
, cardiac_index AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, ci) order by charttime) 
         from (select distinct * from unnest(ci) where ci is not null)) ci,
    from (
        select 
            g.stay_id,
            array_agg(struct(g.charttime, g.valuenum as ci)) ci
        from `physionet-data.mimic_icu.chartevents` g
        where itemid in (228368, 228177)
        group by g.stay_id
    ) s
)
SELECT
    icu.stay_id
    , vitals.hr as hr
    , vitals.sbp as sbp
    , vitals.dbp as dbp
    , vitals.meanbp as meanbp
    , vitals.rr as rr
    , vitals.temp as temp
    , vitals.spo2 as spo2
    , cardiac_index.ci as cardiac_index
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN vitals ON icu.stay_id = vitals.stay_id
LEFT JOIN cardiac_index ON icu.stay_id = cardiac_index.stay_id



