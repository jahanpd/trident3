WITH dt_output AS
(
    select
        d.ICUSTAY_ID,
        (select array_agg(struct(charttime, output, unit) order by CHARTTIME) from unnest(d.output) where output is not null) output,
    from (
        select 
            s.ICUSTAY_ID,
            array_agg(struct(s.charttime, s.output, s.unit)) output,
        from (
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , VALUE as output
                , VALUEUOM as unit
            from `physionet-data.mimiciii_clinical.outputevents` as df
            left join `physionet-data.mimiciii_clinical.d_items` as labels on labels.ITEMID = df.ITEMID
            where (
                df.itemid in ( 
                    226588 ,  26589 ,  265890 ,  265891 ,  265892 ,  265893 ,  229413 ,  229414 ,  226619 ,
                    226620 ,  226612 ,  226628 ,  226599 ,  226598 ,  226597 ,  226600 ,  226601 ,  226602 , 
                    42315 ,  42327 ,  42328 ,  42498 ,  42516 ,  42540 ,  40290,  41683 ,  41698 ,  41718 ,  
                    42881 ,  41933 ,  40073 ,  40071 ,  40075 ,  40077 ,  40080 ,  40084 ,   40086 ,  40088 ,  
                    40091 ,  41707 ,  45417 ,  45883 ,  42539 ,  42210 ,  45813 ,  45227 ,  41003 ,  42498 ,  
                    40049 ,  41707 ,  45664 ,  45883 ,  42210 ,  45813 ,  45227 ,  41003 ,  40048 ,  40050 ,  
                    6009 ,  40090 ,  42834 ,  43114 ,  40049 ,  42936 ,  43668 )
            ) or REGEXP_CONTAINS(labels.LABEL, '(?i)(chest|drain|.+).{0,3}(tube|drain)')
            union all
            select
                ICUSTAY_ID
                , CHARTTIME as charttime
                , VALUENUM as output
                , VALUEUOM as unit
            from `physionet-data.mimiciii_clinical.chartevents` as df
            left join `physionet-data.mimiciii_clinical.d_items` as labels on labels.ITEMID = df.ITEMID
            where ((
                df.itemid in ( 
                    226588 ,  26589 ,  265890 ,  265891 ,  265892 ,  265893 ,  229413 ,  229414 ,  226619 ,
                    226620 ,  226612 ,  226628 ,  226599 ,  226598 ,  226597 ,  226600 ,  226601 ,  226602 , 
                    42315 ,  42327 ,  42328 ,  42498 ,  42516 ,  42540 ,  40290,  41683 ,  41698 ,  41718 ,  
                    42881 ,  41933 ,  40073 ,  40071 ,  40075 ,  40077 ,  40080 ,  40084 ,   40086 ,  40088 ,  
                    40091 ,  41707 ,  45417 ,  45883 ,  42539 ,  42210 ,  45813 ,  45227 ,  41003 ,  42498 ,  
                    40049 ,  41707 ,  45664 ,  45883 ,  42210 ,  45813 ,  45227 ,  41003 ,  40048 ,  40050 ,  
                    6009 ,  40090 ,  42834 ,  43114 ,  40049 ,  42936 ,  43668 )
            ) or REGEXP_CONTAINS(labels.LABEL, '(?i)(chest|drain|.+).{0,3}(tube|drain)'))
                and ERROR is distinct from 1
        ) s
        group by s.ICUSTAY_ID
    ) d
)
SELECT
-- blood product administration
    icu.icustay_id as stay_id
    , dt_output.output as dtoutput

 FROM
`physionet-data.mimiciii_derived.icustay_detail` icu
LEFT JOIN dt_output on icu.ICUSTAY_ID = dt_output.ICUSTAY_ID
FILTER_HERE
