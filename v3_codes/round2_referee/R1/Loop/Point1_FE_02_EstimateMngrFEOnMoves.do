/* 
This do file estimates manager fixed effects on their subordinates' pay outcomes, and classifies managers into high-flyer managers based on different threshold values.

Input:
    "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta"  <== created in Point1_FE_01 do file 

Output: 
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC.dta"
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC.dta"

RA: WWZ 
Time: 2025-10-31
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. estimating manager FE on outcome ChangeSalaryGradeC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta", clear 

reghdfe ChangeSalaryGradeC i.YearMonth, absorb(IDlse SGFE=IDlseMHR)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. identify high-flyer managers based on ChangeSalaryGradeC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? s-2-1. keep a cross-section of managers

keep IDlseMHR SGFE
keep if SGFE!=.
duplicates drop 

*-? s-2-2. generate relevant percentile values 
// Try median split, 60/40, 65/35 etc go up to 90/10
pctile pctile_SGFE = SGFE, nquantiles(20)
global SGFE_50p = pctile_SGFE[10]
global SGFE_55p = pctile_SGFE[11]
global SGFE_60p = pctile_SGFE[12]
global SGFE_65p = pctile_SGFE[13]
global SGFE_70p = pctile_SGFE[14]
global SGFE_75p = pctile_SGFE[15]
global SGFE_80p = pctile_SGFE[16]
global SGFE_85p = pctile_SGFE[17]
global SGFE_90p = pctile_SGFE[18]

*-? s-2-3. create 3 HF indicators

generate SGFE50 = (SGFE >= ${SGFE_50p})
generate SGFE45 = (SGFE >= ${SGFE_55p})
generate SGFE40 = (SGFE >= ${SGFE_60p})
generate SGFE35 = (SGFE >= ${SGFE_65p})
generate SGFE30 = (SGFE >= ${SGFE_70p})
generate SGFE25 = (SGFE >= ${SGFE_75p})
generate SGFE20 = (SGFE >= ${SGFE_80p})
generate SGFE15 = (SGFE >= ${SGFE_85p})
generate SGFE10 = (SGFE >= ${SGFE_90p})

*-? s-2-4. generate variables used for further merge 

keep IDlseMHR SGFE SGFE50 SGFE45 SGFE40 SGFE35 SGFE30 SGFE25 SGFE20 SGFE15 SGFE10 
rename IDlseMHR IDMngr
foreach var in IDMngr SGFE50 SGFE45 SGFE40 SGFE35 SGFE30 SGFE25 SGFE20 SGFE15 SGFE10 {
    generate `var'_Pre = `var'
    generate `var'_Post = `var' 
}

save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. estimating manager FE on outcome SJVertSGC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta", clear 

reghdfe SJVertSGC i.YearMonth, absorb(IDlse SJFE=IDlseMHR)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. identify high-flyer managers based on SJVertSGC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? s-4-1. keep a cross-section of managers

keep IDlseMHR SJFE
keep if SJFE!=.
duplicates drop 

*-? s-4-2. generate relevant percentile values 

pctile pctile_SJFE = SJFE, nquantiles(20)
global SJFE_50p = pctile_SJFE[10]
global SJFE_55p = pctile_SJFE[11]
global SJFE_60p = pctile_SJFE[12]
global SJFE_65p = pctile_SJFE[13]
global SJFE_70p = pctile_SJFE[14]
global SJFE_75p = pctile_SJFE[15]
global SJFE_80p = pctile_SJFE[16]
global SJFE_85p = pctile_SJFE[17]
global SJFE_90p = pctile_SJFE[18]


*-? s-4-3. create 3 HF indicators

generate SJFE50 = (SJFE >= ${SJFE_50p})
generate SJFE45 = (SJFE >= ${SJFE_55p})
generate SJFE40 = (SJFE >= ${SJFE_60p})
generate SJFE35 = (SJFE >= ${SJFE_65p})
generate SJFE30 = (SJFE >= ${SJFE_70p})
generate SJFE25 = (SJFE >= ${SJFE_75p})
generate SJFE20 = (SJFE >= ${SJFE_80p})
generate SJFE15 = (SJFE >= ${SJFE_85p})
generate SJFE10 = (SJFE >= ${SJFE_90p})

*-? s-4-4. generate variables used for further merge 

keep IDlseMHR SJFE SJFE50 SJFE45 SJFE40 SJFE35 SJFE30 SJFE25 SJFE20 SJFE15 SJFE10 
rename IDlseMHR IDMngr
foreach var in IDMngr SJFE50 SJFE45 SJFE40 SJFE35 SJFE30 SJFE25 SJFE20 SJFE15 SJFE10 {
    generate `var'_Pre = `var'
    generate `var'_Post = `var'
}

save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC.dta", replace