WITH insulin AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, amount, unit) order by charttime) from unnest(insulin) where amount is not null) insulin,
    from (
        select 
            ICUSTAY_ID,
            array_agg(struct(s.charttime, s.amount, s.unit)) insulin,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , AMOUNT as amount
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_cv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
            union all
            select
                ICUSTAY_ID
                , STARTTIME as charttime
                , AMOUNT as amount
                , AMOUNTUOM as unit
            from `physionet-data.mimiciii_clinical.inputevents_mv`
            where (
                ITEMID in (30005, 30180, 5404, 42185, 44236, 43009, 46410, 46418, 46684, 44044, 45669, 42323, 227072, 220970, 226367)
            )
        ) s 
        group by ICUSTAY_ID
    ) d
)
SELECT
-- blood product administration
    ad.icustay_id
    , insulin.insulin as insulin

 FROM
`physionet-data.mimiciii_derived.icustay_detail` ad
LEFT JOIN insulin on ad.ICUSTAY_ID = insulin.ICUSTAY_ID
FILTER_HERE
