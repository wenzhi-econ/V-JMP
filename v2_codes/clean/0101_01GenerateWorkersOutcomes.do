/* 
This do file generates relevant outcome variables used in the paper.

Input:
    "${RawMNEData}/AllSnapshotWC.dta"

Output:
    "${TempData}/FinalFullSample.dta"

Description of the output dataset:
    (1) Full employee panel, with additional outcomes that are used frequently.
    (2) In particular, the dataset contains the following outcome variables:
        variables related to vertical promotion,
        variables related to lateral moves, and
        variables related to pay.

impt: This dataset will be used frequently if full sample dataset is required.

RA: WWZ 
Time: 2025-08-05

Notes on some details about the data cleaning process:
    (1) Accounting for missing values:
        SalaryGrade=785 indicates missing values 
        SubFunc=94 indicates missing values
        Func=13 indicates missing values
    (2) Specific issues on the StandardJob variable:
        (i) In some observations, the string contains "Do Not Use"  -- in various formats, e.g., Digital R&D Specialist (Do Not Use), DO NOT USE Digital R&D Specialist, VP Finance BP - DO NOT USE.
        (ii) This affect 0.4% of total observations, but around 11% of total employees.
        (iii) I will treat these observations, and impute with the last non-missing value for that employee. This procedure also fits the pattern of the "Do Not Use".
        (iv) This is the conservative procedure, as this controversial value will never lead to any standard job change in the final constructed variable.
    (3) Specific issues on the Func variable:
        (i) Func=17 and Func=18 both indicate the "Data and Analytics" function.

RA: AT & WWZ
Time: 2025-08-25
*/

use "${RawMNEData}/AllSnapshotWC.dta", clear
xtset IDlse YearMonth 
sort IDlse YearMonth

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. outcome variables: vertical promotions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. salary grade increases
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate ChangeSalaryGrade = 0
replace  ChangeSalaryGrade = 1 if IDlse==IDlse[_n-1] & SalaryGrade!=SalaryGrade[_n-1] & SalaryGrade!=785 & SalaryGrade[_n-1]!=785

sort IDlse YearMonth
bysort IDlse: generate ChangeSalaryGradeC = sum(ChangeSalaryGrade)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2: work level promotions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: generate PromWLC = sum(PromWL)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. outcome variables: lateral moves
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. standard job changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! accounting for the "Do Not Use" observations

generate SJ_not_use = regexm(upper(StandardJob), "DO NOT USE")
order    SJ_not_use, after(StandardJob)

capture drop CleanJob
generate CleanJob = StandardJob
replace  CleanJob = "" if SJ_not_use==1
replace  CleanJob = CleanJob[_n-1] if IDlse==IDlse[_n-1] & CleanJob=="" & CleanJob[_n-1]!=""
order    CleanJob, after(StandardJob)

sort IDlse YearMonth
generate TransferSJ = 0
replace  TransferSJ = 1 if (IDlse==IDlse[_n-1] & CleanJob!=CleanJob[_n-1] & CleanJob!="" & CleanJob[_n-1]!="")

sort IDlse YearMonth
bysort IDlse: generate TransferSJC = sum(TransferSJ)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. standard job changes with simultaneous salary grade changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate TransferSJV = TransferSJ
replace  TransferSJV = 0 if ChangeSalaryGrade==0	

sort IDlse YearMonth
bysort IDlse: generate TransferSJVC = sum(TransferSJV)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. function changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! accounting for "Data and Analytics" function 
replace Func=17 if Func==18

sort IDlse YearMonth
generate TransferFunc = 0
replace  TransferFunc = 1 if IDlse==IDlse[_n-1] & Func!=Func[_n-1] & Func!=13 & Func[_n-1]!=13

sort IDlse YearMonth
bysort IDlse: generate TransferFuncC = sum(TransferFunc)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. subfunction changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferSubFunc = 0
replace  TransferSubFunc = 1 if IDlse==IDlse[_n-1] & SubFunc!=SubFunc[_n-1] & SubFunc!=94 & SubFunc[_n-1]!=94

sort IDlse YearMonth
bysort IDlse: generate TransferSubFuncC = sum(TransferSubFunc)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. internal transfers
*-?        either office, subfunc, or org4
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferInternal = 0 
replace  TransferInternal = 1 if IDlse==IDlse[_n-1] & ///
    ( (Office!=Office[_n-1]) | (SubFunc!=SubFunc[_n-1] & SubFunc!=94 & SubFunc[_n-1]!=94) | (Org4!=Org4[_n-1] & Org4!=. & Org4[_n-1]!=.) )

