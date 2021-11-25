WITH insulin AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, amount, unit) order by charttime) 
            from (select distinct * from unnest(insulin) where amount is not null)) insulin,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as charttime, amount, amountuom as unit)) insulin,
        from `physionet-data.mimic_icu.inputevents` as df
        left join `physionet-data.mimic_icu.d_items` as labels on labels.itemid = df.itemid
        where CONTAINS_SUBSTR(labels.LABEL, 'insulin')
        group by stay_id
    ) s
)
SELECT
    icu.stay_id as stay_id
    , insulin.insulin as insulin
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN insulin ON icu.stay_id = insulin.stay_id
FILTER_HERE
