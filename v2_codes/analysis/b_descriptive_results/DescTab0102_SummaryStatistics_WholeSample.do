/* 
This do file tabulates summary statistics for key variables in the dataset among all employees.

Notes:
    All employees are includes, regardless of whether they appear in the event studies or not.

Input:
    "${TempData}/FinalFullSample.dta"                <== created in 0101_01 do file 
    "${TempData}/0105SalesProdOutcomes.dta"          <== created in 0105 do file
    "${RawMNEData}/EducationMax.dta"                 <== raw data 

Output:
    "${TempData}/DescTab0102_SummaryStatistics_FullSample.dta" <== dataset used to create the summary statistics table 
    "${Results}/SummaryStatistics_FullSample.tex"              <== final table 

RA: WWZ 
Time: 2025-03-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge two additional datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use  "${TempData}/FinalFullSample.dta", clear

merge 1:1 IDlse YearMonth using  "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity)
    drop if _merge ==2 
    drop _merge 

merge m:1 IDlse using "${RawMNEData}/EducationMax.dta", keepusing(QualHigh FieldHigh1 FieldHigh2 FieldHigh3)
    drop if _merge ==2 
    drop _merge

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate two auxiliary variables and keep only relevant variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! mark each individual and manager only once 
xtset IDlse YearMonth 
egen tag_Mngr = tag(IDlseMHR)
egen tag_Ind = tag(IDlse)

sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)
capture drop ChangeM
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

keep IDlse YearMonth IDlseMHR ///
    tag_Ind tag_Mngr ///
    Female AgeBand QualHigh FieldHigh1 FieldHigh2 FieldHigh3 ///
    Tenure WL ChangeM ///
    ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm LogPayBonus Bonus Pay VPA ProductivityStd Productivity

order IDlse YearMonth IDlseMHR ///
    tag_Ind tag_Mngr ///
    Female AgeBand QualHigh FieldHigh1 FieldHigh2 FieldHigh3 ///
    Tenure WL ChangeM ///
    ChangeSalaryGradeC TransferSJVC PromWLC LeaverPerm LogPayBonus Bonus Pay VPA ProductivityStd Productivity

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. prepare demographic variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! gender (set it at worker level, not individual-year-month level)
replace Female = 0 if missing(Female)
    //&? a limited number of missing gender observations
    //&? classify them as non-female
replace Female = . if tag_Ind==0
label variable Female "Female"

*!! cohort 
replace AgeBand = 1 if AgeBand==7 
    //&? if the employee is registered as younger than 18, classify as 18-29
replace AgeBand = 4 if AgeBand>4 & AgeBand!=. 
    //&? upper bound as 50+
tab AgeBand, gen(Cohort)
label variable Cohort1 "Share in cohort 18-29"  
label variable Cohort2 "Share in cohort 30-39"
label variable Cohort3 "Share in cohort 40-49"
label variable Cohort4 "Share in cohort 50+"

*!! education: fields of study 
generate Econ = (FieldHigh1 == 4 | FieldHigh2 == 4 | FieldHigh3 == 4) if FieldHigh1!=.
generate Sci = (FieldHigh1 == 5 | FieldHigh1 == 7 | FieldHigh1 == 9 | FieldHigh1 == 14 | FieldHigh1 == 15 | FieldHigh1 == 17 | ///
FieldHigh2 == 5 | FieldHigh2 == 7 | FieldHigh2 == 9 | FieldHigh2 == 14 | FieldHigh2 == 15 | FieldHigh2 == 17 | ///
FieldHigh3 == 5 | FieldHigh3 == 7 | FieldHigh3 == 9 | FieldHigh3 == 14 | FieldHigh3 == 15 | FieldHigh3 == 17) if FieldHigh1!=.
generate Hum = (FieldHigh1 == 6 | FieldHigh2 == 6 | FieldHigh3 == 6 | FieldHigh1 == 11 | FieldHigh2 == 11 | FieldHigh3 == 11 | FieldHigh1 == 12 | FieldHigh2 == 12 | FieldHigh3 == 12 | FieldHigh1 == 13 | FieldHigh2 == 13 | FieldHigh3 == 13 | FieldHigh1 == 19 | FieldHigh2 == 19 | FieldHigh3 == 19) if FieldHigh1!=.
generate Other = (Econ ==0 & Sci ==0 & Hum ==0  )  if FieldHigh1!=.
generate Missing = FieldHigh1 ==. 

*!! set the above education variables at worker level, not individual-year-month level
replace Econ    = . if tag_Ind==0 
replace Sci     = . if tag_Ind==0 
replace Hum     = . if tag_Ind==0 
replace Other   = . if tag_Ind==0 
replace Missing = . if tag_Ind==0 

label variable Econ    "Econ, business, and admin"
label variable Sci     "Sci, engin, math, and stat"
label variable Hum     "Social sciences and humanities"
label variable Other   "Other educ"
label variable Missing "Missing education"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. prepare work-related variables  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! tenure 
label variable Tenure "Tenure (years)"

*!! work level 
replace WL = 3 if WL > 3
replace WL = . if WL == 0
tab WL, gen(WL)
label variable WL1 "Share in work level 1" 
label variable WL2 "Share in work level 2" 
label variable WL3 "Share in work level 3+" 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-5. prepare # of obs relevant variables   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! # of obs per employee
generate one = 1
sort IDlse YearMonth
bysort IDlse: egen NoMonths = sum(one)

*!! # of supervisors per employee
bysort IDlse: egen ChangeMTot = sum(ChangeM)

*!! team size (i.e., # of workers per supervisor)
sort IDlseMHR YearMonth IDlse 
bysort IDlseMHR YearMonth: generate TeamSize = _N
sort IDlse YearMonth

*!! set the above three variables at worker or manager level, not individual-year-month level
replace TeamSize = .   if tag_Mngr==0 
replace NoMonths = .   if tag_Ind==0 
replace ChangeMTot = . if tag_Ind==0 

label variable NoMonths             "No. of months per worker"
label variable TeamSize             "No. of workers per supervisor"
label variable ChangeMTot           "No. of supervisors per worker"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-6. prepare outcome variables   
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! for three cumulative counts variables, take the maximum value for each individual
foreach v in ChangeSalaryGradeC TransferSJVC PromWLC {
	bysort IDlse: egen `v'm = max(`v')
	replace `v'm = . if tag_Ind==0 
}
label variable ChangeSalaryGradeCm "Number of salary grade increases"
label variable TransferSJVCm       "Number of lateral job transfers"
label variable PromWLCm            "Number of promotions (work-level)"

*!! monthly exit 
label variable LeaverPerm          "Monthly exit"

*!! log of pay and bonus
label variable LogPayBonus         "Pay + bonus (logs)"

*!! bonus over pay ratio 
generate BonusPay = Bonus/Pay
label variable BonusPay            "Bonus over pay"

*!! performance ratings
label variable VPA                 "Perf. appraisals"

*!! productivity 
label variable ProductivityStd     "Sales bonus (s.d.)"

save "${TempData}/DescTab0102_SummaryStatistics_FullSample.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. produce the summary statistics table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/DescTab0102_SummaryStatistics_FullSample.dta", clear 

label variable TransferSJVCm "Number of lateral moves"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. panel a: demographics 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo clear 
estpost summarize Female Cohort1 Cohort2 Cohort3 Cohort4 Econ Sci Hum Other, detail

global latex_file "${DescriptiveResults}/SummaryStatistics_FullSample.tex"

esttab using "${latex_file}", ///
    replace ci(3) label nonotes noobs nomtitles collabels(,none) nonumbers ///
    cells("mean(fmt(%9.2fc)) sd(fmt(%8.1fc)) p1(fmt(%8.1fc)) p99(fmt(%8.1fc)) count(fmt(%12.0fc) )") ///
    prehead("\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Mean} & \multicolumn{1}{c}{SD} & \multicolumn{1}{c}{P1} & \multicolumn{1}{c}{P99} & \multicolumn{1}{c}{N} \\ " "\midrule") ///
    posthead("\multicolumn{6}{l}{\emph{Panel (a): gender, age and education}} \\ [+5pt]") ///
    prefoot(" ") postfoot("\midrule")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. panel b: work-related variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

estpost summarize Tenure WL1 WL2 WL3 NoMonths ChangeMTot TeamSize, detail
esttab using "${latex_file}", ///
    append ci(3) label nonotes noobs nomtitles collabels(,none) nonumbers ///
    cells("mean(fmt(%9.2fc)) sd(fmt(%8.1fc)) p1(fmt(%8.1fc)) p99(fmt(%8.1fc)) count(fmt(%12.0fc) )") ///
    prehead(" ") /// 
    posthead("\multicolumn{6}{l}{\emph{Panel (b): tenure, hierarchy and team size}} \\ [+5pt]") ///
    postfoot("\midrule") prefoot(" ")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. panel c: outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

estpost summarize ChangeSalaryGradeCm TransferSJVCm PromWLCm LeaverPerm LogPayBonus BonusPay ProductivityStd, detail
    
esttab using "${latex_file}", ///
    append ci(3) label nonotes noobs nomtitles collabels(,none) nonumbers ///
    cells("mean(fmt(%9.2fc)) sd(fmt(%8.1fc)) p1(fmt(%8.1fc)) p99(fmt(%8.1fc)) count(fmt(%12.0fc))") ///
    prehead(" ") ///
    posthead("\multicolumn{6}{l}{\emph{Panel (c): outcome variables}} \\ [+5pt]") ///
    prefoot(" ") ///
    postfoot("\midrule" "\end{tabular}") 