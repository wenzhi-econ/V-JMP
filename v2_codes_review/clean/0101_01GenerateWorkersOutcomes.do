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

Proposed Changes:
	1. SalaryGrade does not have any missing values but have some UNKNW values coded with 785.
		   Subfunc has UNKNOWN vlues coded with 94 (very small number)
		   Func has UNKNW values coded with 13 (very small number)
			Changed lines: 57-58, 110-111, 121-122
		
	2. StandardJob has some values with DO NOT USE such as: 
		eCommerce Manager_eCommerce
		eCommerce Manager_eCommerce-DO NOT USE 
		We can exlude these from job transfers maybe
		The DO NOT USE usually is followed up by a more detailed description of the same general job emerging.
		Example: Field Sales Administrator -> Field Sales Administrator-DO NOT USE -> Field Sales Administrator_Proximity
		A more conservative Job Transfer calculation could count these as the same job.
		I think this can be a good robustness check as well. 
		Again very small unknow values coded with  UNKNW. (only 13 people)
			Changed lines: 80-90
			
	3. Robustness idea: Ignore unknown values by adding for example:
		replace  ChangeSalaryGrade = 1 if IDlse==IDlse[_n-1] & SalaryGrade!=SalaryGrade[_n-1] & SalaryGrade!=. & SalaryGrade!= 785 
		& SalaryGrade[_n-1]!=. & SalaryGrade[_n-1]!= 785  /// additions
		
		We can also replace the missing values from for example the salary grade from the month before or if this is the workers
		first month the month after the missing value. Right now we are counting missing to a salary grade as a salary grade change.
		Even if the salary grade before and after the missing month is the same. Example:
		ChangeSalaryGrade	IDlse	SalaryGrade	YearMonth
		0					515749	1A			2014m12
		0					515749	UNKNW		2015m1
		1					515749	1A			2015m2



RA: AT 
Time: 2025-08-16
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
generate ChangeSalaryGrade = 0 & SalaryGrade!=. & SalaryGrade!= 785
replace  ChangeSalaryGrade = 1 if IDlse==IDlse[_n-1] & SalaryGrade!=SalaryGrade[_n-1] & SalaryGrade!=. & SalaryGrade!= 785 

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

sort IDlse YearMonth

** A more conservative way to calculate job transfers
gen not_use = regexm(upper(StandardJob), "DO NOT USE")
bysort IDlse: egen not_use_jobs= max(not_use)
gen CleanJob = upper(StandardJob)
replace CleanJob = regexr(CleanJob, "[()\\-\\s]*DO NOT USE[()\\-\\s]*", "")
replace CleanJob = trim(CleanJob)
gen BaseJob = CleanJob
replace BaseJob = substr(CleanJob, 1, strpos(CleanJob, "_") - 1) if strpos(CleanJob, "_") > 0

generate TransferSJ = 0 if BaseJob!="" &  BaseJob!="UNKNW" 
replace  TransferSJ = 1 if (IDlse==IDlse[_n-1] & BaseJob!=BaseJob[_n-1] & BaseJob!="" & BaseJob!="UNKNW")

sort IDlse YearMonth
bysort IDlse: generate TransferSJC = sum(TransferSJ)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. standard job changes with salary grade changes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate TransferSJV = TransferSJ
replace  TransferSJV = 0 if ChangeSalaryGrade==0	

sort IDlse YearMonth
bysort IDlse: generate TransferSJVC = sum(TransferSJV)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. function changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferFunc = 0 if Func!=. & Func!=13
replace  TransferFunc = 1 if IDlse==IDlse[_n-1] & Func!=Func[_n-1]  & Func!=. & Func!=13

sort IDlse YearMonth
bysort IDlse: generate TransferFuncC = sum(TransferFunc)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. subfunction changes 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
generate TransferSubFunc = 0 if SubFunc!=.  & SubFunc!=94
replace  TransferSubFunc = 1 if IDlse==IDlse[_n-1] & SubFunc!=SubFunc[_n-1] & SubFunc!=. & SubFunc!=94

sort IDlse YearMonth
bysort IDlse: generate TransferSubFuncC = sum(TransferSubFunc)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-5. internal transfers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-5-1. measure 1: either office, subfunc, or org4
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
generate TransferInternal = 0 & Office!=. & SubFunc!=. & Org4!=. 
replace  TransferInternal = 1 if IDlse==IDlse[_n-1] & ///
    ((OfficeCode!=OfficeCode[_n-1] & OfficeCode!=.) | (SubFunc!=SubFunc[_n-1] & SubFunc!=.) | (Org4!=Org4[_n-1] & Org4!=.))

sort IDlse YearMonth
bysort IDlse: generate TransferInternalC = sum(TransferInternal)

*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!
*!! s-2-5-2. measure 2: either office, StandardJob, or org4
*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!*!!

sort IDlse YearMonth
generate TransferInternalSJ = 0 if Office!=. & StandardJob!="" & Org4!=. 
replace  TransferInternalSJ = 1 if IDlse==IDlse[_n-1] & ///
    ((OfficeCode!=OfficeCode[_n-1] & OfficeCode!=.) | (StandardJob!=StandardJob[_n-1] & StandardJob!="") | (Org4!=Org4[_n-1] & Org4!=.))

sort IDlse YearMonth
bysort IDlse: generate TransferInternalSJC = sum(TransferInternalSJ)

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

label variable LogPayBonus "Pay + bonus (logs)"
label variable LogPay      "Pay (logs)"
label variable LogBonus    "Bonus (logs)"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. manager id imputations  
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
    TransferInternal TransferInternalC TransferInternalSJ TransferInternalSJC ///
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
label variable TransferSJ          "= 1 in months when an individual's StandardJob is diff. than preceding months"
label variable TransferSJC         "Cumulative count of TransferSJ for an individual"
label variable TransferSJV         "= 1 when his StandardJob is diff. than last month but SalaryGrade is the same"
label variable TransferSJVC        "Cumulative count of TransferSJV for an individual"
label variable ChangeSalaryGrade   "= 1 in months when an individual's SalaryGrade is diff. than preceding months"
label variable ChangeSalaryGradeC  "Cumulative count of ChangeSalaryGrade for an individual"
label variable PromWL              "= 1 in months when WL is greater than preceding months"
label variable PromWLC             "Cumulative count of PromWL for an individual"
label variable TransferFunc        "= 1 in months when an individual's Func is diff. than preceding months"
label variable TransferFuncC       "Cumulative count of TransferFunc for an individual"
label variable TransferSubFunc     "= 1 in months when SubFunc is diff. than preceding months"
label variable TransferSubFuncC    "Cumulative count of TransferSubFuncC for an individual"
label variable TransferInternal    "= 1 in months when either SubFunc or Office or Org4 is diff than last months"
label variable TransferInternalC   "Cumulative count of TransferInternal for an individual"
label variable TransferInternalSJ  "= 1 in months when either StandardJob or Office or Org4 is diff than last months"
label variable TransferInternalSJC "Cumulative count of TransferInternalSJ for an individual"
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
