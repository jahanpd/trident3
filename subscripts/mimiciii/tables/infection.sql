WITH infection AS (
    select
        s.icustay_id,
        (select array_agg(struct(suspected_infection_time, antibiotic_time, antibiotic, specimen, positiveculture) order by suspected_infection_time) from unnest(inf)) inf,
    from (
        select
            g.icustay_id,
            array_agg(struct(g.suspected_infection_time, g.antibiotic_time, g.antibiotic_name as antibiotic, g.specimen, g.positiveculture)) inf
        from `physionet-data.mimiciii_derived.suspicion_of_infection` g
        group by g.icustay_id
    ) s
)
SELECT
-- blood product administration
    ad.icustay_id
    , infection.inf as infection
 FROM
`physionet-data.mimiciii_derived.icustay_detail` ad
LEFT JOIN infection on ad.ICUSTAY_ID = infection.ICUSTAY_ID
FILTER_HERE
