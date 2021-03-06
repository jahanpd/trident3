--PASP (Luke)
WITH PASP AS (
   select
       s.icustay_id,
       (select array_agg(struct(charttime, PASP) order by charttime) from (select distinct * from unnest(PASP) where PASP is not null)) PASP,
   from (
       select
           g.icustay_id,
           array_agg(struct(g.charttime, g.valuenum as PASP)) PASP
       from `physionet-data.mimiciii_clinical.chartevents` g
       where itemid in (220061, 49)
       group by g.icustay_id
   ) s
)
 
-- PADP (Luke)
, PADP AS (
   select
       s.icustay_id,
       (select array_agg(struct(charttime, PADP) order by charttime) from (select distinct * from unnest(PADP) where PADP is not null)) PADP,
   from (
       select
           g.icustay_id,
           array_agg(struct(g.charttime, g.valuenum as PADP)) PADP
       from `physionet-data.mimiciii_clinical.chartevents` g
       where itemid in (220060, 8448)
       group by g.icustay_id
   ) s
)
 
-- mPAP (Luke)
, mPAP AS (
   select
       s.icustay_id,
       (select array_agg(struct(charttime, mPAP) order by charttime) from (select distinct * from unnest(mPAP) where mPAP is not null)) mPAP,
   from (
       select
           g.icustay_id,
           array_agg(struct(g.charttime, g.valuenum as mPAP)) mPAP
       from `physionet-data.mimiciii_clinical.chartevents` g
       where itemid in (2220059, 491)
       group by g.icustay_id
   ) s
)
SELECT
-- blood product administration
    icu.icustay_id as stay_id
    , PASP.PASP as pasp
    , PADP.PADP as padp
    , mPAP.mPAP as mpap
FROM
`physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN PASP on icu.ICUSTAY_ID = PASP.ICUSTAY_ID
LEFT JOIN PADP on icu.ICUSTAY_ID = PADP.ICUSTAY_ID
LEFT JOIN mPAP on icu.ICUSTAY_ID = mPAP.ICUSTAY_ID
FILTER_HERE
