/* 
This do file plots the flow plot across subfunctions.

RA: WWZ 
Time: 2025-08-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. aggregate subfunctions based on their sizes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

keep IDlse Year YearMonth SubFunc 

tab SubFunc, sort nolabel

generate SubFunc_13 = (SubFunc==13) if !missing(SubFunc)
generate SubFunc_37 = (SubFunc==37) if !missing(SubFunc)
generate SubFunc_39 = (SubFunc==39) if !missing(SubFunc)
generate SubFunc_22 = (SubFunc==22) if !missing(SubFunc)
generate SubFunc_35 = (SubFunc==35) if !missing(SubFunc)
generate SubFunc_50 = (SubFunc==50) if !missing(SubFunc)
generate SubFunc_53 = (SubFunc==53) if !missing(SubFunc)
generate SubFunc_4  = (SubFunc==4) if !missing(SubFunc)
generate SubFunc_14 = (SubFunc==14) if !missing(SubFunc)
generate SubFunc_52 = (SubFunc==52) if !missing(SubFunc)
generate SubFunc_17 = (SubFunc==17) if !missing(SubFunc)
generate SubFunc_O  = 1 if !missing(SubFunc)
replace  SubFunc_O  = 0 if (SubFunc_13==1 | SubFunc_37==1 | SubFunc_39==1 | SubFunc_22==1 | SubFunc_35==1 | SubFunc_50==1 | SubFunc_53==1 | SubFunc_4==1 | SubFunc_14==1 | SubFunc_52==1 | SubFunc_17==1)

generate SubFuncAgg = . 
replace  SubFuncAgg = 1  if SubFunc_4==1
replace  SubFuncAgg = 2  if SubFunc_14==1
replace  SubFuncAgg = 3  if SubFunc_13==1
replace  SubFuncAgg = 4  if SubFunc_17==1
replace  SubFuncAgg = 5  if SubFunc_22==1
replace  SubFuncAgg = 6  if SubFunc_35==1
replace  SubFuncAgg = 7  if SubFunc_39==1
replace  SubFuncAgg = 8  if SubFunc_50==1
replace  SubFuncAgg = 9  if SubFunc_52==1
replace  SubFuncAgg = 10 if SubFunc_53==1
replace  SubFuncAgg = 11 if SubFunc_37==1
replace  SubFuncAgg = 12 if SubFunc_O ==1

label define SubFuncAgg ///
    1  "Consumer Relations" ///
    2  "Customer and Account Management" ///
    3  "Customer Management" ///
    4  "Engineering" ///
    5  "Finance Business Partnering" ///
    6  "Logistics" ///
    7  "Marketing Category" ///
    8  "Planning" ///
    9  "Procurement" ///
    10 "Product Development" ///
    11 "Supply chain" ///
    12 "Others"
label values SubFuncAgg SubFuncAgg

keep  IDlse YearMonth Year SubFuncAgg
order IDlse YearMonth Year SubFuncAgg

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. collapse into (first subfunction, last subfunction) level
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

collapse (first) SubFuncFirst=SubFuncAgg (last) SubFuncLast=SubFuncAgg, by(IDlse Year)
label values SubFuncFirst SubFuncAgg
label values SubFuncLast SubFuncAgg

generate one  = 1

collapse (sum) Size=one, by(SubFuncFirst SubFuncLast)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. plotting 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

sankey Size if SubFuncFirst!=SubFuncLast, ///
    from(SubFuncFirst) to(SubFuncLast) boxwidth(2.5) offset(30) novalues ///
    labangle(0) labpos(3) labg(1) sort1(name, reverse)
graph export "${Round1Results}/MoveAcrossSubFuncs_ExcludeStayers.pdf", replace as(pdf)

