-- START OFF DEFINING/CODING THE DIFFERENT TYPES OF CARDIAC SURGERIES
WITH surgery AS
-- Code for type of surgery
(
    SELECT
        ad.hadm_id

        -- CABG
        , MAX(CASE WHEN
            icd9_code IN (
                '3603','3610','3611','3612','3613','3614','3615','3616',
                '3617','3619','362','3631','3632','3633'
                )
            THEN 1 
            ELSE 0 END) AS CABG
        -- AORTIC
        , MAX(CASE WHEN
            icd9_code IN ('3511', '3521', '3522')
            THEN 1 
            ELSE 0 END) AS AORTIC
        -- MITRAL
        , MAX(CASE WHEN
            icd9_code IN ('3512', '3523', '3524')
            THEN 1 
            ELSE 0 END) AS MITRAL
        -- TRICUSPID
        , MAX(CASE WHEN
            icd9_code IN ('3514', '3527', '3528')
            THEN 1 
            ELSE 0 END) AS TRICUSPID
        -- PULMONARY
        , MAX(CASE WHEN
            icd9_code IN ('3513', '3525', '3526')
            THEN 1 
            ELSE 0 END) AS PULMONARY
        -- Thoracic Operation
        , MAX(CASE WHEN
            icd9_code IN ('3845')
            THEN 1 
            ELSE 0 END) AS THORACIC
    FROM `physionet-data.mimiciii_clinical.admissions` ad
    FULL OUTER JOIN `physionet-data.mimiciii_clinical.procedures_icd` AS proc ON ad.HADM_ID = proc.hadm_id
    GROUP BY ad.HADM_ID
)
, dt_output AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, output, unit) order by CHARTTIME) from unnest(d.output) where output is not null) output,
    from (
        select 
            s.ICUSTAY_ID,
            array_agg(struct(s.charttime, s.output, s.unit)) output,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , VALUE as output
                , VALUEUOM as unit
            from `physionet-data.mimiciii_clinical.outputevents` as df
            left join `physionet-data.mimiciii_clinical.d_items` as labels on labels.ITEMID = df.ITEMID
            where (
                df.itemid in ( 
                    226588 ,  26589 ,  265890 ,  265891 ,  265892 ,  265893 ,  229413 ,  229414 ,  226619 ,
                    226620 ,  226612 ,  226628 ,  226599 ,  226598 ,  226597 ,  226600 ,  226601 ,  226602 , 
                    42315 ,  42327 ,  42328 ,  42498 ,  42516 ,  42540 ,  40290,  41683 ,  41698 ,  41718 ,  
                    42881 ,  41933 ,  40073 ,  40071 ,  40075 ,  40077 ,  40080 ,  40084 ,   40086 ,  40088 ,  
                    40091 ,  41707 ,  45417 ,  45883 ,  42539 ,  42210 ,  45813 ,  45227 ,  41003 ,  42498 ,  
                    40049 ,  41707 ,  45664 ,  45883 ,  42210 ,  45813 ,  45227 ,  41003 ,  40048 ,  40050 ,  
                    6009 ,  40090 ,  42834 ,  43114 ,  40049 ,  42936 ,  43668 )
            ) or REGEXP_CONTAINS(labels.LABEL, '(?i)(chest|drain|.+).{0,3}(tube|drain)')
            union all
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , VALUENUM as output
                , VALUEUOM as unit
            from `physionet-data.mimiciii_clinical.chartevents` as df
            left join `physionet-data.mimiciii_clinical.d_items` as labels on labels.ITEMID = df.ITEMID
            where ((
                df.itemid in ( 
                    226588 ,  26589 ,  265890 ,  265891 ,  265892 ,  265893 ,  229413 ,  229414 ,  226619 ,
                    226620 ,  226612 ,  226628 ,  226599 ,  226598 ,  226597 ,  226600 ,  226601 ,  226602 , 
                    42315 ,  42327 ,  42328 ,  42498 ,  42516 ,  42540 ,  40290,  41683 ,  41698 ,  41718 ,  
                    42881 ,  41933 ,  40073 ,  40071 ,  40075 ,  40077 ,  40080 ,  40084 ,   40086 ,  40088 ,  
                    40091 ,  41707 ,  45417 ,  45883 ,  42539 ,  42210 ,  45813 ,  45227 ,  41003 ,  42498 ,  
                    40049 ,  41707 ,  45664 ,  45883 ,  42210 ,  45813 ,  45227 ,  41003 ,  40048 ,  40050 ,  
                    6009 ,  40090 ,  42834 ,  43114 ,  40049 ,  42936 ,  43668 )
            ) or REGEXP_CONTAINS(labels.LABEL, '(?i)(chest|drain|.+).{0,3}(tube|drain)'))
                and ERROR is distinct from 1
        ) s
        group by s.ICUSTAY_ID
    ) d
)
, vent AS (
    select
        s.icustay_id,
        (select array_agg(struct(starttime, endtime, duration_hours) order by starttime) from unnest(vent) where duration_hours is not null) vent,
        s.begintime
    from (
        select
            g.icustay_id,
            array_agg(struct(g.starttime, g.endtime, g.duration_hours)) vent,
            min(g.starttime) as begintime
        from `physionet-data.mimiciii_derived.ventilation_durations` g
        group by g.icustay_id
    ) s
)
SELECT
    ad.subject_id as subject_id
    , ad.hadm_id as hadm_id
    , icu.ICUSTAY_ID as stay_id
    , surgery.cabg as cabg
    , surgery.aortic as aortic
    , surgery.mitral as mitral
    , surgery.tricuspid as tricuspid
    , surgery.pulmonary as pulmonary
    , dt_output.output as dtoutput
    , vent.vent as vent_array
    , vent.begintime as postop_intime
FROM `physionet-data.mimiciii_clinical.admissions` ad
LEFT JOIN surgery ON ad.hadm_id = surgery.hadm_id
RIGHT JOIN `physionet-data.mimiciii_clinical.icustays` AS icu ON ad.hadm_id = icu.HADM_ID
LEFT JOIN dt_output on icu.ICUSTAY_ID = dt_output.ICUSTAY_ID
LEFT JOIN vent on icu.ICUSTAY_ID = vent.icustay_id


