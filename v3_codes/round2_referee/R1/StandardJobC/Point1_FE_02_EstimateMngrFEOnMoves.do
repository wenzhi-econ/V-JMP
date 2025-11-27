/* 
This do file estimates manager fixed effects on their subordinates' pay outcomes, and classifies managers into high-flyer managers based on different threshold values.

Input:
    "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta"  <== created in Point1_FE_01 do file 

Output: 
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC.dta"

RA: WWZ 
Time: 2025-11-25
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. estimating manager FE on outcome StandardJobC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta", clear 

reghdfe SJVertSGC i.YearMonth, absorb(IDlse SJFE=IDlseMHR)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. identify high-flyer managers based on StandardJobC
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

save "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC.dta", replace