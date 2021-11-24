WITH
  vent AS (
  SELECT
    s.stay_id,
    (
    SELECT
      MIN(starttime)
    FROM
      UNNEST(vent)) first_vent,
    (
    SELECT
      ARRAY_AGG(STRUCT(starttime,
          endtime,
          duration_hours)
      ORDER BY
        starttime )
    FROM
      UNNEST(vent)
    WHERE
      duration_hours IS NOT NULL) vent,
  FROM (
    SELECT
      g.stay_id,
      ARRAY_AGG(STRUCT(g.starttime,
          g.endtime,
          DATETIME_DIFF(g.endtime,
            g.starttime,
            HOUR) AS duration_hours )) vent
    FROM
      `physionet-data.mimic_derived.ventilation` g
    WHERE
      g.ventilation_status = 'InvasiveVent'
    GROUP BY
      g.stay_id ) s ),


  vitals AS (
  SELECT
    s.stay_id,
    (
    SELECT
      MIN(charttime)
    FROM
      UNNEST(vit)
    WHERE
      heart_rate IS NOT NULL) hr_time,
    (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          heart_rate AS value)
      ORDER BY
        charttime) 
    FROM
      UNNEST(vit)
    WHERE
      heart_rate IS NOT NULL) hr,
     (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          sbp AS value)
      ORDER BY
        charttime) 
    FROM
      UNNEST(vit)
    WHERE
      sbp IS NOT NULL) sbp,
    (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          dbp AS value)
      ORDER BY
        charttime) 
    FROM
      UNNEST(vit)
    WHERE
      dbp IS NOT NULL) dbp,
     (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          mbp AS value)
      ORDER BY
        charttime) --
    FROM
      UNNEST(vit)
    WHERE
      mbp IS NOT NULL) meanbp,
     (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          resp_rate AS value)
      ORDER BY
        charttime) 
    FROM
      UNNEST(vit)
    WHERE
      resp_rate IS NOT NULL) rr,
     (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          temperature AS value)
      ORDER BY
        charttime) --
    FROM
      UNNEST(vit)
    WHERE
      temperature IS NOT NULL) temp,
     (
    SELECT
      ARRAY_AGG(STRUCT(charttime,
          spo2 AS value)
      ORDER BY
        charttime) --
    FROM
      UNNEST(vit)
    WHERE
      spo2 IS NOT NULL) spo2
  FROM (
    SELECT
      t.stay_id,
      ARRAY_AGG(STRUCT(t.charttime,
          t.heart_rate,
          t.sbp,
          t.dbp,
          t.mbp,
          t.resp_rate,
          t.temperature,
          t.spo2,
          t.glucose)) vit
    FROM
      `physionet-data.mimic_derived.vitalsign` t
    GROUP BY
      t.stay_id ) s ),


  ventsettings AS (
  SELECT
    s.stay_id,
    (
    SELECT
      MIN(charttime)
    FROM
      UNNEST(vent)
    WHERE
      vent IS NOT NULL) first_vent_settings,
    (
    SELECT
      ARRAY_AGG( STRUCT( charttime,
          rrset,
          rrtotal,
          rrspont,
          minute_volume,
          tvset,
          tvobs,
          tvspont,
          plat,
          peep,
          fio2,
          mode,
          mode_ham,
          type )
      ORDER BY
        charttime )
    FROM
      UNNEST(vent)
    WHERE
      mode IS NOT NULL
      OR mode_ham IS NOT NULL) vent,
  FROM (
    SELECT
      stay_id,
      ARRAY_AGG(STRUCT( charttime,
          respiratory_rate_set AS rrset,
          respiratory_rate_total AS rrtotal,
          respiratory_rate_spontaneous AS rrspont,
          minute_volume,
          tidal_volume_set AS tvset,
          tidal_volume_observed AS tvobs,
          tidal_volume_spontaneous AS tvspont,
          plateau_pressure AS plat,
          peep,
          fio2,
          ventilator_mode AS mode,
          ventilator_mode_hamilton AS mode_ham,
          ventilator_type AS type )) vent
    FROM
      `physionet-data.mimic_derived.ventilator_setting`
    GROUP BY
      stay_id ) s ),


  -- set_ICU_in_time AS (
  -- SELECT
  --   vent.stay_id,
  --   CASE
  --     WHEN vent.first_vent IS NOT NULL THEN vent.first_vent
  --   ELSE
  --   ventsettings.first_vent_settings
  -- END
  --   AS first_ventilator_time
  -- FROM
  --   vent
  -- LEFT JOIN
  --   ventsettings
  -- ON
  --   vent.stay_id = ventsettings.stay_id
  -- LEFT JOIN
  --   vitals
  -- ON
  --   vent.stay_id = vitals.stay_id ),


  multiple_icu AS (
  SELECT
    ie.stay_id,
    CASE
      WHEN COUNT(*) OVER (PARTITION BY ie.hadm_id) > 1 THEN 1
    ELSE
    0
  END
    AS multiple_icu_stays --more than 1 ICU stay IN the same hospital admission.
  FROM
    `physionet-data.mimic_derived.icustay_detail` ie )


SELECT
  icu.stay_id,
  icu.hadm_id,
  icu2.icustay_seq,
  icu.INTIME AS reported_icu_intime,
   CASE
      WHEN vent.first_vent IS NOT NULL THEN vent.first_vent
    ELSE
    ventsettings.first_vent_settings
  END
    AS postop_intime,
  icu.OUTTIME,
  multi.multiple_icu_stays
FROM
  `physionet-data.mimic_icu.icustays` icu
LEFT JOIN
  `physionet-data.mimic_derived.icustay_detail` AS icu2
ON
  icu.stay_id = icu2.stay_id
LEFT JOIN
  multiple_icu AS multi
ON
  icu.stay_id = multi.stay_id
LEFT JOIN
  vent
ON
  icu.stay_id = vent.stay_id
  LEFT JOIN
  ventsettings 
ON
  icu.stay_id = ventsettings.stay_id
