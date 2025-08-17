/* 
This do file generates the do file used for estimating manager fixed effects on their subordinates' pay outcomes.

Input:
    "${TempData}/FinalFullSample.dta"                   <== created in 0101_01 do file 

Output:
    "${TempData}/R3_Point1_EmployeePanelUsedForMngrFE.dta"

RA: WWZ 
Time: 2025-08-12
*/

use "${TempData}/FinalFullSample.dta", clear 

keep  Year YearMonth IDlse IDlseMHR WL LogPayBonus
order Year YearMonth IDlse IDlseMHR WL LogPayBonus

keep if WL==1
    //impt: keep only WL1 employees

keep if LogPayBonus!=.
    //impt: keep only those observations with non-missing pay outcomes

sort IDlse YearMonth

save "${TempData}/R3_Point1_EmployeePanelUsedForMngrFE.dta", replace 