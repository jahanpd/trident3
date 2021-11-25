WITH inotropes as (
    SELECT 
        s.stay_id, 
        array_agg(struct(linkorderid, inotrope_duration, inotrope, starttime, endtime)) as inotrope 
    FROM
        (
        SELECT 
            stay_id,
            linkorderid, 
            DATETIME_DIFF(endtime, starttime, HOUR) AS inotrope_duration,
            starttime,
            endtime,
            CASE 
                WHEN itemid=221986 THEN 'milrinone'
                WHEN itemid=221662 THEN 'dopamine'
                WHEN itemid=221653 THEN 'dobutamine'
                WHEN itemid IN (221289, 221289, 229617, 229617) THEN 'epinephrine'
                WHEN itemid=221906 THEN 'norepinephrine'
                WHEN itemid IN (221749, 229632, 229630) THEN 'phenylephrine'
                WHEN itemid=222315 THEN 'vasopressin'
                WHEN itemid=227692 THEN 'isuprel'
            ELSE null
            END AS inotrope
        FROM `physionet-data.mimic_icu.inputevents`
        WHERE itemid IN (
        221986, --Milrinone
        221662, --Dopamine
        221653, --Dobutamine
        221289, 221289, 229617, 229617,  --Epinephrine
        221906, --Norepinephrine
        221749, 229632, 229630, -- Phenylephrine
        222315, --Vasopressin
        227692 --Isuprel
        )
    ) s
    GROUP BY s.stay_id
)
SELECT
    icu.stay_id
    , inotropes.inotrope as inotropes
FROM `physionet-data.mimic_derived.icustay_detail` AS icu
LEFT JOIN inotropes ON icu.stay_id = inotropes.stay_id
FILTER_HERE
