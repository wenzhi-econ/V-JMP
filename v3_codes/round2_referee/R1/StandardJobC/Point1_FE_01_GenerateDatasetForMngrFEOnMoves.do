/* 
This do file generates the do file used for estimating manager fixed effects on their subordinates' pay outcomes.

Input:
    "${TempData}/FinalFullSample.dta"                   <== created in 0101_01 do file 

Output:
    "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta"

RA: WWZ 
Time: 2025-10-31
*/

use "${TempData}/FinalFullSample.dta", clear 

keep  Year YearMonth IDlse IDlseMHR WL LogPayBonus TransferSJ ChangeSalaryGrade StandardJob StandardJobCode
order Year YearMonth IDlse IDlseMHR WL LogPayBonus TransferSJ ChangeSalaryGrade StandardJob StandardJobCode

//impt: step 1. keep only WL1 employees
keep if WL==1

// step 2. get two outcomes used in manager FE estimation
sort IDlse YearMonth
bysort IDlse: generate ChangeSalaryGradeC = sum(ChangeSalaryGrade)

// setp 3. add additional outcomes. any standard job change
sort IDlse YearMonth
bysort IDlse: generate StandardJobC = sum(TransferSJ)

generate SJVertSG = TransferSJ
replace  SJVertSG = 0 if ChangeSalaryGrade==0
sort IDlse YearMonth
bysort IDlse: generate SJVertSGC = sum(SJVertSG)


save "${TempData}/R1_Point1_EmployeePanel_UsedFor_MoveBasedMngrFE.dta", replace 


