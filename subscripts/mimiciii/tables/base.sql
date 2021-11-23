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
    , ad.hospital_expire_flag as hospital_expire_flag
    , ad.DEATHTIME as deathtime
    , pat.dod as dod
FROM `physionet-data.mimiciii_clinical.admissions` ad
RIGHT JOIN `physionet-data.mimiciii_derived.icustay_detail` AS icu2 ON ad.HADM_ID = icu2.hadm_id
LEFT JOIN `physionet-data.mimiciii_clinical.patients` AS pat ON icu2.SUBJECT_ID = pat.subject_id
LEFT JOIN `physionet-data.mimiciii_derived.heightweight`AS body ON icu2.icustay_id = body.icustay_id
FILTER_HERE