sort IDlse YearMonth
bysort IDlse: generate TransferInternalC = sum(TransferInternal)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. outcome variables: earnings
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate LogPay        = log(Pay)
generate LogBonus      = log(Bonus+1)
generate LogBenefit    = log(Benefit+1)
generate LogPackage    = log(Package)
generate PayBonus      = Pay + Bonus
generate LogPayBonus   = log(PayBonus)
generate BonusPayRatio = Bonus/Pay

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. manager id imputations  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in IDlseMHR {
    replace `var' = l1.`var' if IDlseMHR==. & l1.IDlseMHR!=. 
    replace `var' = f1.`var' if IDlseMHR==. & f1.IDlseMHR!=. & l1.IDlseMHR==. 
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? final step. save these worker outcomes  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture drop occurrence
sort IDlse YearMonth
bysort IDlse: generate occurrence = _n 
order occurrence, after(YearMonth)

order ///
    Year YearMonth occurrence IDlse IDlseMHR ///
    Female AgeBand Tenure WL Country ISOCode ///
    Func SubFunc Org4 Office OfficeCode StandardJob SalaryGrade VPA ///
    TransferSJV TransferSJVC TransferSJ TransferSJC ///
    ChangeSalaryGrade ChangeSalaryGradeC PromWL PromWLC ///
    TransferFunc TransferFuncC TransferSubFunc TransferSubFuncC ///
    TransferInternal TransferInternalC ///
    LogPayBonus LogPay LogBonus Pay Bonus ///
    Leaver LeaverPerm LeaverVol LeaverInv

label variable Year                "Year"
label variable YearMonth           "Year-Month"
label variable occurrence          "Sequential occurrence number for each employee in that month"
label variable IDlse               "Employee ID"
label variable IDlseMHR            "Manager ID"
label variable Female              "Female"
label variable AgeBand             "Age band"
label variable Tenure              "Years within the firm"
label variable WL                  "Work level: from lowest (1) to highest (6)"
label variable Country             "Working country"
label variable ISOCode             "ISO code of the working country"
label variable Func                "Function"
label variable SubFunc             "Subfunction"
label variable Org4                "Level 4 organization description"
label variable Office              "Work location: Office or Plant/Factory"
label variable OfficeCode          "Work location code: Office or Plant/Factory"
label variable StandardJob         "Standard job title"
label variable SalaryGrade         "Salary grade"
label variable VPA                 "Performance rating"
label variable TransferSJ          "= 1 in months when an individual's StandardJob is diff. from preceding months"
label variable TransferSJC         "Cumulative count of TransferSJ for an individual"
label variable TransferSJV         "= 1 when his StandardJob and SalaryGrade are diff. from last month"
label variable TransferSJVC        "Cumulative count of TransferSJV for an individual"
label variable ChangeSalaryGrade   "= 1 in months when an individual's SalaryGrade is diff. from preceding months"
label variable ChangeSalaryGradeC  "Cumulative count of ChangeSalaryGrade for an individual"
label variable PromWL              "= 1 in months when WL is greater from preceding months"
label variable PromWLC             "Cumulative count of PromWL for an individual"
label variable TransferFunc        "= 1 in months when an individual's Func is diff. from preceding months"
label variable TransferFuncC       "Cumulative count of TransferFunc for an individual"
label variable TransferSubFunc     "= 1 in months when SubFunc is diff. from preceding months"
label variable TransferSubFuncC    "Cumulative count of TransferSubFuncC for an individual"
label variable TransferInternal    "= 1 in months when either SubFunc or Office or Org4 is diff from last months"
label variable TransferInternalC   "Cumulative count of TransferInternal for an individual"
label variable LogPayBonus         "Pay + bonus (logs)"
label variable LogPay              "Pay (logs)"
label variable LogBonus            "Bonus (logs)"
label variable Pay                 "Pay"
label variable Bonus               "Bonus"
label variable Leaver              "= 1 in months when an individual leaves the firm"
label variable LeaverPerm          "= 1 in the month when an individual leaves the firm permanently"
label variable LeaverVol           "= 1 in the month when an individual quits (voluntarily exits)"
label variable LeaverInv           "= 1 in the month when an individual is fired (involuntarily exits)"

compress 
save "${TempData}/FinalFullSample.dta", replace 