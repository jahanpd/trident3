SELECT
    -- stay details and demographics
    ad.subject_id as subject_id
    , ad.hadm_id as hadm_id
    , icu.ICUSTAY_ID as stay_id
    , icu.admission_age as age
    , pat.gender as gender
    , icu.ethnicity_grouped as ethnicity
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
    , icu.icustay_seq as icustay_seq
    , icu2.los as los
    , icu2.first_careunit as first_careunit
    , icu2.last_careunit as last_careunit
    , icu2.DBSOURCE as dbsource
    , ad.hospital_expire_flag as hospital_expire_flag
    , ad.DEATHTIME as deathtime
    , pat.dod as dod
    , sofa.sofa
    , ft.postop_intime as postop_intime
FROM `physionet-data.mimiciii_clinical.admissions` ad
RIGHT JOIN `physionet-data.mimiciii_derived.icustay_detail` AS icu ON ad.HADM_ID = icu.hadm_id
LEFT JOIN `physionet-data.mimiciii_clinical.icustays` as icu2 on icu2.ICUSTAY_ID = icu.icustay_id
LEFT JOIN `physionet-data.mimiciii_clinical.patients` AS pat ON icu.SUBJECT_ID = pat.subject_id
LEFT JOIN `physionet-data.mimiciii_derived.heightweight`AS body ON icu.icustay_id = body.icustay_id
LEFT JOIN `physionet-data.mimiciii_derived.sofa` sofa ON icu.ICUSTAY_ID = sofa.icustay_id
FILTER_HERE
