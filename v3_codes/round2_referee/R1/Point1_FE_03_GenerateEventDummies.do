/* 
This do file generates relevant event dummies used for event studies.
The high-flyer measures are 6 different indicators constructed from manager fixed effects.

Input:
    "${TempData}/FinalAnalysisSample.dta"                                  <== created in 0103_03 do file 
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC.dta"     <== created in Point1_FE_02 do file
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC.dta"              <== created in Point1_FE_02 do file

Output:
    "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes"   <== main output 

RA: WWZ 
Time: 2025-10-31
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. process the estimated fixed effects datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC.dta", clear 
keep IDMngr_Pre IDMngr_Post SGFE50_Pre SGFE50_Post SGFE40_Pre SGFE40_Post SGFE30_Pre SGFE30_Post
keep if SGFE50_Pre!=.
duplicates drop 
save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_FEForMerge.dta", replace

use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC.dta", clear 
keep IDMngr_Pre IDMngr_Post SJFE50_Pre SJFE50_Post SJFE40_Pre SJFE40_Post SJFE30_Pre SJFE30_Post
keep if SJFE50_Pre!=.
duplicates drop 
save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_FEForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the estimated fixed effects datasets into the main dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post

merge m:1 IDMngr_Post using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_FEForMerge.dta", keepusing(SGFE50_Post SGFE40_Post SGFE30_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_FEForMerge.dta", keepusing(SGFE50_Pre  SGFE40_Pre  SGFE30_Pre)  keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_FEForMerge.dta",          keepusing(SJFE50_Post SJFE40_Post SJFE30_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_FEForMerge.dta",          keepusing(SJFE50_Pre  SJFE40_Pre  SJFE30_Pre)  keep(match master) nogenerate
sort  IDlse YearMonth


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in SGFE30 SJFE30 {
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

foreach measure in SGFE30 SJFE30 {
    label variable `measure'_LtoL "LtoL event group (based on `measure' measure)"
    label variable `measure'_LtoH "LtoH event group (based on `measure' measure)"
    label variable `measure'_HtoH "HtoH event group (based on `measure' measure)"
    label variable `measure'_HtoL "HtoL event group (based on `measure' measure)"
}

order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time SGFE30_LtoL - SJFE30_HtoL

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL SGFE30_LtoL - SJFE30_HtoL ///
    TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC TransferSJV TransferSJVC LogPayBonus LogPay LogBonus

keep if SGFE30_LtoL!=. | SJFE30_LtoL!=.
    //impt: keep only event workers who can be classified into a event group under manager FE based measures

compress
save "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes.dta", replace
