LEFT JOIN `{}.trident.filtertable_mimiciii` AS ft ON ft.stay_id = icu.icustay_id
WHERE (
    ft.cabg = 1 or ft.aortic = 1 or ft.mitral = 1 or ft.tricuspid = 1 or ft.pulmonary = 1
) --and (first_careunit in ('CSRU'))  and (last_careunit in ('CSRU'))
and ft.postop_intime is not null
and icu.intime < ft.postop_intime
and icu.outtime > ft.postop_intime

