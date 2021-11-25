LEFT JOIN `{}.trident.filtertable_mimiciv` AS ft ON ft.stay_id = icu.stay_id
WHERE (
        ft.cabg = 1 or ft.aortic = 1 or ft.mitral = 1 or ft.tricuspid = 1 or ft.pulmonary = 1 
    )  
and ABS((DATE_DIFF(DATE(ft.chartdate), DATE(ft.postop_intime), DAY))) <= 1 
