-- blood procuct tables 
WITH prbcs AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (225168, 226370, 221013, 226368, 227070)
        )
        group by stay_id
    ) s
)
, plts AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (225170, 226369, 227071)
        )
        group by stay_id
    ) s
)
, ffp AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (226367, 227072, 220970)
        )
        group by stay_id
    ) s
)
, cryo AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (225171, 226371)
        )
        group by stay_id
    ) s
)
-- blood product administration
SELECT
    icu.stay_id
    , (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) 
        from unnest(prbcs.bloodproduct)
        where starttime >= ft.postop_intime  and starttime <= icu.icu_outtime
    ) as prbc
    , (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) 
        from unnest(plts.bloodproduct)
        where starttime >= ft.postop_intime  and starttime <= icu.icu_outtime
    ) as plts
    , (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) 
        from unnest(ffp.bloodproduct)
        where starttime >= ft.postop_intime  and starttime <= icu.icu_outtime
    )  as ffp
    , (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) 
        from unnest(cryo.bloodproduct)
        where starttime >= ft.postop_intime  and starttime <= icu.icu_outtime
    ) as cryo
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
-- blood product tables
LEFT JOIN prbcs ON icu.stay_id = prbcs.stay_id
LEFT JOIN plts ON icu.stay_id = plts.stay_id
LEFT JOIN ffp ON icu.stay_id = ffp.stay_id
LEFT JOIN cryo ON icu.stay_id = cryo.stay_id
FILTER_HERE

