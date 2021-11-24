LEFT JOIN `{}.trident.filtertable_mimiciv` AS ft ON ft.stay_id = icu.stay_id
WHERE (
        ft.cabg = 1 or ft.aortic = 1 or ft.mitral = 1 or ft.tricuspid = 1 or ft.pulmonary = 1 
    )  and (
    DATETIME(ft.chartdate, TIME "00:00:00") > DATETIME_SUB(ft.postop_intime, INTERVAL 1 DAY)
    ) and (
    DATETIME(ft.chartdate, TIME "00:00:00")  < DATETIME_ADD(ft.postop_intime, INTERVAL 1 DAY)
    ) and (ft.last_careunit in ('Cardiac Vascular Intensive Care Unit (CVICU)'))
