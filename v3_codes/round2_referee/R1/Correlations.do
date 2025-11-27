/* 
This do file runs correlations between the different FE baded measures and the original age-based measure 

Input: 
    "${TempData}/FinalAnalysisSample.dta"   
    "${TempData}/0102_03HFMeasure.dta"
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC.dta"
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC.dta"
    "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC.dta"


RA: AT 
Time: 2025-11-27
*/


/***********************************************************************
Load the original age based measure
************************************************************************/
use "${TempData}/0102_03HFMeasure.dta", clear
keep IDlseMHR CA30
duplicates drop
rename IDlseMHR IDMngr
tempfile agehf
save `agehf'


/***********************************************************************
Only keep managers in the final analysis sample for the correlations
************************************************************************/
use "${TempData}/FinalAnalysisSample.dta", clear
keep IDlseMHR
rename IDlseMHR IDMngr
duplicates drop
tempfile final_samp
save `final_samp'


/***********************************************************************
Salary Grade Change based FE dummies
************************************************************************/
use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_ChangeSalaryGradeC.dta", clear
keep IDMngr SGFE??
duplicates drop
tempfile fe_sgfe
save `fe_sgfe'


/***********************************************************************
Standard Job Change based FE dummies
************************************************************************/
use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_StandardJobC.dta", clear
keep IDMngr SJFE??
duplicates drop
* rename to avoid conflict with lateral move
rename SJFE* SJFEstd*
tempfile fe_sjfe
save `fe_sjfe'



/***********************************************************************
Lateral Move based FE dummies
************************************************************************/
use "${TempData}/R1_Point1_FE_HFMeasure_MngrFE_SJVertSGC.dta", clear
keep IDMngr SJFE??
* rename to avoid conflict with standard job change
rename SJFE* LMFE*
duplicates drop
tempfile fe_lmfe
save `fe_lmfe'




// Build a corr table
clear
set obs 9
gen threshold = 50 - 5 * (_n - 1)
gen corr_sgfe = .
gen corr_sjfe = .
gen corr_lmfe = .

tempfile corrtab
save `corrtab', replace


/***********************************************************************
   Loop over thresholds and compute correlations properly
************************************************************************/

local i = 1
// Loop over all the thresholds
foreach t in 50 45 40 35 30 25 20 15 10 {

    // FE against salary grade changes
    use `agehf', clear
    merge 1:1 IDMngr using `fe_sgfe', nogenerate
    merge 1:1 IDMngr using `final_samp', keep(3)
    quietly corr CA30 SGFE`t'
    local r1 = r(rho)

    // FE against standard job changes
    use `agehf', clear
    merge 1:1 IDMngr using `fe_sjfe', nogenerate
    merge 1:1 IDMngr using `final_samp', keep(3)
    quietly corr CA30 SJFEstd`t'
    local r2 = r(rho)

    // FE against lateral moves
    use `agehf', clear
    merge 1:1 IDMngr using `fe_lmfe', nogenerate
    merge 1:1 IDMngr using `final_samp', keep(3)
    quietly corr CA30 LMFE`t'
    local r3 = r(rho)

    // Store correlations
    use `corrtab', clear
    replace corr_sgfe = `r1' in `i'
    replace corr_sjfe = `r2' in `i'
    replace corr_lmfe = `r3' in `i'

    save `corrtab', replace
    local ++i
}


 // Final Table
use `corrtab', clear
format corr_sgfe corr_sjfe corr_lmfe %6.4f
list threshold corr_sgfe corr_sjfe corr_lmfe, noobs sep(0)

