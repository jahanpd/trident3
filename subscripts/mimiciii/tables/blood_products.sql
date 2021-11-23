-- blood procuct tables
WITH prbcs AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, bloodproduct, unit) order by charttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            ICUSTAY_ID,
            array_agg(struct(s.charttime, s.bloodproduct, s.unit)) bloodproduct,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_cv`
            where (
                ITEMID in (226370, 227070, 226368, 225168, 221013, 44560, 43901, 43010, 30002, 30106, 30179, 30001, 30004, 42588, 42239, 46407, 42186)
            )
            union all
            select
                ICUSTAY_ID
                , STARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_mv`
            where (
                ITEMID in (226370, 227070, 226368, 225168, 221013, 44560, 43901, 43010, 30002, 30106, 30179, 30001, 30004, 42588, 42239, 46407, 42186)
            )
        ) s 
        group by ICUSTAY_ID
    ) d
) 
, plts AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, bloodproduct, unit) order by charttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            ICUSTAY_ID,
            array_agg(struct(s.charttime, s.bloodproduct, s.unit)) bloodproduct,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_cv`
            where (
                ITEMID in (30006, 30105, 225170, 227071, 226369)
            )
            union all
            select
                ICUSTAY_ID
                , STARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_mv`
            where (
                ITEMID in (30006, 30105, 225170, 227071, 226369)
            )
        ) s 
        group by ICUSTAY_ID
    ) d
)
, ffp AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, bloodproduct, unit) order by charttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            ICUSTAY_ID,
            array_agg(struct(s.charttime, s.bloodproduct, s.unit)) bloodproduct,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_cv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
            union all
            select
                ICUSTAY_ID
                , STARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_mv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
        ) s 
        group by ICUSTAY_ID
    ) d
)
, cryo AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, bloodproduct, unit) order by charttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            ICUSTAY_ID,
            array_agg(struct(s.charttime, s.bloodproduct, s.unit)) bloodproduct,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_cv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
            union all
            select
                ICUSTAY_ID
                , STARTTIME as charttime
                , AMOUNT as bloodproduct
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_mv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
        ) s 
        group by ICUSTAY_ID
    ) d
)
SELECT
-- blood product administration
    ad.icustay_id as stay_id
    , prbcs.bloodproduct as prbc
    , plts.bloodproduct as plts
    , ffp.bloodproduct as ffp
    , cryo.bloodproduct as cryo
FROM
`physionet-data.mimiciii_derived.icustay_detail` ad
LEFT JOIN prbcs ON ad.icustay_id = prbcs.icustay_id
LEFT JOIN plts ON prbcs.ICUSTAY_ID = plts.ICUSTAY_ID
LEFT JOIN ffp ON prbcs.ICUSTAY_ID = ffp.ICUSTAY_ID
LEFT JOIN cryo ON prbcs.ICUSTAY_ID = cryo.ICUSTAY_ID
FILTER_HERE
