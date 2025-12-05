/* 
This do file generates the do file used for estimating manager fixed effects on their subordinates' pay outcomes.
Subordinates pay outcomes are measured 5 year forward.

Input:
    "${TempData}/FinalFullSample.dta"                   <== created in 0101_01 do file 

Output:
    "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE_5yr.dta"

RA: WWZ & AT
Time:   2025-10-31
Update: 2025-11-27
*/

use "${TempData}/FinalFullSample.dta", clear 

keep  Year YearMonth IDlse IDlseMHR WL LogPayBonus TransferSJ ChangeSalaryGrade StandardJob StandardJobCode
order Year YearMonth IDlse IDlseMHR WL LogPayBonus TransferSJ ChangeSalaryGrade StandardJob StandardJobCode

//impt: step 1. keep only WL1 employees
keep if WL==1

// step 2. get three outcomes used in manager FE estimation

// Outcome 1: Salary grade change
sort IDlse YearMonth
bysort IDlse: generate ChangeSalaryGradeC = sum(ChangeSalaryGrade)

// Outcome 2: standard job change
sort IDlse YearMonth
bysort IDlse: generate StandardJobC = sum(TransferSJ)

// Outcome 3: Lateral moves
generate SJVertSG = TransferSJ
replace  SJVertSG = 0 if ChangeSalaryGrade==0
sort IDlse YearMonth
bysort IDlse: generate SJVertSGC = sum(SJVertSG)

// step 3. Subordinates pay outcomes are measured 5 year forward.
xtset IDlse YearMonth   

local lag = 60   // move 5 years forward
generate ChangeSalaryGradeC_fwd5 = F`lag'.ChangeSalaryGradeC
generate StandardJobC_fwd5       = F`lag'.StandardJobC
generate SJVertSGC_fwd5          = F`lag'.SJVertSGC


save "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE_5yr.dta", replace 