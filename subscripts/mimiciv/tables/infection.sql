WITH infection AS (
    select
        s.stay_id
        , (select array_agg(struct(suspected_infection_time, antibiotic_time, antibiotic, specimen, positiveculture)
                order by suspected_infection_time) 
               from (select distinct * from unnest(inf))) inf
    from (
        select
            g.stay_id,
            array_agg(struct(g.suspected_infection_time, g.antibiotic_time, g.antibiotic, g.specimen, g.positive_culture as positiveculture)) inf
        from `physionet-data.mimic_derived.suspicion_of_infection` g
        group by g.stay_id
    ) s
)
SELECT
    icu.stay_id
    , infection.inf as infection
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN infection on infection.stay_id = icu.stay_id
FILTER_HERE
