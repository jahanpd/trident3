select
    icu.icustay_id as stay_id,
    (select array_agg(struct(
    CHARTTIME, STORETIME, CATEGORY, cast(REGEXP_REPLACE(EF[ordinal(1)], '[^0-9]','') as int64 ) as VALUE) order by CHARTTIME) from unnest(s.note)
    WHERE ((ARRAY_LENGTH(EF) > 0))) echo,
FROM 
(
    SELECT notes.hadm_id,
        array_agg(struct(
            notes.CHARTTIME, notes.STORETIME, notes.CATEGORY, 
            REGEXP_EXTRACT_ALL(TEXT, r'(?i)(?: EF|LVEF|EJECTION FRACTION)\W+(?:\w+){0,3}?(?:\>|\<|)(?:\s){0,4}(?:\d){2}(?:\s){0,4}(?:\%|per|)') as EF
            )) note,
        min(icu.intime) as intime
    from `physionet-data.mimiciii_notes.noteevents` notes
    LEFT JOIN `physionet-data.mimiciii_clinical.icustays` AS icu ON notes.HADM_ID = icu.hadm_id
    group by notes.hadm_id
) s
RIGHT JOIN `physionet-data.mimiciii_derived.icustay_detail` icu ON icu.HADM_ID = s.hadm_id
FILTER_HERE


