with vasocv1 as
(
  select
    icustay_id, charttime
    -- case statement determining whether the ITEMID is an instance of vasopressor usage
    , max(case when itemid in (
        30125,221986, --milrinone
        30043,30307,221662, -- dopamine
        30042,30306,221653, -- dobutamine
        30044,30119,30309,221289, -- epinephrine
        30047,30120,221906, -- norepinephrine
        30127,30128,221749, -- phenylephrine
        30051,222315, -- vasopressin
        30046,227692 -- Isuprel
      ) then 1 else 0 end) as vaso -- dobutamine
    -- the 'stopped' column indicates if a vasopressor has been disconnected
    , max(case when itemid in (
        30125,221986, --milrinone
        30043,30307,221662, -- dopamine
        30042,30306,221653, -- dobutamine
        30044,30119,30309,221289, -- epinephrine
        30047,30120,221906, -- norepinephrine
        30127,30128,221749, -- phenylephrine
        30051,222315, -- vasopressin
        30046,227692 -- Isuprel
      ) and (stopped = 'Stopped' OR stopped like 'D/C%') then 1
          else 0 end) as vaso_stopped
    , max(case when itemid in (
        30125,221986, --milrinone
        30043,30307,221662, -- dopamine
        30042,30306,221653, -- dobutamine
        30044,30119,30309,221289, -- epinephrine
        30047,30120,221906, -- norepinephrine
        30127,30128,221749, -- phenylephrine
        30051,222315, -- vasopressin
        30046,227692 -- Isuprel
      ) and rate is not null then 1 else 0 end) as vaso_null
    , max(case when itemid in (
        30125,221986, --milrinone
        30043,30307,221662, -- dopamine
        30042,30306,221653, -- dobutamine
        30044,30119,30309,221289, -- epinephrine
        30047,30120,221906, -- norepinephrine
        30127,30128,221749, -- phenylephrine
        30051,222315, -- vasopressin
        30046,227692 -- Isuprel
      ) then rate else null end) as vaso_rate
    , max(case when itemid in (
        30125,221986, --milrinone
        30043,30307,221662, -- dopamine
        30042,30306,221653, -- dobutamine
        30044,30119,30309,221289, -- epinephrine
        30047,30120,221906, -- norepinephrine
        30127,30128,221749, -- phenylephrine
        30051,222315, -- vasopressin
        30046,227692 -- Isuprel
      ) then amount else null end) as vaso_amount
  FROM `physionet-data.mimiciii_clinical.inputevents_cv`
  where itemid in (
        30125,221986, --milrinone
        30043,30307,221662, -- dopamine
        30042,30306,221653, -- dobutamine
        30044,30119,30309,221289, -- epinephrine
        30047,30120,221906, -- norepinephrine
        30127,30128,221749, -- phenylephrine
        30051,222315, -- vasopressin
        30046,227692 -- Isuprel
      ) -- dobutamine
  group by icustay_id, charttime
)
, vasocv2 as
(
  select v.*
    , sum(vaso_null) over (partition by icustay_id order by charttime) as vaso_partition
  from
    vasocv1 v
)
, vasocv3 as
(
  select v.*
    , first_value(vaso_rate) over (partition by icustay_id, vaso_partition order by charttime) as vaso_prevrate_ifnull
  from
    vasocv2 v
)
, vasocv4 as
(
select
    icustay_id
    , charttime
    -- , (CHARTTIME - (LAG(CHARTTIME, 1) OVER (partition by icustay_id, vaso order by charttime))) AS delta
    , vaso
    , vaso_rate
    , vaso_amount
    , vaso_stopped
    , vaso_prevrate_ifnull
    -- We define start time here
    , case
        when vaso = 0 then null
        -- if this is the first instance of the vasoactive drug
        when vaso_rate > 0 and
          LAG(vaso_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, vaso, vaso_null
          order by charttime
          )
          is null
          then 1
        -- you often get a string of 0s
        -- we decide not to set these as 1, just because it makes vasonum sequential
        when vaso_rate = 0 and
          LAG(vaso_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, vaso
          order by charttime
          )
          = 0
          then 0
        -- sometimes you get a string of NULL, associated with 0 volumes
        -- same reason as before, we decide not to set these as 1
        -- vaso_prevrate_ifnull is equal to the previous value *iff* the current value is null
        when vaso_prevrate_ifnull = 0 and
          LAG(vaso_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, vaso
          order by charttime
          )
          = 0
          then 0
        -- If the last recorded rate was 0, newvaso = 1
        when LAG(vaso_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, vaso
          order by charttime
          ) = 0
          then 1
        -- If the last recorded vaso was D/C'd, newvaso = 1
        when
          LAG(vaso_stopped,1)
          OVER
          (
          partition by icustay_id, vaso
          order by charttime
          )
          = 1 then 1
        -- ** not sure if the below is needed
        --when (CHARTTIME - (LAG(CHARTTIME, 1) OVER (partition by icustay_id, vaso order by charttime))) > (interval '4 hours') then 1
      else null
      end as vaso_start
FROM
  vasocv3
)
-- propagate start/stop flags forward in time
, vasocv5 as
(
  select v.*
    , SUM(vaso_start) OVER (partition by icustay_id, vaso order by charttime) as vaso_first
FROM
  vasocv4 v
)
, vasocv6 as
(
  select v.*
    -- We define end time here
    , case
        when vaso = 0
          then null
        -- If the recorded vaso was D/C'd, this is an end time
        when vaso_stopped = 1
          then vaso_first
        -- If the rate is zero, this is the end time
        when vaso_rate = 0
          then vaso_first
        -- the last row in the table is always a potential end time
        -- this captures patients who die/are discharged while on vasopressors
        -- in principle, this could add an extra end time for the vasopressor
        -- however, since we later group on vaso_start, any extra end times are ignored
        when LEAD(CHARTTIME,1)
          OVER
          (
          partition by icustay_id, vaso
          order by charttime
          ) is null
          then vaso_first
        else null
        end as vaso_stop
    from vasocv5 v
)
-- -- if you want to look at the results of the table before grouping:
-- select
--   icustay_id, charttime, vaso, vaso_rate, vaso_amount
--     , case when vaso_stopped = 1 then 'Y' else '' end as stopped
--     , vaso_start
--     , vaso_first
--     , vaso_stop
-- from vasocv6 order by charttime;
, vasocv as
(
-- below groups together vasopressor administrations into groups
select
  icustay_id
  -- the first non-null rate is considered the starttime
  , min(case when vaso_rate is not null then charttime else null end) as starttime
  -- the *first* time the first/last flags agree is the stop time for this duration
  , min(case when vaso_first = vaso_stop then charttime else null end) as endtime
from vasocv6
where
  vaso_first is not null -- bogus data
and
  vaso_first != 0 -- sometimes *only* a rate of 0 appears, i.e. the drug is never actually delivered
and
  icustay_id is not null -- there are data for "floating" admissions, we don't worry about these
group by icustay_id, vaso_first
having -- ensure start time is not the same as end time
 min(charttime) != min(case when vaso_first = vaso_stop then charttime else null end)
and
  max(vaso_rate) > 0 -- if the rate was always 0 or null, we consider it not a real drug delivery
)
-- now we extract the associated data for metavision patients
, vasomv as
(
  select
    icustay_id, linkorderid
    , min(starttime) as starttime, max(endtime) as endtime
  FROM `physionet-data.mimiciii_clinical.inputevents_mv`
  where itemid IN (
    30125,221986, --milrinone
    30043,30307,221662, -- dopamine
    30042,30306,221653, -- dobutamine
    30044,30119,30309,221289, -- epinephrine
    30047,30120,221906, -- norepinephrine
    30127,30128,221749, -- phenylephrine
    30051,222315, -- vasopressin
    30046,227692 -- Isuprel
  )
  and statusdescription != 'Rewritten' -- only valid orders
  group by icustay_id, linkorderid
)

select 
    s.stay_id as stay_id,
    array_agg(struct( starttime, endtime, duration)) inotropes
from
    (
    select
      icustay_id as stay_id
      -- generate a sequential integer for convenience
      , ROW_NUMBER() over (partition by icustay_id order by starttime) as vasonum
      , starttime, endtime
      , DATETIME_DIFF(endtime, starttime, HOUR) AS duration
      -- add durations
    from
      vasocv
    UNION ALL
    select
      icustay_id as stay_id
      , ROW_NUMBER() over (partition by icustay_id order by starttime) as vasonum
      , starttime, endtime
      , DATETIME_DIFF(endtime, starttime, HOUR) AS duration
      -- add durations
    from
      vasomv
    ) s
LEFT JOIN `physionet-data.mimiciii_derived.icustay_detail` icu ON icu.icustay_id = s.stay_id
FILTER_HERE
group by s.stay_id
