WITH vent AS (
    select
        s.icustay_id,
        (select array_agg(struct(starttime, endtime, duration_hours) order by starttime) 
            from (select distinct * from unnest(vent) where duration_hours is not null)) vent,
    from (
        select
            g.icustay_id,
            array_agg(struct(g.starttime, g.endtime, g.duration_hours)) vent
        from `physionet-data.mimiciii_derived.ventilation_durations` g
        group by g.icustay_id
    ) s
)
, ce as
(
  SELECT
      ce.subject_id
    , ce.icustay_id
    , ce.charttime
    , le.itemid
    -- TODO: clean
    , value
    , label
    , case
        -- begin fio2 cleaning
        when ce.itemid = 223835
        then
            case
                when valuenum >= 0.20 and valuenum <= 1
                    then valuenum * 100
                -- improperly input data - looks like O2 flow in litres
                when valuenum > 1 and valuenum < 20
                    then null
                when valuenum >= 20 and valuenum <= 100
                    then valuenum
            ELSE NULL END
        -- end of fio2 cleaning
        -- begin peep cleaning
        WHEN ce.itemid in (220339, 224700)
        THEN
          CASE
            WHEN valuenum > 100 THEN NULL
            WHEN valuenum < 0 THEN NULL
          ELSE valuenum END
        -- end peep cleaning
    ELSE valuenum END AS valuenum
    , valueuom
    , storetime
  FROM `physionet-data.mimiciii_clinical.chartevents` ce
  LEFT JOIN `physionet-data.mimiciii_clinical.d_items` le on le.ITEMID = ce.ITEMID
  where ce.value IS NOT NULL
  AND ce.icustay_id IS NOT NULL
  AND ce.valuenum is not null
  AND (ce.itemid IN
  (
      720 -- vent type
      , 467 -- O2 delivery device
      , 445, 448, 449, 450, 1340, 1486, 1600, 224687 -- minute volume
      , 639, 654, 681, 682, 683, 684, 224685, 224684, 224686 -- tidal volume
      , 543 -- PlateauPressure
      , 5865, 5866, 224707, 224709, 224705, 224706 -- APRV pressure
      , 60, 437, 505, 506, 686, 220339, 224700 -- PEEP
      , 3459 -- high pressure relief
      , 501, 502, 503, 224702 -- PCV
      , 223, 667, 668, 669, 670, 671, 672 -- TCPCV
      , 157, 158, 1852, 3398, 3399, 3400, 3401, 3402, 3403, 3404, 8382, 227809, 227810 -- ETT
      , 224701 -- PSVlevel
  ) or regexp_contains(LABEL, r'(?i)(fio)'))
)
, vs as (
SELECT
      subject_id
    , MAX(icustay_id) AS icustay_id
    , charttime
    , MAX(CASE WHEN itemid = 720 THEN valuenum ELSE NULL END) AS type
    , MAX(CASE WHEN itemid = 467 THEN valuenum ELSE NULL END) AS o2delivery
    , MAX(CASE WHEN itemid in (445, 448, 449, 450, 1340, 1486, 1600, 224687)
        THEN valuenum ELSE NULL END) AS minute_volume
    , MAX(CASE WHEN itemid in (639, 654, 681, 682, 683, 684, 224685, 224684, 224686)
        THEN valuenum ELSE NULL END) AS tvobs
    , MAX(CASE WHEN itemid = 543 THEN valuenum ELSE NULL END) AS plat
    , MAX(CASE WHEN itemid in (5865, 5866, 224707, 224709, 224705, 224706)
        THEN valuenum ELSE NULL END) AS aprv
    , MAX(CASE WHEN itemid in (60, 437, 505, 506, 686, 220339, 224700) THEN valuenum ELSE NULL END) AS peep
    , MAX(CASE WHEN itemid = 3459 THEN valuenum ELSE NULL END) AS high_pressure_relief
    , MAX(CASE WHEN itemid in (501, 502, 503, 224702 ) THEN valuenum ELSE NULL END) AS pcv
    , MAX(CASE WHEN itemid in (223, 667, 668, 669, 670, 671, 672) THEN value ELSE NULL END) AS tcpcv
    , MAX(CASE WHEN itemid = 224701 THEN value ELSE NULL END) AS psvlevel
    , MAX(CASE WHEN regexp_contains(label, r'(?i)(fio)') THEN value ELSE NULL END) AS fio2
FROM ce
GROUP BY subject_id, charttime
)
, ventsettings as (
select
    icustay_id
    , array_agg(struct(
                charttime,
                o2delivery as o2delivery,
                tvobs,
                minute_volume,
                plat,
                peep,
                fio2,
                aprv,
                high_pressure_relief,
                type,
                pcv,
                tcpcv,
                psvlevel
                )) ventsettings
from vs
group by icustay_id
)
SELECT
    icu.icustay_id as stay_id
    , vent.vent as vent_array
    , (CASE WHEN
            ARRAY_LENGTH(vent.vent) > 1
        THEN 1
        ELSE 0 END ) as reintubation
    , (CASE WHEN
            ARRAY_LENGTH(vent.vent) > 1
        THEN vent.vent[ORDINAL(2)].starttime
        ELSE null END ) as reint_time
    , (vent.vent[ORDINAL(1)].endtime) ext_time
    , (select array_agg(struct(
                charttime,
                o2delivery as o2delivery,
                tvobs,
                minute_volume,
                plat,
                peep,
                fio2,
                aprv,
                high_pressure_relief,
                type,
                pcv,
                tcpcv,
                psvlevel
                ) order by charttime) from 
    (select distinct * from unnest(ventsettings.ventsettings))) as ventsettings
 FROM
`physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN vent on icu.ICUSTAY_ID = vent.ICUSTAY_ID
LEFT JOIN ventsettings on icu.ICUSTAY_ID = ventsettings.ICUSTAY_ID
FILTER_HERE
