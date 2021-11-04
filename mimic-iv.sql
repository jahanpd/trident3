WITH diag AS
-- prepare ICD diagnosis codes for comorbidities, need to combine icd 9 and 10 codes
(
    SELECT 
        hadm_id
        , CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
        , CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
    FROM `physionet-data.mimic_hosp.diagnoses_icd` diag
)
, com AS
-- prepare comorbidites according to charleston comorb index
(
    SELECT
        ad.hadm_id

        -- Myocardial infarction
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN ('410','412')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I21','I22')
            OR
            SUBSTR(icd10_code, 1, 4) = 'I252'
            THEN 1 
            ELSE 0 END) AS myocardial_infarct

        -- Arrhythmia
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 3) IN ('427')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I48')
            THEN 1 
            ELSE 0 END) AS arrhythmia

        -- Congestive heart failure
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '428'
            OR
            SUBSTR(icd9_code, 1, 5) IN ('39891','40201','40211','40291','40401','40403',
                            '40411','40413','40491','40493')
            OR 
            SUBSTR(icd9_code, 1, 4) BETWEEN '4254' AND '4259'
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I43','I50')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I099','I110','I130','I132','I255','I420',
                                                    'I425','I426','I427','I428','I429','P290')
            THEN 1 
            ELSE 0 END) AS congestive_heart_failure

        -- Peripheral vascular disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('440','441')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('0930','4373','4471','5571','5579','V434')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '4431' AND '4439'
            OR
            SUBSTR(icd10_code, 1, 3) IN ('I70','I71')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I731','I738','I739','I771','I790',
                                                    'I792','K551','K558','K559','Z958','Z959')
            THEN 1 
            ELSE 0 END) AS peripheral_vascular_disease

        -- Cerebrovascular disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '430' AND '438'
            OR
            SUBSTR(icd9_code, 1, 5) = '36234'
            OR
            SUBSTR(icd10_code, 1, 3) IN ('G45','G46')
            OR 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'I60' AND 'I69'
            OR
            SUBSTR(icd10_code, 1, 4) = 'H340'
            THEN 1 
            ELSE 0 END) AS cerebrovascular_disease

        -- Dementia
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '290'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('2941','3312')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('F00','F01','F02','F03','G30')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('F051','G311')
            THEN 1 
            ELSE 0 END) AS dementia

        -- Chronic pulmonary disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '490' AND '505'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('4168','4169','5064','5081','5088')
            OR 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'J40' AND 'J47'
            OR 
            SUBSTR(icd10_code, 1, 3) BETWEEN 'J60' AND 'J67'
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I278','I279','J684','J701','J703')
            THEN 1 
            ELSE 0 END) AS chronic_pulmonary_disease

        -- Rheumatic disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) = '725'
            OR
            SUBSTR(icd9_code, 1, 4) IN ('4465','7100','7101','7102','7103',
                                                    '7104','7140','7141','7142','7148')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('M05','M06','M32','M33','M34')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('M315','M351','M353','M360')
            THEN 1 
            ELSE 0 END) AS rheumatic_disease

        -- Peptic ulcer disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('531','532','533','534')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('K25','K26','K27','K28')
            THEN 1 
            ELSE 0 END) AS peptic_ulcer_disease

        -- Mild liver disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('570','571')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('0706','0709','5733','5734','5738','5739','V427')
            OR
            SUBSTR(icd9_code, 1, 5) IN ('07022','07023','07032','07033','07044','07054')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('B18','K73','K74')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('K700','K701','K702','K703','K709','K713',
                                                    'K714','K715','K717','K760','K762',
                                                    'K763','K764','K768','K769','Z944')
            THEN 1 
            ELSE 0 END) AS mild_liver_disease

        -- Diabetes without chronic complication
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('2500','2501','2502','2503','2508','2509') 
            OR
            SUBSTR(icd10_code, 1, 4) IN ('E100','E10l','E106','E108','E109','E110','E111',
                                                    'E116','E118','E119','E120','E121','E126','E128',
                                                    'E129','E130','E131','E136','E138','E139','E140',
                                                    'E141','E146','E148','E149')
            THEN 1 
            ELSE 0 END) AS diabetes_without_cc

        -- Diabetes with chronic complication
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('2504','2505','2506','2507')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('E102','E103','E104','E105','E107','E112','E113',
                                                    'E114','E115','E117','E122','E123','E124','E125',
                                                    'E127','E132','E133','E134','E135','E137','E142',
                                                    'E143','E144','E145','E147')
            THEN 1 
            ELSE 0 END) AS diabetes_with_cc

        -- Type 1 Diabetes
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 5) IN (
                '25001','25003','25011','25013','25021','25023','25031',
                '25033','25041','25043','25051','25053','25061','25063','25071',
                '25073','25081','25083','25091','25093')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('E10')
            THEN 1 
            ELSE 0 END) AS t1dm
        
        -- Type 2 Diabetes
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 5) IN (
            '25000','25002','25010','25012','25020','25022','25030','25032','25040',
            '25042','25050','25052','25060','25062','25070','25072','25080','25082',
            '25090','25092')
            OR
            SUBSTR(icd10_code, 1, 3) IN ('E11')
            THEN 1 
            ELSE 0 END) AS t2dm
        
        -- Hemiplegia or paraplegia
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('342','343')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('3341','3440','3441','3442',
                                                    '3443','3444','3445','3446','3449')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('G81','G82')
            OR 
            SUBSTR(icd10_code, 1, 4) IN ('G041','G114','G801','G802','G830',
                                                    'G831','G832','G833','G834','G839')
            THEN 1 
            ELSE 0 END) AS paraplegia

        -- Renal disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('582','585','586','V56')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('5880','V420','V451')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '5830' AND '5837'
            OR
            SUBSTR(icd9_code, 1, 5) IN ('40301','40311','40391','40402','40403','40412','40413','40492','40493')          
            OR
            SUBSTR(icd10_code, 1, 3) IN ('N18','N19')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I120','I131','N032','N033','N034',
                                                    'N035','N036','N037','N052','N053',
                                                    'N054','N055','N056','N057','N250',
                                                    'Z490','Z491','Z492','Z940','Z992')
            THEN 1 
            ELSE 0 END) AS renal_disease

        -- Any malignancy, including lymphoma and leukemia, except malignant neoplasm of skin
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) BETWEEN '140' AND '172'
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '1740' AND '1958'
            OR
            SUBSTR(icd9_code, 1, 3) BETWEEN '200' AND '208'
            OR
            SUBSTR(icd9_code, 1, 4) = '2386'
            OR
            SUBSTR(icd10_code, 1, 3) IN ('C43','C88')
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C00' AND 'C26'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C30' AND 'C34'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C37' AND 'C41'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C45' AND 'C58'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C60' AND 'C76'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C81' AND 'C85'
            OR
            SUBSTR(icd10_code, 1, 3) BETWEEN 'C90' AND 'C97'
            THEN 1 
            ELSE 0 END) AS malignant_cancer

        -- Moderate or severe liver disease
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 4) IN ('4560','4561','4562')
            OR
            SUBSTR(icd9_code, 1, 4) BETWEEN '5722' AND '5728'
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I850','I859','I864','I982','K704','K711',
                                                    'K721','K729','K765','K766','K767')
            THEN 1 
            ELSE 0 END) AS severe_liver_disease

        -- Metastatic solid tumor
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('196','197','198','199')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('C77','C78','C79','C80')
            THEN 1 
            ELSE 0 END) AS metastatic_solid_tumor

        -- AIDS/HIV
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('042','043','044')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('B20','B21','B22','B24')
            THEN 1 
            ELSE 0 END) AS aids

        -- SMOKING
        , MAX(CASE WHEN 
            SUBSTR(icd9_code, 1, 3) IN ('V15')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('Z87', 'F17')
            THEN 1 
            ELSE 0 END) AS smoking
    FROM `physionet-data.mimic_core.admissions` ad
    LEFT JOIN diag
    ON ad.hadm_id = diag.hadm_id
    GROUP BY ad.hadm_id
)
, procs AS
-- prepare ICD diagnosis codes for comorbidities
(
    SELECT 
        hadm_id
        , CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
        , CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
    FROM `physionet-data.mimic_hosp.procedures_icd` diag
)
, surgery AS
-- Code for type of surgery
(
    SELECT
        ad.hadm_id

        -- CABG
        , MAX(CASE WHEN
            icd10_code IN ('210083', '210088', '210089', '021008C', '021008F', '021008W',
                '210093', '210098', '210099', '021009C', '021009F', '021009W',
                '02100A3', '02100A8', '02100A9', '02100AC', '02100AF', '02100AW',
                '02100J3', '02100J8', '02100J9', '02100JC', '02100JF', '02100JW',
                '02100K3', '02100K8', '02100K9', '02100KC', '02100KF', '02100KW',
                '02100Z3', '02100Z8', '02100Z9', '02100ZC', '02100ZF', '02110Z9',
                '211083', '211088', '211089', '021108C', '021108F', '021108W',
                '211093', '211098', '211099', '021109C', '021109F', '021109W',
                '02110A3', '02110A8', '02110A9', '02110AC', '02110AF', '02110AW',
                '02110J3', '02110J8', '02110J9', '02110JC', '02110JF', '02110JW',
                '02110K3', '02110K8', '02110K9', '02110KC', '02110KF', '02110KW',
                '02110Z3', '02110Z8', '02110ZC', '02110ZF', '212083', '212088',
                '212089', '021208C', '021208F', '021208W', '212093', '212098',
                '212099', '021209C', '021209F', '021209W', '02120A3', '02120A8',
                '02120A9', '02120AC', '02120AF', '02120AW', '02120J3', '02120J8',
                '02120J9', '02120JC', '02120JF', '02120JW', '02120K3', '02120K8',
                '02120K9', '02120KC', '02120KF', '02120KW', '02120Z3', '02120Z8',
                '02120Z9', '02120ZC', '02120ZF', '213083', '213088', '213089',
                '021308C', '021308F', '021308W', '213093', '213098', '213099',
                '021309C', '021309F', '021309W', '02130A3', '02130A8', '02130A9',
                '02130AC', '02130AF', '02130AW', '02130J3', '02130J8', '02130J9',
                '02130JC', '02130JF', '02130JW', '02130K3', '02130K8', '02130K9',
                '02130KC', '02130KF', '02130KW', '02130Z3', '02130Z8', '02130Z9',
                '02130ZC', '02130ZF', '021K0Z5', '021L0Z5', '02540ZZ', '270046',
                '027004Z', '270056', '027005Z', '270066', '027006Z', '270076',
                '027007Z', '02700D6', '02700DZ', '2.70E+09', '02700EZ', '02700F6',
                '02700FZ', '02700G6', '02700GZ', '02700T6', '02700TZ', '02700Z6',
                '02700ZZ', '271046', '027104Z', '271056', '027105Z', '271066',
                '027106Z', '271076', '027107Z', '02710D6', '02710DZ', '2.71E+09',
                '02710EZ', '02710F6', '02710FZ', '02710G6', '02710GZ', '02710T6',
                '02710TZ', '02710Z6', '02710ZZ', '272046', '027204Z', '272056',
                '027205Z', '272066', '027206Z', '272076', '027207Z', '02720D6',
                '02720DZ', '2.72E+09', '02720EZ', '02720F6', '02720FZ', '02720G6',
                '02720GZ', '02720T6', '02720TZ', '02720Z6', '02720ZZ', '273046',
                '027304Z', '273056', '027305Z', '273066', '027306Z', '027307Z',
                '02730D6', '02730DZ', '2.73E+09', '02730EZ', '02730F6', '02730FZ',
                '02730G6', '02730GZ', '02730T6', '02730TZ', '02730Z6', '02730ZZ',
                '02B40ZX', '02B40ZZ', '02C00Z6', '02C00ZZ', '02C10Z6', '02C10ZZ',
                '02C20Z6', '02C20ZZ', '02C30Z6', '02C30ZZ', '02C40ZZ', '02H400Z',
                '02H402Z', '02H403Z', '02H40DZ', '02H40JZ', '02H40KZ', '02H40MZ',
                '02H40NZ', '02H40YZ', '02N00ZZ', '02N10ZZ', '02N20ZZ', '02N30ZZ',
                '02N40ZZ', '02Q00ZZ', '02Q10ZZ', '02Q20ZZ', '02Q30ZZ', '02Q40ZZ',
                '02S10ZZ', '02S00ZZ', '3E07016', '3E07017', '3E070GC', '3E070KZ',
                '3E070PZ')
            or SUBSTR(icd9_code, 1, 3) IN ('361')
            THEN 1 
            ELSE 0 END) AS CABG
        -- AORTIC
        , MAX(CASE WHEN
            icd10_code IN ('024F07J', '024F08J', '024F0JJ', '024F0KJ', '027F04Z', '027F0DZ',
        '02QF0ZJ', '02RF07Z', '02RF08Z', '02RF0JZ', '02RF0KZ', '02UF07J',
        '02UF07Z', '02UF08J', '02UF08Z', '02UF0JJ', '02UF0JZ', '02UF0KJ',
        '02UF0KZ', 'X2RF032')
            or SUBSTR(icd9_code, 1, 4) IN ('3511', '3521', '3522')
            THEN 1 
            ELSE 0 END) AS AORTIC
        -- MITRAL
        , MAX(CASE WHEN
            icd10_code IN ('024G072', '024G082', '024G0J2', '024G0K2', '025G0ZZ', '027G04Z',
            '027G0DZ', '027G0ZZ', '02BG0ZX', '02BG0ZZ', '02CG0ZZ', '02NG0ZZ',
            '02QG0ZE', '02QG0ZZ', '02RG07Z', '02RG08Z', '02RG0JZ', '02RG0KZ',
            '02UG07E', '02UG07Z', '02UG08E', '02UG08Z', '02UG0JE', '02UG0JZ',
            '02UG0KE', '02UG0KZ', '02VG0ZZ', '02WG07Z', '02WG08Z', '02WG0JZ',
            '02WG0KZ')
            or SUBSTR(icd9_code, 1, 4) IN ('3512', '3523', '3524')
            THEN 1 
            ELSE 0 END) AS MITRAL
        -- TRICUSPID
        , MAX(CASE WHEN
            icd10_code IN ('024J072', '024J082', '024J0J2', '024J0K2', '027J04Z', '027J0DZ',
        '02QJ0ZG', '02RJ07Z', '02RJ08Z', '02RJ0JZ', '02RJ0KZ', '02UJ07G',
        '02UJ07Z', '02UJ08G', '02UJ08Z', '02UJ0JG', '02UJ0JZ', '02UJ0KG',
        '02UJ0KZ')
            or SUBSTR(icd9_code, 1, 4) IN ('3514', '3527', '3528')
            THEN 1 
            ELSE 0 END) AS TRICUSPID
        -- PULMONARY
        , MAX(CASE WHEN
            icd_code IN ('027H04Z', '027H0DZ', '02LH0CZ', '02LH0DZ', '02RH07Z', '02RH08Z',
        '02RH0JZ', '02RH0KZ', '02UH07Z', '02UH08Z', '02UH0JZ', '02UH0KZ')
            or SUBSTR(icd9_code, 1, 4) IN ('3513', '3525', '3526')
            THEN 1 
            ELSE 0 END) AS PULMONARY
    FROM `physionet-data.mimic_core.admissions` ad
    LEFT JOIN `physionet-data.mimic_hosp.procedures_icd` AS proc ON ad.hadm_id = proc.hadm_id
    LEFT JOIN procs ON ad.hadm_id = procs.hadm_id
    GROUP BY ad.hadm_id
)
, bloods AS
(
    select
        s.subject_id
        -- blood gas values (combined with biochem and fbe in itemids)
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50820) and VALUENUM is not null) pH
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50882) and VALUENUM is not null) bicarb 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50802) and VALUENUM is not null) baseexcess
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50806, 50902, 52434) and VALUENUM is not null) chloride
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50808) and VALUENUM is not null) free_calcium 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50931, 50809, 52027) and VALUENUM is not null) glucose
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50971, 50822, 52452, 52610) and VALUENUM is not null) potassium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50824, 52455, 50983, 52623) and VALUENUM is not null) sodium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50813, 52442) and VALUENUM is not null) lactate
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (52028, 50810, 51638, 51639) and VALUENUM is not null) hematocrit
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51222, 50811, 51640) and VALUENUM is not null) hb
        -- partial pressures and o2 from blood gas
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50818) and VALUENUM is not null) pco2
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50821) and VALUENUM is not null) po2
        -- auxillary blood gas information
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50825) and VALUENUM is not null) bg_temp 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50816) and VALUENUM is not null) fio2
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50827) and VALUENUM is not null) ventrate
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50826) and VALUENUM is not null) tidalvol
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50801) and VALUENUM is not null) aado2 
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50800, 52028) and VALUENUM is not null) specimen
        -- other bloods
        -- FBE
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51256, 51697) and VALUENUM is not null) neutrophils
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51244, 51690) and VALUENUM is not null) lymphocytes
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51300, 51301, 51755, 51756) and VALUENUM is not null) wcc
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51265, 51704) and VALUENUM is not null) plt
        -- inflammatory
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50889) and VALUENUM is not null) crp
        -- LFTs and BIOCHEM (if electrolyte not in blood gas)
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (52022, 50862, 51542) and VALUENUM is not null) albumin
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (52024, 50912, 52546) and VALUENUM is not null) creatinine
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51006, 52647) and VALUENUM is not null) bun
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50960) and VALUENUM is not null) magnesium
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50861) and VALUENUM is not null) alt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50863) and VALUENUM is not null) alp
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50878) and VALUENUM is not null) ast
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50927) and VALUENUM is not null) ggt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50885) and VALUENUM is not null) bilirubin_total
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50883) and VALUENUM is not null) bilirubin_direct
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50884) and VALUENUM is not null) bilirubin_indirect
        -- coags
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51237) and VALUENUM is not null) inr
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51213, 51214) and VALUENUM is not null) fibrinogen
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51149) and VALUENUM is not null) bleed_time
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51274) and VALUENUM is not null) pt
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (51275) and VALUENUM is not null) ptt 

        -- other eg hba1c
        , (select array_agg(struct(charttime, VALUENUM as value) order by charttime) from unnest(bloods) 
        where ITEMID in (50852) and VALUENUM is not null) hba1c

    from (
        SELECT le.subject_id,
            array_agg(struct(le.itemid as ITEMID, le.charttime, le.valuenum as VALUENUM)) bloods,
        FROM `physionet-data.mimic_hosp.labevents` le
        GROUP BY le.subject_id
    ) s
)
, vitals AS 
(
    select 
        s.stay_id,
        (select array_agg(struct(charttime, heart_rate as value) order by charttime)
        from unnest(vit) where heart_rate is not null) hr,
        (select array_agg(struct(charttime, sbp as value) order by charttime)
        from unnest(vit) where sbp is not null) sbp,
        (select array_agg(struct(charttime, dbp as value) order by charttime)
        from unnest(vit) where dbp is not null) dbp,
        (select array_agg(struct(charttime, mbp as value) order by charttime)
        from unnest(vit) where mbp is not null) meanbp,
        (select array_agg(struct(charttime, resp_rate as value) order by charttime)
        from unnest(vit) where resp_rate is not null) rr,
        (select array_agg(struct(charttime, temperature as value) order by charttime)
        from unnest(vit) where temperature is not null) temp,
        (select array_agg(struct(charttime, spo2 as value) order by charttime)
        from unnest(vit) where spo2 is not null) spo2
    from (
        select
            t.stay_id,
            array_agg(struct(t.charttime, t.heart_rate, t.sbp, t.dbp, t.mbp, t.resp_rate, t.temperature, t.spo2, t.glucose)) vit
        from `physionet-data.mimic_derived.vitalsign` t
        group by t.stay_id
    ) s
)
, cardiac_index AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, ci) order by charttime) from unnest(ci) where ci is not null) ci,
    from (
        select 
            g.stay_id,
            array_agg(struct(g.charttime, g.valuenum as ci)) ci
        from `physionet-data.mimic_icu.chartevents` g
        where itemid in (228368, 228177)
        group by g.stay_id
    ) s
)
-- blood procuct tables 
, prbcs AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (225168, 226370, 221013, 226368, 227070)
        )
        group by stay_id
    ) s
)
, plts AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (225170, 226369, 227071)
        )
        group by stay_id
    ) s
)
, ffp AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (226367, 227072, 220970)
        )
        group by stay_id
    ) s
)
, cryo AS
(
    select
        s.stay_id,
        (select array_agg(struct(starttime, bloodproduct, unit) order by starttime) from unnest(bloodproduct) where bloodproduct is not null) bloodproduct,
    from (
        select 
            stay_id,
            array_agg(struct(starttime as starttime, amount as bloodproduct, amountuom as unit)) bloodproduct,
        from `physionet-data.mimic_icu.inputevents`
        where (
            ITEMID in (225171, 226371)
        )
        group by stay_id
    ) s
)
, dt_output AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, output, unit) order by charttime) from unnest(output) where output is not null) output,
    from (
        select 
            stay_id,
            array_agg(struct(CHARTTIME as charttime, VALUE as output, VALUEUOM as unit)) output,
        from `physionet-data.mimic_icu.outputevents` as df
        left join `physionet-data.mimic_icu.d_items` as labels on labels.itemid = df.itemid
        where CONTAINS_SUBSTR(labels.LABEL, 'drain') and CONTAINS_SUBSTR(labels.linksto, 'outputevents')
        group by stay_id
    ) s
)
, insulin AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, amount, unit) order by charttime) from unnest(insulin) where amount is not null) insulin,
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
, vent AS (
    select
        s.stay_id,
        (select array_agg(struct(starttime, endtime, duration_hours) order by starttime) from unnest(vent) where duration_hours is not null) vent,
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
        (select array_agg(
            struct(
                charttime, rrset, rrtotal, rrspont, minute_volume, tvset, tvobs, tvspont, plat, peep, fio2, mode, mode_ham, type
                ) order by charttime) from unnest(vent) where mode is not null or mode_ham is not null) vent,
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
, aki AS
(
    select
        s.stay_id,
        (select array_agg(struct(charttime, aki_stage_creat, aki_stage_uo) order by charttime) from unnest(aki) where aki is not null) aki,
    from (
        select 
        g.stay_id,
        array_agg(struct(g.charttime, g.aki_stage_creat, g.aki_stage_uo)) aki
        from `physionet-data.mimic_derived.kdigo_stages` g
        group by g.stay_id
    ) s
)
, infection AS (
    select
        s.stay_id,
        (select array_agg(struct(suspected_infection_time, antibiotic_time, antibiotic, specimen, positiveculture) order by suspected_infection_time) from unnest(inf)) inf,
    from (
        select
            g.stay_id,
            array_agg(struct(g.suspected_infection_time, g.antibiotic_time, g.antibiotic, g.specimen, g.positive_culture as positiveculture)) inf
        from `physionet-data.mimic_derived.suspicion_of_infection` g
        group by g.stay_id
    ) s
)
-- select features for final dataset
-- comment out any unnecessary features
SELECT
    -- stay details and demographics
    ad.subject_id as subject_id
    , ad.hadm_id as hadm_id
    , icu.stay_id as icustay_id
    , pat.gender as gender
    , icu2.ethnicity as ethnicity
    , height.height as height
    , weight.weight as weight
    , ad.admission_type as admission_type
    , ad.admission_location as admission_location
    , ad.admittime as admittime
    , ad.dischtime as dischtime
    , icu.intime as intime
    , icu.outtime as outtime
    , ad.insurance as insurance
    , ad.marital_status as marital_status
    , ad.language as language
    , icu2.icustay_seq as icustay_seq
    , icu.los as los
    , icu.first_careunit as first_careunit
    , icu.last_careunit as last_careunit
    -- surgery types NOTE CAN BE MULTIPLE TYPES eg cabg + valve
    , surgery.cabg as cabg
    , surgery.aortic as aortic
    , surgery.mitral as mit
    , surgery.tricuspid as tricuspid
    , surgery.pulmonary as pulmonary
    -- comorbidities
    , com.myocardial_infarct as mi
    , com.arrhythmia as arrhythmia
    , com.congestive_heart_failure as ccf
    , com.peripheral_vascular_disease as pvd
    , com.cerebrovascular_disease as cvd
    , com.dementia as dementia
    , com.chronic_pulmonary_disease as copd
    , com.rheumatic_disease as rheum
    , com.peptic_ulcer_disease as pud
    , com.mild_liver_disease as liver_mild
    , com.diabetes_without_cc as diab_un
    , com.diabetes_with_cc as diab_cc
    , com.t1dm as t1dm
    , com.t2dm as t2dm
    , com.paraplegia as paraplegia
    , com.renal_disease as ckd
    , com.malignant_cancer as malig
    , com.severe_liver_disease as liver_severe
    , com.metastatic_solid_tumor as met_ca
    , com.aids as aids
    , com.smoking as smoking
    -- vitals
    , vitals.hr as hr
    , vitals.sbp as sbp
    , vitals.dbp as dbp
    , vitals.meanbp as meanbp
    , vitals.rr as rr
    , vitals.temp as temp
    , vitals.spo2 as spo2
    -- bloods, these need to be filtered accoring to admission times
    -- as original datatable above is grouped by subject id which
    -- captures community results as well (eg for hba1c), but means
    -- each array could have multiple hospital or icu admissions
    -- blood gases
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ph)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ph
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bicarb)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bicarb
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.baseexcess)
        where charttime > icu.intime and charttime < icu.outtime
    ) as baseexcess
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.chloride)
        where charttime > icu.intime and charttime < icu.outtime
    ) as chloride
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.free_calcium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as free_calcium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.glucose)
        where charttime > icu.intime and charttime < icu.outtime
    ) as glucose
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.potassium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as potassium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.sodium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as sodium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.lactate)
        where charttime > icu.intime and charttime < icu.outtime
    ) as lactate
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.hematocrit)
        where charttime > icu.intime and charttime < icu.outtime
    ) as hematocrit
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.hb)
        where charttime > icu.intime and charttime < icu.outtime
    ) as hb
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.pco2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as pco2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.po2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as po2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bg_temp)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bg_temp
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.fio2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as fio2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ventrate)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ventrate
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.tidalvol)
        where charttime > icu.intime and charttime < icu.outtime
    ) as tidalvol
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.aado2)
        where charttime > icu.intime and charttime < icu.outtime
    ) as aado2
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.specimen)
        where charttime > icu.intime and charttime < icu.outtime
    ) as specimen -- this is needed to delineate between art/venous gases
    -- blood film
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.neutrophils)
        where charttime > icu.intime and charttime < icu.outtime
    ) as neutrophils
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.lymphocytes)
        where charttime > icu.intime and charttime < icu.outtime
    ) as lymphocytes
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.wcc)
        where charttime > icu.intime and charttime < icu.outtime
    ) as wcc
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.plt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as plt
    -- inflammatory
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.crp)
        where charttime > icu.intime and charttime < icu.outtime
    ) as crp
    -- chemistry
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.albumin)
        where charttime > icu.intime and charttime < icu.outtime
    ) as albumin
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.creatinine)
        where charttime > icu.intime and charttime < icu.outtime
    ) as creatinine
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bun)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bun
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.magnesium)
        where charttime > icu.intime and charttime < icu.outtime
    ) as magnesium
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.alt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as alt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.alp)
        where charttime > icu.intime and charttime < icu.outtime
    ) as alp
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ast)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ast
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ggt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ggt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bilirubin_total)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bilirubin_total
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bilirubin_direct)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bilirubin_direct
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bilirubin_indirect)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bilirubin_indirect
    -- coags
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.inr)
        where charttime > icu.intime and charttime < icu.outtime
    ) as inr
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.inr)
        where charttime > icu.intime and charttime < icu.outtime
    ) as inr
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.fibrinogen)
        where charttime > icu.intime and charttime < icu.outtime
    ) as fibrinogen
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.bleed_time)
        where charttime > icu.intime and charttime < icu.outtime
    ) as bleed_time
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.ptt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as ptt
    , (select array_agg(struct(charttime, value) order by charttime) 
        from unnest(bloods.pt)
        where charttime > icu.intime and charttime < icu.outtime
    ) as pt
    -- other bloods
    , bloods.hba1c as hba1c
    -- insulin use
    , insulin.insulin as insulin
    -- other CV variables
    , cardiac_index.ci as cardiac_index
    -- blood product administration
    , prbcs.bloodproduct as prbc
    , plts.bloodproduct as plts
    , ffp.bloodproduct as ffp
    , cryo.bloodproduct as cryo
    , ventsettings.vent as ventsettings
    -- outcomes
    , dt_output.output as dtoutput
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
    , infection.inf as infection
    , ad.hospital_expire_flag as hospital_expire_flag
    , ad.DEATHTIME as deathtime
    , pat.dod as dod
    -- , aki.aki as aki
