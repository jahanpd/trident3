LEFT JOIN `{}.trident.filtertable_mimiciii` AS ft ON ft.stay_id = icu.icustay_id
WHERE (
    ft.cabg = 1 or ft.aortic = 1 or ft.mitral = 1 or ft.tricuspid = 1 or ft.pulmonary = 1
) --and (first_careunit in ('CSRU'))  and (last_careunit in ('CSRU'))
and array_length(ft.vent_array)>0 and array_length(ft.dtoutput)>0
and ft.icustay_seq = 1
