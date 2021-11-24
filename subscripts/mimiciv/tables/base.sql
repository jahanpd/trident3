SELECT
    -- stay details and demographics
    ad.subject_id as subject_id
    , ad.hadm_id as hadm_id
    , icu.STAY_ID as stay_id
    , icu.admission_age as age
    , pat.gender as gender
    , icu.ethnicity as ethnicity
    , height.height as height
    , weight.weight as weight
    , ad.admission_type as admission_type
    , ad.admission_location as admission_location
    , ad.admittime as admittime
    , ad.dischtime as dischtime
    , icu.ICU_INTIME as intime
    , icu.ICU_OUTTIME as outtime
    , ad.insurance as insurance
    , ad.MARITAL_STATUS as marital_status
    , ad.LANGUAGE as language
    , icu.icustay_seq as icustay_seq
    , icu2.los as los
    , icu2.first_careunit as first_careunit
    , icu2.last_careunit as last_careunit
    , ad.hospital_expire_flag as hospital_expire_flag
    , ad.DEATHTIME as deathtime
    , pat.dod as dod
    , sofa.sofa as sofa
    , ft.postop_intime as postop_intime
    , ft.cabg
    , ft.aortic
    , ft.mitral
    , ft.tricuspid
    , ft.pulmonary
FROM `physionet-data.mimic_core.admissions` ad
RIGHT JOIN `physionet-data.mimic_derived.icustay_detail` AS icu ON ad.HADM_ID = icu.hadm_id
LEFT JOIN `physionet-data.mimic_icu.icustays` as icu2 on icu2.STAY_ID = icu.stay_id
LEFT JOIN `physionet-data.mimic_core.patients` AS pat ON icu.SUBJECT_ID = pat.subject_id
LEFT JOIN `physionet-data.mimic_derived.first_day_sofa` sofa ON icu.stay_id = sofa.stay_id
LEFT JOIN `physionet-data.mimic_derived.height`AS height ON icu.stay_id = height.stay_id
LEFT JOIN `physionet-data.mimic_derived.first_day_weight`AS weight ON icu.stay_id = weight.stay_id
FILTER_HERE
