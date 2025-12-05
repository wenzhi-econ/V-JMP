/* 
This do file generates relevant event dummies used for event studies.
The high-flyer measures are 6 different indicators constructed from manager fixed effects.

Input:
    "${TempData}/FinalAnalysisSample.dta"                                  <== created in 0103_03 do file 
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_5yr.dta" <== created in Point1_FE_02 do file
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_5yr.dta"          <== created in Point1_FE_02 do file
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobChange_5yr.dta"  <== created in Point1_FE_02 do file

Output:
    "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes_5yr"   <== main output 

RA: WWZ & AT
Time: 2025-10-31
Updated: 2025-11-27
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. process the estimated fixed effects datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_5yr.dta", clear 
keep IDMngr_Pre IDMngr_Post SGFE??_Pre SGFE??_Post 
keep if SGFE50_Pre!=.
duplicates drop 
save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_FEForMerge_5yr.dta", replace

use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_5yr.dta", clear 
keep IDMngr_Pre IDMngr_Post SJFE??_Pre SJFE??_Post 
keep if SJFE50_Pre!=.
duplicates drop 
save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_FEForMerge_5yr.dta", replace

use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobChange_5yr.dta", clear 
keep IDMngr_Pre IDMngr_Post SJCFE??_Pre SJCFE??_Post
keep if SJCFE50_Pre!=.
duplicates drop 
save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobChange_FEForMerge_5yr.dta", replace


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the estimated fixed effects datasets into the main dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post

merge m:1 IDMngr_Post using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_FEForMerge_5yr.dta", keepusing(SGFE??_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC_FEForMerge_5yr.dta", keepusing(SGFE??_Pre)  keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_FEForMerge_5yr.dta",          keepusing(SJFE??_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC_FEForMerge_5yr.dta",          keepusing(SJFE??_Pre)  keep(match master) nogenerate
merge m:1 IDMngr_Post using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobChange_FEForMerge_5yr.dta",  keepusing(SJCFE??_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobChange_FEForMerge_5yr.dta",  keepusing(SJCFE??_Pre)  keep(match master) nogenerate

sort  IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local FE_measures "SGFE50 SGFE45 SGFE40 SGFE35 SGFE30 SGFE25 SGFE20 SGFE15 SGFE10 SJFE50 SJFE45 SJFE40 SJFE35 SJFE30 SJFE25 SJFE20 SJFE15 SJFE10 SJCFE50 SJCFE45 SJCFE40 SJCFE35 SJCFE30 SJCFE25 SJCFE20 SJCFE15 SJCFE10"

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

order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time SGFE50_LtoL - SJCFE10_HtoL

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL SGFE50_LtoL - SJCFE10_HtoL ///
    TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC TransferSJV TransferSJVC LogPayBonus LogPay LogBonus

keep if SGFE30_LtoL!=. | SJFE30_LtoL!=.
    //impt: keep only event workers who can be classified into a event group under manager FE based measures

compress
save "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes_5yr.dta", replace
