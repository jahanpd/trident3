WITH fb AS
(
    select
        s.icustay_id,
        (select 
            array_agg(
                struct(
                    starttime,
                    endtime,
                    rate_all,
                    balance
                ) order by starttime)
            from (SELECT 
                    DISTINCT *, 
                    sum(volume) over (ORDER BY starttime ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as balance 
                    FROM UNNEST(fb)) 
            where rate_all is not null
        ) balance,
    from (
        select 
        g.icustay_id,
        array_agg( struct(starttime, endtime, rate_all, date_diff(endtime, starttime, hour) * rate_all as volume)) fb
        from `physionet-data.mimiciii_derived.fluid_balance` g
        group by g.icustay_id
    ) s
)
SELECT
    fb.icustay_id as stay_id
    , fb.balance as fluid_balance
FROM
`physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN fb on icu.ICUSTAY_ID = fb.ICUSTAY_ID
FILTER_HERE
