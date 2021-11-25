WITH bloods AS
(
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
        where ITEMID in (50806, 50902, 52434) and VALUENUM is not null) chloride
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50808) and VALUENUM is not null) free_calcium 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50931, 50809, 52027) and VALUENUM is not null) glucose
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50971, 50822, 52452, 52610) and VALUENUM is not null) potassium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50824, 52455, 50983, 52623) and VALUENUM is not null) sodium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50813, 52442) and VALUENUM is not null) lactate
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (52028, 50810, 51638, 51639) and VALUENUM is not null) hematocrit
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51222, 50811, 51640) and VALUENUM is not null) hb
        -- partial pressures and o2 from blood gas
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50818) and VALUENUM is not null) pco2
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50821) and VALUENUM is not null) po2
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
        where ITEMID in (50800, 52028) and VALUENUM is not null) specimen
        -- other bloods
        -- FBE
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51256, 51697) and VALUENUM is not null) neutrophils
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51244, 51690) and VALUENUM is not null) lymphocytes
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51300, 51301, 51755, 51756) and VALUENUM is not null) wcc
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51265, 51704) and VALUENUM is not null) plt
        -- inflammatory
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50889) and VALUENUM is not null) crp
        -- LFTs and BIOCHEM (if electrolyte not in blood gas)
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (52022, 50862, 51542) and VALUENUM is not null) albumin
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (52024, 50912, 52546) and VALUENUM is not null) creatinine
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51006, 52647) and VALUENUM is not null) bun
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
        where ITEMID in (51274) and VALUENUM is not null) pt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51275) and VALUENUM is not null) ptt 

        -- other eg hba1c
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50852) and VALUENUM is not null) hba1c

    from (
        SELECT le.subject_id,
            array_agg(struct(le.itemid as ITEMID, le.charttime, le.valuenum as VALUENUM)) bloods,
        FROM `physionet-data.mimic_hosp.labevents` le
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
            FROM `physionet-data.mimic_hosp.labevents`
            where ITEMID in (50931, 50809, 52027)
            union all
            SELECT subject_id,
                ITEMID as itemid,
                charttime,
                VALUENUM as value
            FROM `physionet-data.mimic_icu.chartevents`
            where ITEMID in (225664, 220621, 226537)
        ) s   
        group by s.subject_id
    ) d 
)
SELECT
    icu.stay_id
    -- blood gases
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.ph))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as ph
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bicarb))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bicarb
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.baseexcess))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as baseexcess
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.chloride))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as chloride
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.free_calcium))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as free_calcium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.glucose))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as glucose
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.potassium))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as potassium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.sodium))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as sodium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.lactate))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as lactate
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.hematocrit))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as hematocrit
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.hb))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as hb
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.pco2))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as pco2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.po2))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as po2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bg_temp))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bg_temp
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.fio2))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as fio2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.ventrate))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as ventrate
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.tidalvol))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as tidalvol
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.aado2))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as aado2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.specimen))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as specimen -- this is needed to delineate between art/venous gases
    -- blood film
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.neutrophils))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as neutrophils
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.lymphocytes))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as lymphocytes
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.wcc))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as wcc
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.plt))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as plt
    -- inflammatory
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.crp))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as crp
    -- chemistry
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.albumin))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as albumin
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.creatinine))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as creatinine
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bun))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bun
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.magnesium))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as magnesium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.alt))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as alt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.alp))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as alp
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.ast))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as ast
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.ggt))        where charttime > ft.postop_intime and charttime < icu.icu_outtime

    ) as ggt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bilirubin_total))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bilirubin_total
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bilirubin_direct))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bilirubin_direct
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bilirubin_indirect))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bilirubin_indirect
    -- coags
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.inr))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as inr
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.fibrinogen))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as fibrinogen
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.bleed_time))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as bleed_time
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.ptt))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as ptt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from (select distinct * from unnest(bloods.pt))        where charttime > ft.postop_intime and charttime < icu.icu_outtime
    ) as pt
    -- other bloods
    , bloods.hba1c as hba1c
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN bloods on bloods.subject_id = icu.subject_id
LEFT JOIN glucose on glucose.subject_id = icu.subject_id
FILTER_HERE
