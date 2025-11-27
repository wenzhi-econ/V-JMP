/* 
This do file generates relevant event dummies used for event studies.
The high-flyer measures are 6 different indicators constructed from manager fixed effects.

Input:
    "${TempData}/FinalAnalysisSample.dta"                                  <== created in 0103_03 do file 
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC.dta"     <== created in Point1_FE_02 do file

Output:
    "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes"   <== main output 

RA: WWZ 
Time: 2025-11-25
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. process the estimated fixed effects datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC.dta", clear 
keep IDMngr_Pre IDMngr_Post SJFE??_Pre SJFE??_Post
keep if SJFE50_Pre!=.
duplicates drop 
save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC_FEForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the estimated fixed effects datasets into the main dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post

merge m:1 IDMngr_Post using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC_FEForMerge.dta",          keepusing(SJFE??_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC_FEForMerge.dta",          keepusing(SJFE??_Pre)  keep(match master) nogenerate
sort  IDlse YearMonth


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local FE_measures "SJFE50 SJFE45 SJFE40 SJFE35 SJFE30 SJFE25 SJFE20 SJFE15 SJFE10"

foreach measure in `FE_measures' {
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
}

foreach measure in `FE_measures' {
    label variable `measure'_LtoL "LtoL event group (based on `measure' measure)"
    label variable `measure'_LtoH "LtoH event group (based on `measure' measure)"
    label variable `measure'_HtoH "HtoH event group (based on `measure' measure)"
    label variable `measure'_HtoL "HtoL event group (based on `measure' measure)"
}

order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time SJFE50_LtoL - SJFE10_HtoL

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL SJFE50_LtoL - SJFE10_HtoL ///
    TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC TransferSJV TransferSJVC LogPayBonus LogPay LogBonus

keep if SJFE30_LtoL!=.
    //impt: keep only event workers who can be classified into a event group under manager FE based measures

compress
save "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes.dta", replace
