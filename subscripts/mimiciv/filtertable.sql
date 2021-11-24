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
      g.stay_id ) s 
)
, vitals AS (
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
      t.stay_id ) s 
)
, ventsettings AS (
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
      stay_id ) s 
)


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


, multiple_icu AS (
  SELECT
    ie.stay_id,
    CASE
      WHEN COUNT(*) OVER (PARTITION BY ie.hadm_id) > 1 THEN 1
    ELSE
    0
  END
    AS multiple_icu_stays --more than 1 ICU stay IN the same hospital admission.
  FROM
    `physionet-data.mimic_derived.icustay_detail` ie 
)
, procs AS
-- prepare ICD diagnosis codes for comorbidities
(
    SELECT 
        hadm_id
        , CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
        , CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
        , chartdate
    FROM `physionet-data.mimic_hosp.procedures_icd` diag
)
, surgery AS
-- Code for type of surgery
(
    SELECT
        ad.hadm_id
        , min(procs.chartdate) chartdate
        , array_agg(struct(procs.chartdate, icd9_code, icd10_code)) procedures

        -- CABG
        , MAX(CASE WHEN
            icd10_code IN ('210083', '210088', '210089', '021008C', '021008F', '021008W',
                '210093', '210098', '210099', '021009C', '021009F', '021009W',
                '02100A3', '02100A8', '02100A9', '02100AC', '02100AF', '02100AW',
                '02100J3', '02100J8', '02100J9', '02100JC', '02100JF', '02100JW',
                '02100K3', '02100K8', '02100K9', '02100KC', '02100KF', '02100KW',
                '02100Z3', '02100Z8', '02100Z9', '02100ZC', '02100ZF', '02110Z9',
                '211083', '211088', '211089', '021108C', '021108F', '021108W',
                '211093', '211098', '211099', '021109C', '021109F', '021109W',
                '02110A3', '02110A8', '02110A9', '02110AC', '02110AF', '02110AW',
                '02110J3', '02110J8', '02110J9', '02110JC', '02110JF', '02110JW',
                '02110K3', '02110K8', '02110K9', '02110KC', '02110KF', '02110KW',
                '02110Z3', '02110Z8', '02110ZC', '02110ZF', '212083', '212088',
                '212089', '021208C', '021208F', '021208W', '212093', '212098',
                '212099', '021209C', '021209F', '021209W', '02120A3', '02120A8',
                '02120A9', '02120AC', '02120AF', '02120AW', '02120J3', '02120J8',
                '02120J9', '02120JC', '02120JF', '02120JW', '02120K3', '02120K8',
                '02120K9', '02120KC', '02120KF', '02120KW', '02120Z3', '02120Z8',
                '02120Z9', '02120ZC', '02120ZF', '213083', '213088', '213089',
                '021308C', '021308F', '021308W', '213093', '213098', '213099',
                '021309C', '021309F', '021309W', '02130A3', '02130A8', '02130A9',
                '02130AC', '02130AF', '02130AW', '02130J3', '02130J8', '02130J9',
                '02130JC', '02130JF', '02130JW', '02130K3', '02130K8', '02130K9',
                '02130KC', '02130KF', '02130KW', '02130Z3', '02130Z8', '02130Z9',
                '02130ZC', '02130ZF', '021K0Z5', '021L0Z5', '02540ZZ', '270046',
                '027004Z', '270056', '027005Z', '270066', '027006Z', '270076',
                '027007Z', '02700D6', '02700DZ', '2.70E+09', '02700EZ', '02700F6',
                '02700FZ', '02700G6', '02700GZ', '02700T6', '02700TZ', '02700Z6',
                '02700ZZ', '271046', '027104Z', '271056', '027105Z', '271066',
                '027106Z', '271076', '027107Z', '02710D6', '02710DZ', '2.71E+09',
                '02710EZ', '02710F6', '02710FZ', '02710G6', '02710GZ', '02710T6',
                '02710TZ', '02710Z6', '02710ZZ', '272046', '027204Z', '272056',
                '027205Z', '272066', '027206Z', '272076', '027207Z', '02720D6',
                '02720DZ', '2.72E+09', '02720EZ', '02720F6', '02720FZ', '02720G6',
                '02720GZ', '02720T6', '02720TZ', '02720Z6', '02720ZZ', '273046',
                '027304Z', '273056', '027305Z', '273066', '027306Z', '027307Z',
                '02730D6', '02730DZ', '2.73E+09', '02730EZ', '02730F6', '02730FZ',
                '02730G6', '02730GZ', '02730T6', '02730TZ', '02730Z6', '02730ZZ',
                '02B40ZX', '02B40ZZ', '02C00Z6', '02C00ZZ', '02C10Z6', '02C10ZZ',
                '02C20Z6', '02C20ZZ', '02C30Z6', '02C30ZZ', '02C40ZZ', '02H400Z',
                '02H402Z', '02H403Z', '02H40DZ', '02H40JZ', '02H40KZ', '02H40MZ',
                '02H40NZ', '02H40YZ', '02N00ZZ', '02N10ZZ', '02N20ZZ', '02N30ZZ',
                '02N40ZZ', '02Q00ZZ', '02Q10ZZ', '02Q20ZZ', '02Q30ZZ', '02Q40ZZ',
                '02S10ZZ', '02S00ZZ', '3E07016', '3E07017', '3E070GC', '3E070KZ',
                '3E070PZ')
            or SUBSTR(icd9_code, 1, 3) IN ('361')
            THEN 1 
            ELSE 0 END) AS CABG
        -- AORTIC
        , MAX(CASE WHEN
            icd10_code IN ('024F07J', '024F08J', '024F0JJ', '024F0KJ', '027F04Z', '027F0DZ',
        '02QF0ZJ', '02RF07Z', '02RF08Z', '02RF0JZ', '02RF0KZ', '02UF07J',
        '02UF07Z', '02UF08J', '02UF08Z', '02UF0JJ', '02UF0JZ', '02UF0KJ',
        '02UF0KZ', 'X2RF032')
            or SUBSTR(icd9_code, 1, 4) IN ('3511', '3521', '3522')
            THEN 1 
            ELSE 0 END) AS AORTIC
        -- MITRAL
        , MAX(CASE WHEN
            icd10_code IN ('024G072', '024G082', '024G0J2', '024G0K2', '025G0ZZ', '027G04Z',
            '027G0DZ', '027G0ZZ', '02BG0ZX', '02BG0ZZ', '02CG0ZZ', '02NG0ZZ',
            '02QG0ZE', '02QG0ZZ', '02RG07Z', '02RG08Z', '02RG0JZ', '02RG0KZ',
            '02UG07E', '02UG07Z', '02UG08E', '02UG08Z', '02UG0JE', '02UG0JZ',
            '02UG0KE', '02UG0KZ', '02VG0ZZ', '02WG07Z', '02WG08Z', '02WG0JZ',
            '02WG0KZ')
            or SUBSTR(icd9_code, 1, 4) IN ('3512', '3523', '3524')
            THEN 1 
            ELSE 0 END) AS MITRAL
        -- TRICUSPID
        , MAX(CASE WHEN
            icd10_code IN ('024J072', '024J082', '024J0J2', '024J0K2', '027J04Z', '027J0DZ',
        '02QJ0ZG', '02RJ07Z', '02RJ08Z', '02RJ0JZ', '02RJ0KZ', '02UJ07G',
        '02UJ07Z', '02UJ08G', '02UJ08Z', '02UJ0JG', '02UJ0JZ', '02UJ0KG',
        '02UJ0KZ')
            or SUBSTR(icd9_code, 1, 4) IN ('3514', '3527', '3528')
            THEN 1 
            ELSE 0 END) AS TRICUSPID
        -- PULMONARY
        , MAX(CASE WHEN
            icd_code IN ('027H04Z', '027H0DZ', '02LH0CZ', '02LH0DZ', '02RH07Z', '02RH08Z',
        '02RH0JZ', '02RH0KZ', '02UH07Z', '02UH08Z', '02UH0JZ', '02UH0KZ')
            or SUBSTR(icd9_code, 1, 4) IN ('3513', '3525', '3526')
            THEN 1 
            ELSE 0 END) AS PULMONARY
    FROM `physionet-data.mimic_core.admissions` ad
    LEFT JOIN `physionet-data.mimic_hosp.procedures_icd` AS proc ON ad.hadm_id = proc.hadm_id
    LEFT JOIN procs ON ad.hadm_id = procs.hadm_id
    GROUP BY ad.hadm_id
)
SELECT
  icu.stay_id
  , icu.hadm_id
  , icu2.icustay_seq
  , icu.INTIME AS intime
  , icu.last_careunit as last_careunit
  , surgery.cabg as cabg
  , surgery.aortic as aortic
  , surgery.mitral as mitral
  , surgery.tricuspid as tricuspid
  , surgery.pulmonary as pulmonary
  , surgery.chartdate
  , surgery.procedures

  ,CASE
      WHEN vent.first_vent IS NOT NULL THEN vent.first_vent
    ELSE
    ventsettings.first_vent_settings
  END
    AS postop_intime
  , icu.OUTTIME as outtime
  , multi.multiple_icu_stays
FROM
  `physionet-data.mimic_icu.icustays` icu
  LEFT JOIN `physionet-data.mimic_derived.icustay_detail` AS icu2 ON icu.stay_id = icu2.stay_id
  LEFT JOIN multiple_icu AS multi ON icu.stay_id = multi.stay_id
  LEFT JOIN vent ON icu.stay_id = vent.stay_id
  LEFT JOIN ventsettings  ON icu.stay_id = ventsettings.stay_id
  LEFT JOIN surgery on surgery.hadm_id = icu.hadm_id
