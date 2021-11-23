select
    s.hadm_id,
    (select array_agg(struct(
    CHARTTIME, STORETIME, CATEGORY, cast(REGEXP_REPLACE(EF[ordinal(1)], '[^0-9]','') as int64 ) as VALUE) order by CHARTTIME) from unnest(s.note)
    WHERE ((ARRAY_LENGTH(EF) > 0))) echo,
FROM 
(
    SELECT notes.hadm_id,
        array_agg(struct(
            notes.CHARTTIME, notes.STORETIME, notes.CATEGORY, 
            REGEXP_EXTRACT_ALL(TEXT, '(?i)(?: EF|LVEF|EJECTION FRACTION)\W+(?:\w+){0,3}?(?:\>|\<|)(?:\s){0,4}(?:\d){2}(?:\s){0,4}(?:\%|per|)') as EF
            )) note,
        min(icu.intime) as intime
    from `physionet-data.mimiciii_notes.noteevents` notes
    LEFT JOIN `physionet-data.mimiciii_clinical.icustays` AS icu ON notes.HADM_ID = icu.hadm_id
    group by notes.hadm_id
) s
LEFT JOIN `physionet-data.mimiciii_notes.noteevents` notes on s.hadm_id = notes.HADM_ID
LEFT JOIN `physionet-data.mimiciii_clinical.icustays` AS icu ON notes.HADM_ID = icu.hadm_id
LEFT JOIN `physionet-data.mimiciii_clinical.admissions` ad ON ad.HADM_ID = notes.HADM_ID
FILTER_HERE
group by notes.hadm_id

