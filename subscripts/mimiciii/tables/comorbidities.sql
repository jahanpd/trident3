WITH com as (
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
SELECT
    ad.icustay_id as stay_id   
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
FROM `physionet-data.mimiciii_derived.icustay_detail` ad
LEFT JOIN com ON com.hadm_id = ad.hadm_id
FILTER_HERE

