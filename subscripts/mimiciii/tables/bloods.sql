with bloods as (
    select
        s.subject_id
        -- blood gas values (combined with biochem and fbe in itemids)
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50820) and VALUENUM is not null) pH
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50882) and VALUENUM is not null) bicarb 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50802) and VALUENUM is not null) baseexcess
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50806, 50902) and VALUENUM is not null) chloride
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50808) and VALUENUM is not null) free_calcium 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50971, 50822) and VALUENUM is not null) potassium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50824, 50983) and VALUENUM is not null) sodium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50813) and VALUENUM is not null) lactate
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50810) and VALUENUM is not null) hematocrit
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51222, 50811) and VALUENUM is not null) hb
        -- partial pressures and o2 from blood gas
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50818) and VALUENUM is not null) pco2
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50802) and VALUENUM is not null) po2
        -- auxillary blood gas information
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50825) and VALUENUM is not null) bg_temp 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50816) and VALUENUM is not null) fio2
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50827) and VALUENUM is not null) ventrate
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50826) and VALUENUM is not null) tidalvol
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50801) and VALUENUM is not null) aado2 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50800) and VALUENUM is not null) specimen
        -- other bloods
        -- FBE
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51256) and VALUENUM is not null) neutrophils
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51244, 51245) and VALUENUM is not null) lymphocytes
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51300, 51301, 51755) and VALUENUM is not null) wcc
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51265) and VALUENUM is not null) plt
        -- inflammatory
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50889) and VALUENUM is not null) crp
        -- LFTs and BIOCHEM (if electrolyte not in blood gas)
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50862) and VALUENUM is not null) albumin
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50912) and VALUENUM is not null) creatinine
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51006) and VALUENUM is not null) bun
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50960) and VALUENUM is not null) magnesium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50861) and VALUENUM is not null) alt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50863) and VALUENUM is not null) alp
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50878) and VALUENUM is not null) ast
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50927) and VALUENUM is not null) ggt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50885) and VALUENUM is not null) bilirubin_total
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50883) and VALUENUM is not null) bilirubin_direct
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50884) and VALUENUM is not null) bilirubin_indirect
        -- coags
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51237) and VALUENUM is not null) inr
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51213, 51214) and VALUENUM is not null) fibrinogen
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51149) and VALUENUM is not null) bleed_time
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51141) and VALUENUM is not null) pt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51275) and VALUENUM is not null) ptt 

        -- other eg hba1c
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50852) and VALUENUM is not null) hba1c

    from (
        SELECT le.subject_id,
            array_agg(struct(le.ITEMID, le.charttime, le.VALUENUM)) bloods,
        FROM `physionet-data.mimiciii_clinical.labevents` le
        GROUP BY le.subject_id
    ) s
)
, glucose AS
(
    select
        d.subject_id
        ,( select array_agg(struct(itemid,charttime,value) order by charttime)
        from unnest(d.glucose) where value is not null 
        ) as glucose
    from (
        SELECT s.subject_id
        , array_agg(struct(s.itemid,s.charttime, s.value)) as glucose
        from (
            SELECT subject_id,
               ITEMID as itemid,
               charttime,
               VALUENUM as value
            FROM `physionet-data.mimiciii_clinical.labevents`
            where ITEMID in (50931, 50809)
            union all
            SELECT subject_id,
                ITEMID as itemid,
                charttime,
                VALUENUM as value
            FROM `physionet-data.mimiciii_clinical.chartevents`
            where 
                ITEMID in (807, 811, 1529, 3744, 3745, 22664, 220621, 226537) and
                ERROR is distinct from 1
        ) s   
        group by s.subject_id
    ) d 
)
SELECT
-- blood gases
    icu.icustay_id as stay_id
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ph)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ph
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bicarb)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bicarb
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.baseexcess)
        where charttime > icu.intime and charttime < icu.outtime
    ) as baseexcess
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.chloride)
        where charttime > icu.intime and charttime < icu.outtime
    ) as chloride
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.free_calcium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as free_calcium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(glucose.glucose)
        where charttime > icu.intime and charttime < icu.outtime
    ) as glucose
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.potassium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as potassium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.sodium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as sodium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.lactate)
        where charttime > icu.intime and charttime < icu.outtime
    ) as lactate
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.hematocrit)
        where charttime > icu.intime and charttime < icu.outtime
    ) as hematocrit
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.hb)
        where charttime > icu.intime and charttime < icu.outtime
    ) as hb
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.pco2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as pco2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.po2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as po2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bg_temp)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bg_temp
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.fio2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as fio2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ventrate)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ventrate
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.tidalvol)
        where charttime > icu.intime and charttime < icu.outtime
    ) as tidalvol
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.aado2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as aado2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.specimen)
        where charttime > icu.intime and charttime < icu.outtime
    ) as specimen -- this is needed to delineate between art/venous gases
    -- blood film
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.neutrophils)
        where charttime > icu.intime and charttime < icu.outtime
    ) as neutrophils
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.lymphocytes)
        where charttime > icu.intime and charttime < icu.outtime
    ) as lymphocytes
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.wcc)
        where charttime > icu.intime and charttime < icu.outtime
    ) as wcc
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.plt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as plt
    -- inflammatory
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.crp)
        where charttime > icu.intime and charttime < icu.outtime
    ) as crp
    -- chemistry
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.albumin)
        where charttime > icu.intime and charttime < icu.outtime
    ) as albumin
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.creatinine)
        where charttime > icu.intime and charttime < icu.outtime
    ) as creatinine
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bun)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bun
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.magnesium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as magnesium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.alt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as alt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.alp)
        where charttime > icu.intime and charttime < icu.outtime
    ) as alp
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ast)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ast
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ggt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ggt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bilirubin_total)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bilirubin_total
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bilirubin_direct)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bilirubin_direct
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bilirubin_indirect)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bilirubin_indirect
    -- coags
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.inr)
        where charttime > icu.intime and charttime < icu.outtime
    ) as inr
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.fibrinogen)
        where charttime > icu.intime and charttime < icu.outtime
    ) as fibrinogen
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bleed_time)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bleed_time
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ptt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ptt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.pt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as pt
    -- other bloods
    , bloods.hba1c as hba1c
FROM `physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN bloods ON icu.subject_id = bloods.subject_id
LEFT JOIN glucose ON icu.subject_id = glucose.subject_id
FILTER_HERE
