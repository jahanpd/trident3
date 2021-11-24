RIGHT JOIN `physionet-data.mimic_icu.icustays` AS icu ON ad.hadm_id = icu.hadm_id
LEFT JOIN `{}.trident.filtertable_mimiciv` AS ft ON ft.stay_id = icu.stay_id
WHERE (
        ft.cabg = 1 or ft.aortic = 1 or ft.mitral = 1 or ft.tricuspid = 1 or ft.pulmonary = 1 
    )  and (DATETIME(ft.chartdate, TIME "00:00:00") > DATETIME_SUB(new_icu_details.derived_icu_intime, INTERVAL 1 DAY)) and (DATETIME(ft.chartdate, TIME "00:00:00")  < DATETIME_ADD(new_icu_details.derived_icu_intime,INTERVAL 1 DAY)) and (icu.last_careunit in ('Cardiac Vascular Intensive Care Unit (CVICU)'))
