WITH dt_output AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, output, unit) order by charttime) 
            from (select distinct * from unnest(output) where output is not null)) output,
    from (
        select 
            stay_id,
            array_agg(struct(CHARTTIME as charttime, VALUE as output, VALUEUOM as unit)) output,
        from `physionet-data.mimic_icu.outputevents` as df
        left join `physionet-data.mimic_icu.d_items` as labels on labels.itemid = df.itemid
        where REGEXP_CONTAINS(labels.label, '(?i)(chest|drain|.+).{0,3}(tube|drain)')
        group by stay_id
    ) s
)
SELECT
    icu.stay_id
    , dt_output.output as dtoutput
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN dt_output on dt_output.stay_id = icu.stay_id
FILTER_HERE