-- join tables to select variables
-- start with demo/patient detail tables
FROM `physionet-data.mimic_core.admissions` ad
LEFT JOIN surgery ON ad.hadm_id = surgery.hadm_id
RIGHT JOIN `physionet-data.mimic_icu.icustays` AS icu ON ad.hadm_id = icu.hadm_id
LEFT JOIN `physionet-data.mimic_derived.icustay_detail` AS icu2 ON icu.stay_id = icu2.stay_id
LEFT JOIN `physionet-data.mimic_core.patients` AS pat ON icu.subject_id = pat.subject_id
LEFT JOIN `physionet-data.mimic_derived.height`AS height ON icu.stay_id = height.stay_id
LEFT JOIN `physionet-data.mimic_derived.first_day_weight`AS weight ON icu.stay_id = weight.stay_id
-- join in the comorb table
LEFT JOIN com ON icu.hadm_id = com.hadm_id
-- vitals
LEFT JOIN vitals ON icu.stay_id = vitals.stay_id
-- join the bloods table
LEFT JOIN bloods ON icu.subject_id = bloods.subject_id
-- joic CV physiology tables 
LEFT JOIN cardiac_index ON icu.stay_id = cardiac_index.stay_id
-- blood product tables
LEFT JOIN prbcs ON icu.stay_id = prbcs.stay_id
LEFT JOIN plts ON icu.stay_id = plts.stay_id
LEFT JOIN ffp ON icu.stay_id = ffp.stay_id
LEFT JOIN cryo ON icu.stay_id = cryo.stay_id
LEFT JOIN infection on icu.stay_id = infection.stay_id
LEFT JOIN insulin on icu.stay_id = insulin.stay_id
LEFT JOIN ventsettings ON icu.stay_id = ventsettings.stay_id
-- outcome tables
LEFT JOIN dt_output on icu.stay_id = dt_output.stay_id
LEFT JOIN vent on icu.stay_id = vent.stay_id
LEFT JOIN aki ON icu.stay_id = aki.stay_id
-- filter for only the CTS patients
WHERE (
    surgery.cabg = 1 or surgery.aortic = 1 or surgery.mitral = 1 or surgery.tricuspid = 1 or surgery.pulmonary = 1
) and (icu2.icustay_seq = 1)
