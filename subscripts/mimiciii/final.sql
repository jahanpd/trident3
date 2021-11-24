SELECT *
FROM
`{}.trident.base_mimiciii` base
`{}.trident.aki_mimiciii` aki on aki.stay_id == base.stay_id
`{}.trident._mimiciii` aki on aki.stay_id == base.stay_id

