WITH vent AS (
    select
        s.stay_id,
        (select min(starttime) from unnest (vent)) start_vent,
        (select array_agg(struct(starttime, endtime, duration_hours) order by starttime) 
            from (select distinct * from unnest(vent) where duration_hours is not null)) vent,
    from (
        select
            g.stay_id,
            array_agg(struct(g.starttime, g.endtime, DATETIME_DIFF(g.endtime, g.starttime, HOUR) as duration_hours )) vent
        from `physionet-data.mimic_derived.ventilation` g
        where g.ventilation_status = 'InvasiveVent'
        group by g.stay_id
    ) s
)
, ventsettings AS (
    select
        s.stay_id,
        (select min(charttime) from unnest(vent)) start_vent,
        (select array_agg(
            struct(
                charttime, rrset, rrtotal, rrspont, minute_volume, tvset, tvobs, tvspont, plat, peep, fio2, mode, mode_ham, type
                ) order by charttime) 
        from (select distinct * from unnest(vent) where mode is not null or mode_ham is not null)) vent,
    from (
        select
            stay_id,
            array_agg(struct(
                charttime,
                respiratory_rate_set as rrset,
                respiratory_rate_total as rrtotal,
                respiratory_rate_spontaneous as rrspont,
                minute_volume,
                tidal_volume_set as tvset,
                tidal_volume_observed as tvobs,
                tidal_volume_spontaneous as tvspont,
                plateau_pressure as plat,
                peep,
                fio2,
                ventilator_mode as mode,
                ventilator_mode_hamilton as mode_ham,
                ventilator_type as type
                )) vent
        from `physionet-data.mimic_derived.ventilator_setting`
        group by stay_id
    ) s
)
SELECT
    icu.stay_id
    , ventsettings.vent as ventsettings
    -- outcomes
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
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN ventsettings ON icu.stay_id = ventsettings.stay_id
LEFT JOIN vent on icu.stay_id = vent.stay_id
FILTER_HERE
