WITH vent AS (
    select
        s.icustay_id,
        (select array_agg(struct(starttime, endtime, duration_hours) order by starttime) 
            from (select distinct * from unnest(vent) where duration_hours is not null)) vent,
    from (
        select
            g.icustay_id,
            array_agg(struct(g.starttime, g.endtime, g.duration_hours)) vent
        from `physionet-data.mimiciii_derived.ventilation_durations` g
        group by g.icustay_id
    ) s
)
SELECT
-- blood product administration
    icu.icustay_id as stay_id
    , vent.vent as vent_array
    , (CASE WHEN
            ARRAY_LENGTH(vent.vent) > 1
        THEN 1
        ELSE 0 END ) as reintubation
    , (CASE WHEN
            ARRAY_LENGTH(vent.vent) > 1
        THEN vent.vent[ORDINAL(2)].starttime
        ELSE null END ) as reint_time
    , (vent.vent[ORDINAL(1)].endtime) ext_time
 FROM
`physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN vent on icu.ICUSTAY_ID = vent.ICUSTAY_ID
FILTER_HERE
