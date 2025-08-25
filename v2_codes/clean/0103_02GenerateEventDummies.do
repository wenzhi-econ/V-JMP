/* 
This do file generates relevant event dummies used for event studies.

Input:
    "${TempData}/FinalFullSample.dta"                   <== created in 0101_01 do file 
    "${TempData}/0103_01CrossSectionalEventWorkers.dta" <== created in 0103_01 do file 

Output:
    "${TempData}/0103_02EventWorkersPanel_WithEventDummies" <== main output 

Description of the output dataset:
    (1) The dataset contains only event workers.
    (2) It contains workers' event group based on the CA30 high-flyer measure.

RA: WWZ 
Time: 2025-08-05
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge event dates to the outcome dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

merge m:1 IDlse using "${TempData}/0103_01CrossSectionalEventWorkers.dta"
keep if _merge==3
drop _merge
    //impt: I only keep employees that are in the event studies.
    //impt: I will use event study sample, event workers, and analysis sample interchangeably.

codebook IDlse
    //tocheck: expected to be 29,452; and it is

order IDlse YearMonth IDlseMHR Event_Time Event_Time_1monthbefore IDMngr_Pre IDMngr_Post

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

rename YearMonth YearMonth_Save

rename Event_Time YearMonth
merge m:1 IDMngr_Post YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop if _merge==2
    drop _merge 
rename CA30 CA30_Post
rename CA28 CA28_Post
rename CA32 CA32_Post
rename DA30 DA30_Post
rename YearMonth Event_Time

rename Event_Time_1monthbefore YearMonth
merge m:1 IDMngr_Pre YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop if _merge==2
    drop _merge 
rename CA30 CA30_Pre
rename CA28 CA28_Pre
rename CA32 CA32_Pre
rename DA30 DA30_Pre
rename YearMonth Event_Time_1monthbefore

rename Event_Time YearMonth
merge m:1 IDMngr_Post YearMonth using "${TempData}/0102_04HFMeasure_TenureBased.dta"
    drop if _merge==2
    drop _merge 
rename TB05 TB05_Post
rename YearMonth Event_Time

rename Event_Time_1monthbefore YearMonth
merge m:1 IDMngr_Pre YearMonth using "${TempData}/0102_04HFMeasure_TenureBased.dta"
    drop if _merge==2
    drop _merge 
rename TB05 TB05_Pre
rename YearMonth Event_Time_1monthbefore

rename YearMonth_Save YearMonth

sort  IDlse YearMonth
order ///
    IDlse YearMonth IDlseMHR Event_Time Event_Time_1monthbefore ///
    IDMngr_Pre IDMngr_Post ///
    CA30_Pre CA30_Post ///
    CA28_Pre CA28_Post ///
    CA32_Pre CA32_Post ///
    TB05_Pre TB05_Post 

count if CA30_Pre==.
    //&?  1,520 observations have no information on pre-event manager type.
count if CA30_Post==.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. Rel_Time
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Rel_Time = YearMonth - Event_Time, after(Event_Time)
drop Event_Time_1monthbefore

label variable Rel_Time "Relative time to the event"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in CA30 CA28 CA32 DA30 TB05 {

    generate `measure'_LtoL = .
    replace  `measure'_LtoL = 1 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_LtoL = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_LtoH = .
    replace  `measure'_LtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_LtoH = 1 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_LtoH = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_HtoH = .
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoH = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoH = 1 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_HtoH = 0 if `measure'_Pre==1 & `measure'_Post==0

    generate `measure'_HtoL = .
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==0
    replace  `measure'_HtoL = 0 if `measure'_Pre==0 & `measure'_Post==1
    replace  `measure'_HtoL = 0 if `measure'_Pre==1 & `measure'_Post==1
    replace  `measure'_HtoL = 1 if `measure'_Pre==1 & `measure'_Post==0

    label variable `measure'_LtoL "LtoL event group (based on `measure' measure)"
    label variable `measure'_LtoH "LtoH event group (based on `measure' measure)"
    label variable `measure'_HtoH "HtoH event group (based on `measure' measure)"
    label variable `measure'_HtoL "HtoL event group (based on `measure' measure)"
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. check the variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

drop if CA30_LtoL==. | CA30_LtoH==. | CA30_HtoH==. |  CA30_HtoL==.
    //tocheck: drop 1,520 observations whose pre-event manager is not in the dataset in that event month
drop if CA28_LtoL==. | CA28_LtoH==. | CA28_HtoH==. |  CA28_HtoL==.
drop if CA32_LtoL==. | CA32_LtoH==. | CA32_HtoH==. |  CA32_HtoL==.
drop if DA30_LtoL==. | DA30_LtoH==. | DA30_HtoH==. |  DA30_HtoL==.
drop if TB05_LtoL==. | TB05_LtoH==. | TB05_HtoH==. |  TB05_HtoL==.
    //tocheck: 0 observation is deleted, as expected

codebook IDlse
    //&? a panel of event workers with identifiable event groups.
    //tocheck: 29,423 distinct employees, with 1,882,806 employee-year-month observations

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

order IDlse YearMonth IDlseMHR Rel_Time Event_Time ///
    CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    CA28_LtoL CA28_LtoH CA28_HtoH CA28_HtoL ///
    CA32_LtoL CA32_LtoH CA32_HtoH CA32_HtoL ///
    DA30_LtoL DA30_LtoH DA30_HtoH DA30_HtoL ///
    TB05_LtoL TB05_LtoH TB05_HtoH TB05_HtoL ///
    IDMngr_Pre IDMngr_Post CA30_Pre CA30_Post ///
    TransferSJVC ChangeSalaryGradeC PromWLC LogPayBonus LogPay LogBonus

save "${TempData}/0103_02EventWorkersPanel_WithEventDummies.dta", replace