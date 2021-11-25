WITH diag AS
-- prepare ICD diagnosis codes for comorbidities, need to combine icd 9 and 10 codes
(
    SELECT 
        hadm_id
        , CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
        , CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
    FROM `physionet-data.mimic_hosp.diagnoses_icd` diag
)
, icu_times AS (
    SELECT
        hadm_id,
        array_agg(struct(icu_intime, icu_outtime) order by icu_intime) icustay_array
    FROM `physionet-data.mimic_derived.icustay_detail` 
    GROUP BY hadm_id
)
, com AS
-- prepare comorbidites according to charleston comorb index
(
    SELECT
        ad.hadm_id

        -- Myocardial infarction
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN ('410','412')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I21','I22')
            OR
            SUBSTR(icd10_code, 1, 4) = 'I252'
            THEN 1 
            ELSE 0 END) AS myocardial_infarct

        -- Arrhythmia
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN ('427')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I48')
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
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I43','I50')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I099','I110','I130','I132','I255','I420',
                                                    'I425','I426','I427','I428','I429','P290')
            THEN 1 
            ELSE 0 END) AS congestive_heart_failure

        -- Peripheral vascular disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('440','441')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('0930','4373','4471','5571','5579','V434')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '4431' AND '4439'
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I70','I71')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I731','I738','I739','I771','I790',
                                                    'I792','K551','K558','K559','Z958','Z959')
            THEN 1 
            ELSE 0 END) AS peripheral_vascular_disease

        -- Cerebrovascular disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '430' AND '438'
            OR
            SUBSTR(icd9_code, 1, 5) = '36234'
            OR
            SUBSTR(icd10_code, 1, 3) IN ('G45','G46')
            OR 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'I60' AND 'I69'
            OR
            SUBSTR(icd10_code, 1, 4) = 'H340'
            THEN 1 
            ELSE 0 END) AS cerebrovascular_disease

        -- Dementia
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '290'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('2941','3312')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('F00','F01','F02','F03','G30')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('F051','G311')
            THEN 1 
            ELSE 0 END) AS dementia

        -- Chronic pulmonary disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '490' AND '505'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('4168','4169','5064','5081','5088')
            OR 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'J40' AND 'J47'
            OR 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'J60' AND 'J67'
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I278','I279','J684','J701','J703')
            THEN 1 
            ELSE 0 END) AS chronic_pulmonary_disease

        -- Rheumatic disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '725'
            OR
           SUBSTR(icd9_code, 1, 4) IN ('4465','7100','7101','7102','7103',
                                                    '7104','7140','7141','7142','7148')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('M05','M06','M32','M33','M34')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('M315','M351','M353','M360')
            THEN 1 
            ELSE 0 END) AS rheumatic_disease

        -- Peptic ulcer disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('531','532','533','534')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('K25','K26','K27','K28')
            THEN 1 
            ELSE 0 END) AS peptic_ulcer_disease

        -- Mild liver disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('570','571')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('0706','0709','5733','5734','5738','5739','V427')
            OR
            SUBSTR(icd9_code, 1, 5) IN ('07022','07023','07032','07033','07044','07054')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('B18','K73','K74')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('K700','K701','K702','K703','K709','K713',
                                                    'K714','K715','K717','K760','K762',
                                                    'K763','K764','K768','K769','Z944')
            THEN 1 
            ELSE 0 END) AS mild_liver_disease

        -- Diabetes without chronic complication
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('2500','2501','2502','2503','2508','2509') 
            OR
            SUBSTR(icd10_code, 1, 4) IN ('E100','E10l','E106','E108','E109','E110','E111',
                                                    'E116','E118','E119','E120','E121','E126','E128',
                                                    'E129','E130','E131','E136','E138','E139','E140',
                                                    'E141','E146','E148','E149')
            THEN 1 
            ELSE 0 END) AS diabetes_without_cc

        -- Diabetes with chronic complication
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('2504','2505','2506','2507')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('E102','E103','E104','E105','E107','E112','E113',
                                                    'E114','E115','E117','E122','E123','E124','E125',
                                                    'E127','E132','E133','E134','E135','E137','E142',
                                                    'E143','E144','E145','E147')
            THEN 1 
            ELSE 0 END) AS diabetes_with_cc

        -- Type 1 Diabetes
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 5) IN (
                '25001','25003','25011','25013','25021','25023','25031',
                '25033','25041','25043','25051','25053','25061','25063','25071',
                '25073','25081','25083','25091','25093')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('E10')
            THEN 1 
            ELSE 0 END) AS t1dm
        
        -- Type 2 Diabetes
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 5) IN (
            '25000','25002','25010','25012','25020','25022','25030','25032','25040',
            '25042','25050','25052','25060','25062','25070','25072','25080','25082',
            '25090','25092')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('E11')
            THEN 1 
            ELSE 0 END) AS t2dm
        
        -- Hemiplegia or paraplegia
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('342','343')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('3341','3440','3441','3442',
                                                    '3443','3444','3445','3446','3449')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('G81','G82')
            OR 
            SUBSTR(icd10_code, 1, 4) IN ('G041','G114','G801','G802','G830',
                                                    'G831','G832','G833','G834','G839')
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
            OR
            SUBSTR(icd10_code, 1, 3) IN ('N18','N19')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I120','I131','N032','N033','N034',
                                                    'N035','N036','N037','N052','N053',
                                            'N054','N055','N056','N057','N250',
                                                    'Z490','Z491','Z492','Z940','Z992')
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
            OR
            SUBSTR(icd10_code, 1, 3) IN ('C43','C88')
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C00' AND 'C26'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C30' AND 'C34'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C37' AND 'C41'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C45' AND 'C58'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C60' AND 'C76'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C81' AND 'C85'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C90' AND 'C97'
            THEN 1 
            ELSE 0 END) AS malignant_cancer

        -- Moderate or severe liver disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('4560','4561','4562')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '5722' AND '5728'
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I850','I859','I864','I982','K704','K711',
                                                    'K721','K729','K765','K766','K767')
            THEN 1 
            ELSE 0 END) AS severe_liver_disease

        -- Metastatic solid tumor
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('196','197','198','199')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('C77','C78','C79','C80')
            THEN 1 
            ELSE 0 END) AS metastatic_solid_tumor

        -- AIDS/HIV
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('042','043','044')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('B20','B21','B22','B24')
            THEN 1 
            ELSE 0 END) AS aids

        -- SMOKING
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('V15')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('Z87', 'F17')
            THEN 1 
            ELSE 0 END) AS smoking
        -- MENTAL AND BEHAVIOURAL DISORDERS DUE TO USE OF:
        -- OPIOIDS
        -- opioid dependence
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 4) IN ('F112')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('3040')
            THEN 1
            ELSE 0 END) AS opioid_dependence_disorders
            -- opioid abuse
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 4) IN ('F111')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('3055')
            THEN 1
            ELSE 0 END) AS opioid_abuse_disorders
             -- opioid use
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 4) IN ('F119')
            THEN 1
            ELSE 0 END) AS opioid_use_disorders
            -- opioid other
        ,MAX(CASE WHEN 
            icd10_code IN ('F11')
            THEN 1
            ELSE 0 END) AS opioid_other_disorders
        -- ALCOHOL (includes both dependence and harmful use, in remission, continuous, episodic etc.) Also includes any acute intoxication, hangover or drunkenness.
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 3) IN ('F10')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('3050')
            OR
            SUBSTR(icd9_code, 1, 3) IN ('303','291')
            THEN 1
            ELSE 0 END) AS alcohol_use_disorders
        -- OTHER DRUGS (includes both dependence and harmful use, in remission, continuous, episodic etc.) 
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'F12' AND 'F19'
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '3041' AND '3049'
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '3051' AND '3054'
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '3056' AND '3059'
            OR
            SUBSTR(icd9_code, 1, 3) IN ('303','292')
            THEN 1
            ELSE 0 END) AS other_drug_use_disorders
     -- Organic mental disorders 
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'F00' AND 'F09'
            OR
            SUBSTR(icd9_code, 1, 3) BETWEEN '293' AND '294'
            OR
            SUBSTR(icd9_code, 1, 3) IN ('290')
            THEN 1
            ELSE 0 END) AS organic_mental_disorders
            -- Non-organic psychoses
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'F20' AND 'F29'
            OR
            SUBSTR(icd9_code, 1, 3) BETWEEN '297' AND '299'
            OR
            SUBSTR(icd9_code, 1, 3) IN ('295')
            THEN 1
            ELSE 0 END) AS psychotic_disorders
            -- Mood disorders
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'F30' AND 'F39'
            OR
            SUBSTR(icd9_code, 1, 3) IN ('296')
            THEN 1
            ELSE 0 END) AS mood_disorders
             -- Personality and behavioural disorders
        ,MAX(CASE WHEN 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'F60' AND 'F69'
            OR
            SUBSTR(icd9_code, 1, 3) IN ('301','302')
            THEN 1
            ELSE 0 END) AS personality_disorders
            --Chronic pain 
            ,MAX(CASE WHEN 
            (icd10_code IN ('G546','G890','G892', 'G8921','G8922','G8928','G8929','G893','G894','R392'))
            OR
             (SUBSTR(icd10_code, 1, 4) IN ('G905'))
             OR
            SUBSTR(icd9_code, 1, 4) IN ('3382','3383', '3384', '3380')
            THEN 1
            ELSE 0 END) AS chronic_pain_conditions
    FROM `physionet-data.mimic_core.admissions` ad
    LEFT JOIN diag
    ON ad.hadm_id = diag.hadm_id
    GROUP BY ad.hadm_id
)

SELECT
    -- comorbidities
    icu.stay_id
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
    , com.opioid_dependence_disorders as opioid_dependence_disorders
    , com.opioid_use_disorders as opioid_use_disorders
    , com.opioid_abuse_disorders as opioid_abuse_disorders
    , com.opioid_other_disorders as opioid_other_disorders
    , com.alcohol_use_disorders as alcohol_use_disorders
    , com.other_drug_use_disorders as other_drug_use_disorders
    , com.organic_mental_disorders as organic_mental_disorders
    , com.psychotic_disorders as psychotic_disorders
    , com.mood_disorders as mood_disorders
    , com.personality_disorders as personality_disorders
    , com.chronic_pain_conditions as chronic_pain_conditions
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN com on com.hadm_id = icu.hadm_id
FILTER_HERE
