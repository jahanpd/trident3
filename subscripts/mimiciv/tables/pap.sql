WITH PASP AS (
   select
       s.stay_id,
       (select array_agg(struct(charttime, PASP) order by charttime)
        from (select distinct * from unnest(PASP) where PASP is not null)) PASP,
   from (
       select
           g.stay_id,
           array_agg(struct(g.charttime, g.valuenum as PASP)) PASP
       from `physionet-data.mimic_icu.chartevents` g
       where itemid in (222006)
       group by g.stay_id
   ) s
)
-- PADP (Luke)
, PADP AS (
   select
       s.stay_id,
       (select array_agg(struct(charttime, PADP) order by charttime)
        from (select distinct * from unnest(PADP) where PADP is not null)) PADP,
   from (
       select
           g.stay_id,
           array_agg(struct(g.charttime, g.valuenum as PADP)) PADP
       from `physionet-data.mimic_icu.chartevents` g
       where itemid in (220060)
       group by g.stay_id
   ) s
)
-- mPAP (Luke)
, mPAP AS (
   select
       s.stay_id,
       (select array_agg(struct(charttime, mPAP) order by charttime) 
        from (select distinct * from unnest(mPAP) where mPAP is not null)) mPAP,
   from (
       select
           g.stay_id,
           array_agg(struct(g.charttime, g.valuenum as mPAP)) mPAP
       from `physionet-data.mimic_icu.chartevents` g
       where itemid in (120059)
       group by g.stay_id
   ) s
)
SELECT
    icu.stay_id
    , PASP.PASP as pasp
    , PADP.PADP as padp
    , mPAP.mPAP as mpap
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN PASP on icu.stay_id = PASP.stay_id
LEFT JOIN PADP on icu.stay_id = PADP.stay_id
LEFT JOIN mPAP on icu.stay_id = mPAP.stay_id
FILTER_HERE
