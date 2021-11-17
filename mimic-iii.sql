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
, pc AS
-- Get procedure codes 
(
    SELECT array_agg(icd9_code) as ICD_CODES, hadm_id as HADM_ID
    FROM `physionet-data.mimiciii_clinical.procedures_icd`
    GROUP BY HADM_ID
)
, com AS
-- prepare comorbidites according to charleston comorb index
(
    SELECT
        ad.hadm_id
        -- Myocardial infarction
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN ('410','412')
            THEN 1 
            ELSE 0 END) AS myocardial_infarct

        -- Arrhythmia
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN ('427')
            THEN 1 
            ELSE 0 END) AS arrhythmia

        -- Congestive heart failure
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '428'
            OR
            SUBSTR(icd9_code, 1, 5) IN ('39891','40201','40211','40291','40401','40403',
                            '40411','40413','40491','40493')
            OR 
            SUBSTR(icd9_code, 1, 4) BETWEEN '4254' AND '4259'
            THEN 1 
            ELSE 0 END) AS congestive_heart_failure

        -- Peripheral vascular disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('440','441')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('0930','4373','4471','5571','5579','V434')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '4431' AND '4439'
            THEN 1 
            ELSE 0 END) AS peripheral_vascular_disease

        -- Cerebrovascular disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '430' AND '438'
            OR
            SUBSTR(icd9_code, 1, 5) = '36234'
            THEN 1 
            ELSE 0 END) AS cerebrovascular_disease

        -- Dementia
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '290'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('2941','3312')
            THEN 1 
            ELSE 0 END) AS dementia

        -- Chronic pulmonary disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '490' AND '505'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('4168','4169','5064','5081','5088')
            THEN 1 
            ELSE 0 END) AS chronic_pulmonary_disease

        -- Rheumatic disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '725'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('4465','7100','7101','7102','7103',
                                                    '7104','7140','7141','7142','7148')
            THEN 1 
            ELSE 0 END) AS rheumatic_disease

        -- Peptic ulcer disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('531','532','533','534')
            THEN 1 
            ELSE 0 END) AS peptic_ulcer_disease

        -- Mild liver disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('570','571')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('0706','0709','5733','5734','5738','5739','V427')
            OR
            SUBSTR(icd9_code, 1, 5) IN ('07022','07023','07032','07033','07044','07054')
            THEN 1 
            ELSE 0 END) AS mild_liver_disease

        -- Diabetes without chronic complication
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('2500','2501','2502','2503','2508','2509') 
            THEN 1 
            ELSE 0 END) AS diabetes_without_cc

        -- Diabetes with chronic complication
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('2504','2505','2506','2507')
            THEN 1 
            ELSE 0 END) AS diabetes_with_cc

        -- T1DM
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN (
                '25001','25003','25011','25013','25021','25023','25031',
                '25033','25041','25043','25051','25053','25061','25063','25071',
                '25073','25081','25083','25091','25093')
            THEN 1 
            ELSE 0 END) AS t1dm
        -- T2DM
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN (
            '25000','25002','25010','25012','25020','25022','25030','25032','25040',
            '25042','25050','25052','25060','25062','25070','25072','25080','25082',
            '25090','25092')
            THEN 1 
            ELSE 0 END) AS t2dm
        -- Hemiplegia or paraplegia
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('342','343')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('3341','3440','3441','3442',
                                                    '3443','3444','3445','3446','3449')
            THEN 1 
            ELSE 0 END) AS paraplegia

        -- Renal disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('582','585','586','V56')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('5880','V420','V451')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '5830' AND '5837'
            OR
            SUBSTR(icd9_code, 1, 5) IN ('40301','40311','40391','40402','40403','40412','40413','40492','40493')          
            THEN 1 
            ELSE 0 END) AS renal_disease

        -- Any malignancy, including lymphoma and leukemia, except malignant neoplasm of skin
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '140' AND '172'
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '1740' AND '1958'
            OR
            SUBSTR(icd9_code, 1, 3) BETWEEN '200' AND '208'
            OR
            SUBSTR(icd9_code, 1, 4) = '2386'
            THEN 1 
            ELSE 0 END) AS malignant_cancer

        -- Moderate or severe liver disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('4560','4561','4562')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '5722' AND '5728'
            THEN 1 
            ELSE 0 END) AS severe_liver_disease

        -- Metastatic solid tumor
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('196','197','198','199')
            THEN 1 
            ELSE 0 END) AS metastatic_solid_tumor

        -- AIDS/HIV
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('042','043','044')
            THEN 1 
            ELSE 0 END) AS aids

        -- SMOKING
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('V15')
            THEN 1 
            ELSE 0 END) AS smoking
        -- NEED TO ADD EXTRA DEPRESSION/OPIOID DEPENDENCE COMORBS

    FROM `physionet-data.mimiciii_clinical.diagnoses_icd` ad
    GROUP BY ad.hadm_id
)
-- ECHO EF AS A STRING EXTRACTED FROM REGEX
, echos AS
(
    select
        s.hadm_id,
        (select array_agg(struct(
        CHARTTIME, STORETIME, CATEGORY, cast(REGEXP_REPLACE(EF[ordinal(1)], '[^0-9]','') as int64 ) as VALUE) order by CHARTTIME) from unnest(note)
        where ((ARRAY_LENGTH(EF) > 0))) echo,
    from (
        SELECT notes.hadm_id,
            array_agg(struct(
                notes.CHARTTIME, notes.STORETIME, notes.CATEGORY, 
                REGEXP_EXTRACT_ALL(TEXT, r'(?i)(?: EF|LVEF|EJECTION FRACTION)\W+(?:\w+){0,3}?(?:\>|\<|)(?:\s){0,4}(?:\d){2}(?:\s){0,4}(?:\%|per|)') as EF
                )) note,
            min(icu.intime) as intime
    from `physionet-data.mimiciii_notes.noteevents` notes
    LEFT JOIN `physionet-data.mimiciii_clinical.icustays` AS icu ON notes.HADM_ID = icu.hadm_id
    group by notes.hadm_id
    ) s
)
, bloods AS
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
, vitals AS 
(
    select 
        s.icustay_id,
        (select array_agg(struct(charttime, HeartRate as value) order by charttime)
        from unnest(vit) where HeartRate is not null) hr,
        (select array_agg(struct(charttime, SysBP as value) order by charttime)
        from unnest(vit) where SysBP is not null) sbp,
        (select array_agg(struct(charttime, DiasBP as value) order by charttime)
        from unnest(vit) where DiasBP is not null) dbp,
        (select array_agg(struct(charttime, MeanBP as value) order by charttime)
        from unnest(vit) where MeanBP is not null) meanbp,
        (select array_agg(struct(charttime, RespRate as value) order by charttime)
        from unnest(vit) where RespRate is not null) rr,
        (select array_agg(struct(charttime, TempC as value) order by charttime)
        from unnest(vit) where TempC is not null) temp,
        (select array_agg(struct(charttime, SpO2 as value) order by charttime)
        from unnest(vit) where SpO2 is not null) spo2
    from (
        select
            t.icustay_id,
            array_agg(struct(t.charttime, t.HeartRate, t.SysBP, t.DiasBP, t.MeanBP, t.RespRate, t.TempC, t.SpO2, t.Glucose)) vit
        from `physionet-data.mimiciii_derived.pivoted_vital` t
        group by t.icustay_id
    ) s
)
, cardiac_index AS
(
    select
        s.icustay_id,
        (select array_agg(struct(charttime, ci) order by charttime) from unnest(ci) where ci is not null) ci,
    from (
        select 
            g.icustay_id,
            array_agg(struct(g.charttime, g.valuenum as ci)) ci
        from `physionet-data.mimiciii_clinical.chartevents` g
        where 
            itemid in (228177, 226859, 228368, 226859, 116, 7610)
            and ERROR is distinct from 1
        group by g.icustay_id
    ) s
)
-- blood procuct tables
, prbcs AS
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
-- drain tube output
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
            where REGEXP_CONTAINS(labels.LABEL, '(?i)(chest|drain|.+).{0,3}(tube|drain)')
            union all
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , VALUENUM as output
                , VALUEUOM as unit
            from `physionet-data.mimiciii_clinical.chartevents` as df
            left join `physionet-data.mimiciii_clinical.d_items` as labels on labels.ITEMID = df.ITEMID
            where 
                REGEXP_CONTAINS(labels.LABEL, '(?i)(chest|drain|.+).{0,3}(tube|drain)')
                and ERROR is distinct from 1
        ) s
        group by s.ICUSTAY_ID
    ) d
)
, insulin AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, amount, unit) order by charttime) from unnest(insulin) where amount is not null) insulin,
    from (
        select 
            ICUSTAY_ID,
            array_agg(struct(s.charttime, s.amount, s.unit)) insulin,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , AMOUNT as amount
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_cv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
            union all
            select
                ICUSTAY_ID
                , STARTTIME as charttime
                , AMOUNT as amount
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_mv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
        ) s 
        group by ICUSTAY_ID
    ) d
)
, vent AS (
    select
        s.icustay_id,
        (select array_agg(struct(starttime, endtime, duration_hours) order by starttime) from unnest(vent) where duration_hours is not null) vent,
    from (
        select
            g.icustay_id,
            array_agg(struct(g.starttime, g.endtime, g.duration_hours)) vent
        from `physionet-data.mimiciii_derived.ventilation_durations` g
        group by g.icustay_id
    ) s
)
, aki AS
(
    select
        s.icustay_id,
        (select array_agg(struct(charttime, aki_stage_creat, aki_stage_uo) order by charttime) from unnest(aki) where aki is not null) aki,
    from (
        select 
        g.icustay_id,
        array_agg(struct(g.charttime, g.aki_stage_creat, g.aki_stage_uo)) aki
        from `physionet-data.mimiciii_derived.kdigo_stages` g
        group by g.icustay_id
    ) s
)
, infection AS (
    select
        s.icustay_id,
        (select array_agg(struct(suspected_infection_time, antibiotic_time, antibiotic, specimen, positiveculture) order by suspected_infection_time) from unnest(inf)) inf,
    from (
        select
            g.icustay_id,
            array_agg(struct(g.suspected_infection_time, g.antibiotic_time, g.antibiotic_name as antibiotic, g.specimen, g.positiveculture)) inf
        from `physionet-data.mimiciii_derived.suspicion_of_infection` g
        group by g.icustay_id
    ) s
)
-- select features for final dataset
-- comment out any unnecessary features
SELECT
    -- stay details and demographics
    ad.subject_id as subject_id
    , ad.hadm_id as hadm_id
    , icu.ICUSTAY_ID as stay_id
    , pat.gender as gender
    , icu2.ethnicity_grouped as ethnicity
    , body.height_first as height
    , body.weight_first as weight
    , ad.admission_type as admission_type
    , ad.admission_location as admission_location
    , ad.admittime as admittime
    , ad.dischtime as dischtime
    , icu.INTIME as intime
    , icu.OUTTIME as outtime
    , ad.insurance as insurance
    , ad.MARITAL_STATUS as marital_status
    , ad.LANGUAGE as language
    , icu2.icustay_seq as icustay_seq
    , icu.los as los
    , icu.first_careunit as first_careunit
    , icu.last_careunit as last_careunit
    , icu.DBSOURCE as dbsource
    -- surgery types NOTE CAN BE MULTIPLE TYPES eg cabg + valve
    , surgery.cabg as cabg
    , surgery.aortic as aortic
    , surgery.mitral as mit
    , surgery.tricuspid as tricuspid
    , surgery.pulmonary as pulmonary
    -- comorbidities
    , com.myocardial_infarct as mi
    , com.arrhythmia as arrhythmia
    , com.congestive_heart_failure as ccf
    , com.peripheral_vascular_disease as pvd
    , com.cerebrovascular_disease as cvd
    , com.dementia as dementia
    , com.chronic_pulmonary_disease as copd
    , com.rheumatic_disease as rheum
    , com.peptic_ulcer_disease as pud
    , com.mild_liver_disease as liver_mild
    , com.diabetes_without_cc as diab_un
    , com.diabetes_with_cc as diab_cc
    , com.t1dm as t1dm
    , com.t2dm as t2dm
    , com.paraplegia as paraplegia
    , com.renal_disease as ckd
    , com.malignant_cancer as malig
    , com.severe_liver_disease as liver_severe
    , com.metastatic_solid_tumor as met_ca
    , com.aids as aids
    , com.smoking as smoking
    -- vitals
    , vitals.hr as hr
    , vitals.sbp as sbp
    , vitals.dbp as dbp
    , vitals.meanbp as meanbp
    , vitals.rr as rr
    , vitals.temp as temp
    , vitals.spo2 as spo2
    -- bloods
    -- bloods, these need to be filtered accoring to admission times
    -- as original datatable above is grouped by subject id which
    -- captures community results as well (eg for hba1c), but means
    -- each array could have multiple hospital or icu admissions
    -- blood gases
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
    -- insulin use
    , insulin.insulin as insulin
    -- other CV variables
    , cardiac_index.ci as cardiac_index
    , echos.echo as ef
    -- blood product administration
    , prbcs.bloodproduct as prbc
    , plts.bloodproduct as plts
    , ffp.bloodproduct as ffp
    , cryo.bloodproduct as cryo
    -- outcomes
    , dt_output.output as dtoutput
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
    , infection.inf as infection
    , ad.hospital_expire_flag as hospital_expire_flag
    , ad.DEATHTIME as deathtime
    , pat.dod as dod
    -- , aki.aki as aki
