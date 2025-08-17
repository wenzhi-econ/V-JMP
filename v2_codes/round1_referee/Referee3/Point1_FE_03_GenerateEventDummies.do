/* 
This do file generates relevant event dummies used for event studies.
The high-flyer measures are 6 different indicators constructed from manager fixed effects.

Input:
    "${TempData}/FinalAnalysisSample.dta"                                <== created in 0103_03 do file 
    "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased.dta"              <== created in Point1_FE_02 do file

Output:
    "${TempData}/FinalAnalysisSample_Simplified_WithMngrFEBasedMeasures" <== main output 

RA: WWZ 
Time: 2025-08-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. merge pre- and post-event managers' quality measures 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. process the estimated fixed effects datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased.dta", clear 
keep IDMngr_Pre IDMngr_Post FE50_Pre FE50_Post FE40_Pre FE40_Post FE30_Pre FE30_Post
rename (FE50_Pre FE50_Post FE40_Pre FE40_Post FE30_Pre FE30_Post) (FFE50_Pre FFE50_Post FFE40_Pre FFE40_Post FFE30_Pre FFE30_Post)
keep if FFE50_Pre!=.
duplicates drop 
save "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased_FEForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the estimated fixed effects datasets into the main dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 
order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post

merge m:1 IDMngr_Post using "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased_FEForMerge.dta", keepusing(FFE50_Post FFE40_Post FFE30_Post) keep(match master) nogenerate
merge m:1 IDMngr_Pre  using "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased_FEForMerge.dta", keepusing(FFE50_Pre  FFE40_Pre  FFE30_Pre)  keep(match master) nogenerate
sort  IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. event-relevant variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. classify each employee into four event groups 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach measure in FFE50 FFE40 FFE30 {
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

foreach measure in FFE50 FFE40 FFE30 {
    label variable `measure'_LtoL "LtoL event group (based on `measure' measure)"
    label variable `measure'_LtoH "LtoH event group (based on `measure' measure)"
    label variable `measure'_HtoH "HtoH event group (based on `measure' measure)"
    label variable `measure'_HtoL "HtoL event group (based on `measure' measure)"
}

order IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time FFE50_LtoL - FFE30_HtoL

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. obtain a final version dataset for all event study results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth IDlseMHR Event_Time IDMngr_Pre IDMngr_Post Rel_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL FFE50_LtoL - FFE30_HtoL ///
    TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC TransferSJV TransferSJVC LogPayBonus LogPay LogBonus

keep if FFE50_LtoL!=.
    //impt: keep only event workers who can be classified into a event group under manager FE based measures

compress
save "${TempData}/R3_Point1_FE_FinalAnalysisSample_WithMngrFEBasedMeasures.dta", replace