-- join tables to select variables
-- start with demo/patient detail tables
FROM `physionet-data.mimiciii_clinical.admissions` ad
LEFT JOIN surgery ON ad.hadm_id = surgery.hadm_id
RIGHT JOIN `physionet-data.mimiciii_clinical.icustays` AS icu ON ad.hadm_id = icu.HADM_ID
LEFT JOIN `physionet-data.mimiciii_derived.icustay_detail` AS icu2 ON icu.ICUSTAY_ID = icu2.icustay_id
LEFT JOIN `physionet-data.mimiciii_clinical.patients` AS pat ON icu.SUBJECT_ID = pat.subject_id
LEFT JOIN `physionet-data.mimiciii_derived.heightweight`AS body ON icu.icustay_id = body.icustay_id
-- join in the comorb table
LEFT JOIN com ON icu.hadm_id = com.hadm_id
-- vitals
LEFT JOIN vitals ON icu.ICUSTAY_ID = vitals.icustay_id
-- join the bloods table
LEFT JOIN bloods ON icu.subject_id = bloods.subject_id
LEFT JOIN glucose ON icu.subject_id = glucose.subject_id
-- joic CV physiology tables 
LEFT JOIN cardiac_index ON icu.ICUSTAY_ID = cardiac_index.icustay_id
LEFT JOIN echos ON icu.hadm_id = echos.hadm_id
-- blood product tables
LEFT JOIN prbcs ON icu.ICUSTAY_ID = prbcs.ICUSTAY_ID
LEFT JOIN plts ON icu.ICUSTAY_ID = plts.ICUSTAY_ID
LEFT JOIN ffp ON icu.ICUSTAY_ID = ffp.ICUSTAY_ID
LEFT JOIN cryo ON icu.ICUSTAY_ID = cryo.ICUSTAY_ID
LEFT JOIN infection on icu.ICUSTAY_ID = infection.ICUSTAY_ID
LEFT JOIN insulin ON icu.ICUSTAY_ID = insulin.ICUSTAY_ID
-- outcome tables
LEFT JOIN dt_output on icu.ICUSTAY_ID = dt_output.ICUSTAY_ID
LEFT JOIN vent on icu.ICUSTAY_ID = vent.icustay_id
LEFT JOIN aki ON icu.ICUSTAY_ID = aki.icustay_id
-- filter for only the CTS patients
WHERE (
    surgery.cabg = 1 or surgery.aortic = 1 or surgery.mitral = 1 or surgery.tricuspid = 1 or surgery.pulmonary = 1
) and (icu2.icustay_seq = 1)
