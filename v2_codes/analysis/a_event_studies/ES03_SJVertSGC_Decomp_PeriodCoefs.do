/* 
This do file decomposes workers' standard job changes with simultaneous salary grade increases into three categories.
The high-flyer measure used here is CA30.

Then, I run event studies regressions on these four variables and report quarter 8 and quarter 28 estimates.

Notes on the event study regressions:
    (1) Workers in the regression sample include all four event groups. 
    (2) Never-treated employees are not included in the regressions.
    (3) The omitted group in the regression is month -3, -2, and -1 for all four treatment groups.
    (4) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Input: 
    "${TempData}/FinalAnalysisSample.dta"       <== created in 0103_03 do file

Output:
    "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp.txt"
    "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_QuarterYearAndPeriodCoefs.dta"
    "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_PeriodCoefs.gph"

RA: WWZ 
Time: 2025-08-05
*/

capture log close
log using "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. decompose TransferSJV into three categories:
*??         (1) within team (same manager, same function)
*??         (2) different team (different manager), and different function
*??         (3) different team (different manager), but same function
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. auxiliary variable: ChangeM and TransferSJSameM
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! first month for a worker
capture drop temp_first_month
sort IDlse YearMonth
bysort IDlse: egen temp_first_month = min(YearMonth)

*!! if the worker changes his manager 
capture drop ChangeM
generate ChangeM = 0 
replace  ChangeM = 1 if (IDlse[_n]==IDlse[_n-1] & IDlseMHR[_n]!=IDlseMHR[_n-1])
replace  ChangeM = 0  if YearMonth==temp_first_month & ChangeM==1
replace  ChangeM = . if IDlseMHR==. 

*!! lateral transfer under the same manager
capture drop TransferSJSameM
generate TransferSJSameM = TransferSJ
replace  TransferSJSameM = 0 if ChangeM==1 

*!! category (3): different manager + same function
capture drop TransferSJDiffMSameFunc
capture drop TransferSJDiffMSameFuncC
generate TransferSJDiffMSameFunc = TransferSJ 
replace  TransferSJDiffMSameFunc = 0 if TransferFunc==1 
replace  TransferSJDiffMSameFunc = 0 if TransferSJSameM==1
sort IDlse YearMonth
bysort IDlse: generate TransferSJDiffMSameFuncC= sum(TransferSJDiffMSameFunc)

*!! category (1): same manager + same function
capture drop TransferSJSameMSameFunc
capture drop TransferSJSameMSameFuncC
generate TransferSJSameMSameFunc = TransferSJ 
replace  TransferSJSameMSameFunc = 0 if TransferFunc==1 
replace  TransferSJSameMSameFunc = 0 if TransferSJDiffMSameFunc==1
sort IDlse YearMonth
bysort IDlse: generate TransferSJSameMSameFuncC= sum(TransferSJSameMSameFunc)

*!! category (2): different manager + different function
*&? variable TransferFunc can accurately describe this category

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. decomposition 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth

foreach var in TransferSJ TransferSJDiffMSameFunc TransferSJSameMSameFunc TransferFunc {

    if "`var'" == "TransferSJ"              local newvar SJVertSG
    if "`var'" == "TransferSJDiffMSameFunc" local newvar DiffMSameFuncSJV
    if "`var'" == "TransferSJSameMSameFunc" local newvar SameMSameFuncSJV
    if "`var'" == "TransferFunc"            local newvar DiffFuncSJV

    generate `newvar' =`var'
    replace  `newvar' = 0 if ChangeSalaryGrade==0	

    sort IDlse YearMonth
    bysort IDlse (YearMonth) : generate `newvar'C= sum(`newvar')
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. macros storing key regressors
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

GenerateEventDummies, event_prefix(CA30) max_pre_period(24) lto_max_post(84) hto_max_post(60)
    //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
    //&? It also stores all regressors in a global macro ${four_events_dummies}.

display "${four_events_dummies}"
    // CA30_LtoL_X_Pre_Before24 CA30_LtoL_X_Pre24 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Pre_Before24 CA30_LtoH_X_Pre24 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 
    // CA30_HtoH_X_Pre_Before24 CA30_HtoH_X_Pre24 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before24 CA30_HtoL_X_Pre24 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. macros storing equations to be evaluated
*-?        they are used to calculate yearly average coefficients
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

#delimit ;
global coef_0yr_to_1yr 
    ((CA30_LtoH_X_Post1 - CA30_LtoL_X_Post1)
    + (CA30_LtoH_X_Post2 - CA30_LtoL_X_Post2)
    + (CA30_LtoH_X_Post3 - CA30_LtoL_X_Post3)
    + (CA30_LtoH_X_Post4 - CA30_LtoL_X_Post4)
    + (CA30_LtoH_X_Post5 - CA30_LtoL_X_Post5)
    + (CA30_LtoH_X_Post6 - CA30_LtoL_X_Post6)
    + (CA30_LtoH_X_Post7 - CA30_LtoL_X_Post7)
    + (CA30_LtoH_X_Post8 - CA30_LtoL_X_Post8)
    + (CA30_LtoH_X_Post9 - CA30_LtoL_X_Post9)
    + (CA30_LtoH_X_Post10 - CA30_LtoL_X_Post10)
    + (CA30_LtoH_X_Post11 - CA30_LtoL_X_Post11)
    + (CA30_LtoH_X_Post12 - CA30_LtoL_X_Post12))/12;
global coef_1yr_to_2yr 
    ((CA30_LtoH_X_Post13 - CA30_LtoL_X_Post13)
    + (CA30_LtoH_X_Post14 - CA30_LtoL_X_Post14)
    + (CA30_LtoH_X_Post15 - CA30_LtoL_X_Post15)
    + (CA30_LtoH_X_Post16 - CA30_LtoL_X_Post16)
    + (CA30_LtoH_X_Post17 - CA30_LtoL_X_Post17)
    + (CA30_LtoH_X_Post18 - CA30_LtoL_X_Post18)
    + (CA30_LtoH_X_Post19 - CA30_LtoL_X_Post19)
    + (CA30_LtoH_X_Post20 - CA30_LtoL_X_Post20)
    + (CA30_LtoH_X_Post21 - CA30_LtoL_X_Post21)
    + (CA30_LtoH_X_Post22 - CA30_LtoL_X_Post22)
    + (CA30_LtoH_X_Post23 - CA30_LtoL_X_Post23) 
    + (CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24))/12;
global coef_2yr_to_3yr 
    ((CA30_LtoH_X_Post25 - CA30_LtoL_X_Post25)
    + (CA30_LtoH_X_Post26 - CA30_LtoL_X_Post26)
    + (CA30_LtoH_X_Post27 - CA30_LtoL_X_Post27)
    + (CA30_LtoH_X_Post28 - CA30_LtoL_X_Post28)
    + (CA30_LtoH_X_Post29 - CA30_LtoL_X_Post29)
    + (CA30_LtoH_X_Post30 - CA30_LtoL_X_Post30)
    + (CA30_LtoH_X_Post31 - CA30_LtoL_X_Post31)
    + (CA30_LtoH_X_Post32 - CA30_LtoL_X_Post32)
    + (CA30_LtoH_X_Post33 - CA30_LtoL_X_Post33)
    + (CA30_LtoH_X_Post34 - CA30_LtoL_X_Post34)
    + (CA30_LtoH_X_Post35 - CA30_LtoL_X_Post35) 
    + (CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36))/12;
global coef_3yr_to_4yr
    ((CA30_LtoH_X_Post37 - CA30_LtoL_X_Post37)
    + (CA30_LtoH_X_Post38 - CA30_LtoL_X_Post38)
    + (CA30_LtoH_X_Post39 - CA30_LtoL_X_Post39)
    + (CA30_LtoH_X_Post40 - CA30_LtoL_X_Post40)
    + (CA30_LtoH_X_Post41 - CA30_LtoL_X_Post41)
    + (CA30_LtoH_X_Post42 - CA30_LtoL_X_Post42)
    + (CA30_LtoH_X_Post43 - CA30_LtoL_X_Post43)
    + (CA30_LtoH_X_Post44 - CA30_LtoL_X_Post44)
    + (CA30_LtoH_X_Post45 - CA30_LtoL_X_Post45)
    + (CA30_LtoH_X_Post46 - CA30_LtoL_X_Post46)
    + (CA30_LtoH_X_Post47 - CA30_LtoL_X_Post47) 
    + (CA30_LtoH_X_Post48 - CA30_LtoL_X_Post48))/12;
global coef_4yr_to_5yr 
    ((CA30_LtoH_X_Post49 - CA30_LtoL_X_Post49)
    + (CA30_LtoH_X_Post50 - CA30_LtoL_X_Post50)
    + (CA30_LtoH_X_Post51 - CA30_LtoL_X_Post51)
    + (CA30_LtoH_X_Post52 - CA30_LtoL_X_Post52)
    + (CA30_LtoH_X_Post53 - CA30_LtoL_X_Post53)
    + (CA30_LtoH_X_Post54 - CA30_LtoL_X_Post54)
    + (CA30_LtoH_X_Post55 - CA30_LtoL_X_Post55)
    + (CA30_LtoH_X_Post56 - CA30_LtoL_X_Post56)
    + (CA30_LtoH_X_Post57 - CA30_LtoL_X_Post57)
    + (CA30_LtoH_X_Post58 - CA30_LtoL_X_Post58)
    + (CA30_LtoH_X_Post59 - CA30_LtoL_X_Post59)
    + (CA30_LtoH_X_Post60 - CA30_LtoL_X_Post60))/12;
global coef_5yr_to_6yr 
    ((CA30_LtoH_X_Post61 - CA30_LtoL_X_Post61)
    + (CA30_LtoH_X_Post62 - CA30_LtoL_X_Post62)
    + (CA30_LtoH_X_Post63 - CA30_LtoL_X_Post63)
    + (CA30_LtoH_X_Post64 - CA30_LtoL_X_Post64)
    + (CA30_LtoH_X_Post65 - CA30_LtoL_X_Post65)
    + (CA30_LtoH_X_Post66 - CA30_LtoL_X_Post66)
    + (CA30_LtoH_X_Post67 - CA30_LtoL_X_Post67)
    + (CA30_LtoH_X_Post68 - CA30_LtoL_X_Post68)
    + (CA30_LtoH_X_Post69 - CA30_LtoL_X_Post69)
    + (CA30_LtoH_X_Post70 - CA30_LtoL_X_Post70)
    + (CA30_LtoH_X_Post71 - CA30_LtoL_X_Post71)
    + (CA30_LtoH_X_Post72 - CA30_LtoL_X_Post72))/12;
global coef_6yr_to_7yr 
    ((CA30_LtoH_X_Post73 - CA30_LtoL_X_Post73)
    + (CA30_LtoH_X_Post74 - CA30_LtoL_X_Post74)
    + (CA30_LtoH_X_Post75 - CA30_LtoL_X_Post75)
    + (CA30_LtoH_X_Post76 - CA30_LtoL_X_Post76)
    + (CA30_LtoH_X_Post77 - CA30_LtoL_X_Post77)
    + (CA30_LtoH_X_Post78 - CA30_LtoL_X_Post78)
    + (CA30_LtoH_X_Post79 - CA30_LtoL_X_Post79)
    + (CA30_LtoH_X_Post80 - CA30_LtoL_X_Post80)
    + (CA30_LtoH_X_Post81 - CA30_LtoL_X_Post81)
    + (CA30_LtoH_X_Post82 - CA30_LtoL_X_Post82)
    + (CA30_LtoH_X_Post83 - CA30_LtoL_X_Post83)
    + (CA30_LtoH_X_Post84 - CA30_LtoL_X_Post84))/12;
global coef_0yr_to_3yr 
    ((CA30_LtoH_X_Post1 - CA30_LtoL_X_Post1)
    + (CA30_LtoH_X_Post2 - CA30_LtoL_X_Post2)
    + (CA30_LtoH_X_Post3 - CA30_LtoL_X_Post3)
    + (CA30_LtoH_X_Post4 - CA30_LtoL_X_Post4)
    + (CA30_LtoH_X_Post5 - CA30_LtoL_X_Post5)
    + (CA30_LtoH_X_Post6 - CA30_LtoL_X_Post6)
    + (CA30_LtoH_X_Post7 - CA30_LtoL_X_Post7)
    + (CA30_LtoH_X_Post8 - CA30_LtoL_X_Post8)
    + (CA30_LtoH_X_Post9 - CA30_LtoL_X_Post9)
    + (CA30_LtoH_X_Post10 - CA30_LtoL_X_Post10)
    + (CA30_LtoH_X_Post11 - CA30_LtoL_X_Post11)
    + (CA30_LtoH_X_Post12 - CA30_LtoL_X_Post12)
    + (CA30_LtoH_X_Post13 - CA30_LtoL_X_Post13)
    + (CA30_LtoH_X_Post14 - CA30_LtoL_X_Post14)
    + (CA30_LtoH_X_Post15 - CA30_LtoL_X_Post15)
    + (CA30_LtoH_X_Post16 - CA30_LtoL_X_Post16)
    + (CA30_LtoH_X_Post17 - CA30_LtoL_X_Post17)
    + (CA30_LtoH_X_Post18 - CA30_LtoL_X_Post18)
    + (CA30_LtoH_X_Post19 - CA30_LtoL_X_Post19)
    + (CA30_LtoH_X_Post20 - CA30_LtoL_X_Post20)
    + (CA30_LtoH_X_Post21 - CA30_LtoL_X_Post21)
    + (CA30_LtoH_X_Post22 - CA30_LtoL_X_Post22)
    + (CA30_LtoH_X_Post23 - CA30_LtoL_X_Post23) 
    + (CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24)
    + (CA30_LtoH_X_Post25 - CA30_LtoL_X_Post25)
    + (CA30_LtoH_X_Post26 - CA30_LtoL_X_Post26)
    + (CA30_LtoH_X_Post27 - CA30_LtoL_X_Post27)
    + (CA30_LtoH_X_Post28 - CA30_LtoL_X_Post28)
    + (CA30_LtoH_X_Post29 - CA30_LtoL_X_Post29)
    + (CA30_LtoH_X_Post30 - CA30_LtoL_X_Post30)
    + (CA30_LtoH_X_Post31 - CA30_LtoL_X_Post31)
    + (CA30_LtoH_X_Post32 - CA30_LtoL_X_Post32)
    + (CA30_LtoH_X_Post33 - CA30_LtoL_X_Post33)
    + (CA30_LtoH_X_Post34 - CA30_LtoL_X_Post34)
    + (CA30_LtoH_X_Post35 - CA30_LtoL_X_Post35) 
    + (CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36))/36;
global coef_3yr_to_7yr
    ((CA30_LtoH_X_Post37 - CA30_LtoL_X_Post37)
    + (CA30_LtoH_X_Post38 - CA30_LtoL_X_Post38)
    + (CA30_LtoH_X_Post39 - CA30_LtoL_X_Post39)
    + (CA30_LtoH_X_Post40 - CA30_LtoL_X_Post40)
    + (CA30_LtoH_X_Post41 - CA30_LtoL_X_Post41)
    + (CA30_LtoH_X_Post42 - CA30_LtoL_X_Post42)
    + (CA30_LtoH_X_Post43 - CA30_LtoL_X_Post43)
    + (CA30_LtoH_X_Post44 - CA30_LtoL_X_Post44)
    + (CA30_LtoH_X_Post45 - CA30_LtoL_X_Post45)
    + (CA30_LtoH_X_Post46 - CA30_LtoL_X_Post46)
    + (CA30_LtoH_X_Post47 - CA30_LtoL_X_Post47) 
    + (CA30_LtoH_X_Post48 - CA30_LtoL_X_Post48)
    + (CA30_LtoH_X_Post49 - CA30_LtoL_X_Post49)
    + (CA30_LtoH_X_Post50 - CA30_LtoL_X_Post50)
    + (CA30_LtoH_X_Post51 - CA30_LtoL_X_Post51)
    + (CA30_LtoH_X_Post52 - CA30_LtoL_X_Post52)
    + (CA30_LtoH_X_Post53 - CA30_LtoL_X_Post53)
    + (CA30_LtoH_X_Post54 - CA30_LtoL_X_Post54)
    + (CA30_LtoH_X_Post55 - CA30_LtoL_X_Post55)
    + (CA30_LtoH_X_Post56 - CA30_LtoL_X_Post56)
    + (CA30_LtoH_X_Post57 - CA30_LtoL_X_Post57)
    + (CA30_LtoH_X_Post58 - CA30_LtoL_X_Post58)
    + (CA30_LtoH_X_Post59 - CA30_LtoL_X_Post59)
    + (CA30_LtoH_X_Post60 - CA30_LtoL_X_Post60)
    + (CA30_LtoH_X_Post61 - CA30_LtoL_X_Post61)
    + (CA30_LtoH_X_Post62 - CA30_LtoL_X_Post62)
    + (CA30_LtoH_X_Post63 - CA30_LtoL_X_Post63)
    + (CA30_LtoH_X_Post64 - CA30_LtoL_X_Post64)
    + (CA30_LtoH_X_Post65 - CA30_LtoL_X_Post65)
    + (CA30_LtoH_X_Post66 - CA30_LtoL_X_Post66)
    + (CA30_LtoH_X_Post67 - CA30_LtoL_X_Post67)
    + (CA30_LtoH_X_Post68 - CA30_LtoL_X_Post68)
    + (CA30_LtoH_X_Post69 - CA30_LtoL_X_Post69)
    + (CA30_LtoH_X_Post70 - CA30_LtoL_X_Post70)
    + (CA30_LtoH_X_Post71 - CA30_LtoL_X_Post71)
    + (CA30_LtoH_X_Post72 - CA30_LtoL_X_Post72)
    + (CA30_LtoH_X_Post73 - CA30_LtoL_X_Post73)
    + (CA30_LtoH_X_Post74 - CA30_LtoL_X_Post74)
    + (CA30_LtoH_X_Post75 - CA30_LtoL_X_Post75)
    + (CA30_LtoH_X_Post76 - CA30_LtoL_X_Post76)
    + (CA30_LtoH_X_Post77 - CA30_LtoL_X_Post77)
    + (CA30_LtoH_X_Post78 - CA30_LtoL_X_Post78)
    + (CA30_LtoH_X_Post79 - CA30_LtoL_X_Post79)
    + (CA30_LtoH_X_Post80 - CA30_LtoL_X_Post80)
    + (CA30_LtoH_X_Post81 - CA30_LtoL_X_Post81)
    + (CA30_LtoH_X_Post82 - CA30_LtoL_X_Post82)
    + (CA30_LtoH_X_Post83 - CA30_LtoL_X_Post83)
    + (CA30_LtoH_X_Post84 - CA30_LtoL_X_Post84))/48;
#delimit cr

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions and create the coefplot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

//&? The four outcome variables are:
//&? TransferSJVC SameMSameFuncSJVC DiffMSameFuncSJVC DiffFuncSJVC 

rename (SameMSameFuncSJVC DiffMSameFuncSJVC) (SameMVC DiffMVC)

foreach var in SJVertSGC SameMVC DiffMVC DiffFuncSJVC {

    if "`var'" == "SJVertSGC"    global number "3_0"
    if "`var'" == "SameMVC"      global number "3_1"
    if "`var'" == "DiffMVC"      global number "3_2"
    if "`var'" == "DiffFuncSJVC" global number "3_3"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. main regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(CA30) pre_window_len(24)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(84) outcome(`var') statistics(0)
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(CA30) pre_window_len(24)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var') statistics(0)

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(CA30) pre_window_len(24)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(CA30) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    Double_Diff, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var')
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 5. Storing yearly and period coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    xlincom ///
        (coef_0yr_to_1yr = ${coef_0yr_to_1yr}) ///
        (coef_1yr_to_2yr = ${coef_1yr_to_2yr}) ///
        (coef_2yr_to_3yr = ${coef_2yr_to_3yr}) ///
        (coef_3yr_to_4yr = ${coef_3yr_to_4yr}) ///
        (coef_4yr_to_5yr = ${coef_4yr_to_5yr}) ///
        (coef_5yr_to_6yr = ${coef_5yr_to_6yr}) ///
        (coef_6yr_to_7yr = ${coef_6yr_to_7yr}) ///
        (coef_0yr_to_3yr = ${coef_0yr_to_3yr}) ///
        (coef_3yr_to_7yr = ${coef_3yr_to_7yr}) ///
        , post

    generate Year_`var'_gains = _n if inrange(_n, 1, 9)

    generate ccoef_`var'_gains = _n if inrange(_n, 1, 9)
    replace  ccoef_`var'_gains = r(table)["b", "coef_0yr_to_1yr"] if _n==1 
    replace  ccoef_`var'_gains = r(table)["b", "coef_1yr_to_2yr"] if _n==2
    replace  ccoef_`var'_gains = r(table)["b", "coef_2yr_to_3yr"] if _n==3
    replace  ccoef_`var'_gains = r(table)["b", "coef_3yr_to_4yr"] if _n==4
    replace  ccoef_`var'_gains = r(table)["b", "coef_4yr_to_5yr"] if _n==5
    replace  ccoef_`var'_gains = r(table)["b", "coef_5yr_to_6yr"] if _n==6
    replace  ccoef_`var'_gains = r(table)["b", "coef_6yr_to_7yr"] if _n==7
    replace  ccoef_`var'_gains = r(table)["b", "coef_0yr_to_3yr"] if _n==8
    replace  ccoef_`var'_gains = r(table)["b", "coef_3yr_to_7yr"] if _n==9

    generate llb_`var'_gains = _n if inrange(_n, 1, 9)
    replace  llb_`var'_gains = r(table)["ll", "coef_0yr_to_1yr"] if _n==1
    replace  llb_`var'_gains = r(table)["ll", "coef_1yr_to_2yr"] if _n==2
    replace  llb_`var'_gains = r(table)["ll", "coef_2yr_to_3yr"] if _n==3
    replace  llb_`var'_gains = r(table)["ll", "coef_3yr_to_4yr"] if _n==4
    replace  llb_`var'_gains = r(table)["ll", "coef_4yr_to_5yr"] if _n==5
    replace  llb_`var'_gains = r(table)["ll", "coef_5yr_to_6yr"] if _n==6
    replace  llb_`var'_gains = r(table)["ll", "coef_6yr_to_7yr"] if _n==7
    replace  llb_`var'_gains = r(table)["ll", "coef_0yr_to_3yr"] if _n==8
    replace  llb_`var'_gains = r(table)["ll", "coef_3yr_to_7yr"] if _n==9

    generate uub_`var'_gains = _n if inrange(_n, 1, 9)
    replace  uub_`var'_gains = r(table)["ul", "coef_0yr_to_1yr"] if _n==1
    replace  uub_`var'_gains = r(table)["ul", "coef_1yr_to_2yr"] if _n==2
    replace  uub_`var'_gains = r(table)["ul", "coef_2yr_to_3yr"] if _n==3
    replace  uub_`var'_gains = r(table)["ul", "coef_3yr_to_4yr"] if _n==4
    replace  uub_`var'_gains = r(table)["ul", "coef_4yr_to_5yr"] if _n==5
    replace  uub_`var'_gains = r(table)["ul", "coef_5yr_to_6yr"] if _n==6
    replace  uub_`var'_gains = r(table)["ul", "coef_6yr_to_7yr"] if _n==7
    replace  uub_`var'_gains = r(table)["ul", "coef_0yr_to_3yr"] if _n==8
    replace  uub_`var'_gains = r(table)["ul", "coef_3yr_to_7yr"] if _n==9

    eststo `var'
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step y. store the event studies results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep ///
    PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* ///
    Year_* ccoef_* llb_* uub_* 

keep if inrange(_n, 1, 41)

save "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_QuarterYearAndPeriodCoefs.dta", replace 

log close

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step z. visualize the results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-1. period coefficients in a stacked bar plot
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_QuarterYearAndPeriodCoefs.dta", clear 

keep Year_* ccoef_* llb_* uub_* 
rename (ccoef_SJVertSGC_gains llb_SJVertSGC_gains uub_SJVertSGC_gains ccoef_SameMVC_gains llb_SameMVC_gains uub_SameMVC_gains ccoef_DiffMVC_gains llb_DiffMVC_gains uub_DiffMVC_gains ccoef_DiffFuncSJVC_gains llb_DiffFuncSJVC_gains uub_DiffFuncSJVC_gains) (coef_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains coef_SameMVC_gains lb_SameMVC_gains ub_SameMVC_gains coef_DiffMVC_gains lb_DiffMVC_gains ub_DiffMVC_gains coef_DiffFuncSJVC_gains lb_DiffFuncSJVC_gains ub_DiffFuncSJVC_gains)

generate Year = Year_SJVertSGC_gains

foreach var in SameMVC DiffMVC DiffFuncSJVC {
    generate frac_`var'_gains = coef_`var'_gains / coef_SJVertSGC_gains
    generate frac_`var'_gains_int = round(frac_`var'_gains * 100)
    tostring frac_`var'_gains_int, generate(frac_`var'_gains_str)
}

egen test = rowtotal(frac_SameMVC_gains frac_DiffMVC_gains frac_DiffFuncSJVC_gains)
tabulate test, sort
    //&? roughly 1, as expected

foreach var in SameMVC DiffMVC DiffFuncSJVC {
    forvalues i = 1/9 {
        global frac_`var'_`i' = frac_`var'_gains_str[`i']
    }
}

graph bar coef_SameMVC_gains coef_DiffMVC_gains coef_DiffFuncSJVC_gains if inrange(Year, 1, 7), ///
    over(Year, gap(5)) stack ///
    scheme(tab2) name(bar_stacked, replace) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions")) ///
    b1title("Years since manager change") ytitle("Coefficients value") title("Decomposition of standard job changes") subtitle("(with simultaneous salary grade increases)") ///
    ylabel(0(0.01)0.2, grid gstyle(dot)) ///
    text(0.180 0.00 "reporting % of total standard job changes", size(medium) placement(e)) ///
    text(0.160 0.00 "(with simultaneous salary grade increases)", size(medium) placement(e)) ///
    text(0.015 23.0 "${frac_DiffMVC_2}"     , size(medium)  placement(c)) ///
    text(0.035 23.0 "${frac_DiffFuncSJVC_2}", size(medium)  placement(n)) ///
    text(0.03  36.5 "${frac_DiffMVC_3}"     , size(medium)  placement(c)) ///
    text(0.055 36.5 "${frac_DiffFuncSJVC_3}", size(medium)  placement(n)) ///
    text(0.045 50.5 "${frac_DiffMVC_4}"     , size(medium)  placement(c)) ///
    text(0.075 50.5 "${frac_DiffFuncSJVC_4}", size(medium)  placement(n)) ///
    text(0.06  64.0 "${frac_DiffMVC_5}"     , size(medium)  placement(c)) ///
    text(0.10  64.0 "${frac_DiffFuncSJVC_5}", size(medium)  placement(n)) ///
    text(0.06  77.5 "${frac_DiffMVC_6}"     , size(medium)  placement(c)) ///
    text(0.12  77.5 "${frac_DiffFuncSJVC_6}", size(medium)  placement(n)) ///
    text(0.06  91.0 "${frac_DiffMVC_7}"     , size(medium)  placement(c)) ///
    text(0.11  91.0 "${frac_DiffFuncSJVC_7}", size(medium)  placement(n))
graph export "${EventStudyResults}/CA30_Outcome3_5_SJVertSGC_Decomp_YearlyAggregation.pdf", replace as(pdf)

capture drop Period
tostring Year, generate(Period)
format Period %15s
replace Period="Year 0-3" if Period=="8"
replace Period="Year 4-7" if Period=="9"

graph bar coef_SameMVC_gains coef_DiffMVC_gains coef_DiffFuncSJVC_gains if inrange(Year, 8, 9), ///
    over(Period, gap(10)) stack ///
    scheme(tab2) name(bar_stacked, replace) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions")) ///
    b1title("") ytitle("Coefficients value") ///
    ylabel(0(0.01)0.15, grid gstyle(dot)) ///
    text(0.130  0.00 "reporting % of total lateral moves", size(medium) placement(e)) ///
    text(0.0025 27.5 "${frac_SameMVC_8}%"     , size(vsmall)  placement(e)) ///
    text(0.018  27.5 "${frac_DiffMVC_8}%"     , size(vsmall)  placement(e)) ///
    text(0.03   28.0 "${frac_DiffFuncSJVC_8}%", size(vsmall)  placement(e)) ///
    text(0.015  70.0 "${frac_SameMVC_9}%"     , size(medium)  placement(e)) ///
    text(0.060  70.0 "${frac_DiffMVC_9}%"     , size(medium)  placement(e)) ///
    text(0.095  73.0 "${frac_DiffFuncSJVC_9}%", size(medium)  placement(n))
graph save "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_PeriodCoefs.gph", replace
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-2. overlaying the quarterly coefficients
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_QuarterYearAndPeriodCoefs.dta", clear

keep ///
    quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains ///
    quarter_SameMVC_gains coeff_SameMVC_gains lb_SameMVC_gains ub_SameMVC_gains ///
    quarter_DiffMVC_gains coeff_DiffMVC_gains lb_DiffMVC_gains ub_DiffMVC_gains ///
    quarter_DiffFuncSJVC_gains coeff_DiffFuncSJVC_gains lb_DiffFuncSJVC_gains ub_DiffFuncSJVC_gains

replace quarter_SJVertSGC_gains    = quarter_SJVertSGC_gains - 0.22
replace quarter_SameMVC_gains      = quarter_SameMVC_gains  - 0.11
replace quarter_DiffFuncSJVC_gains = quarter_DiffFuncSJVC_gains + 0.11

twoway ///
    (scatter coeff_SameMVC_gains quarter_SameMVC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SameMVC_gains ub_SameMVC_gains quarter_SameMVC_gains, lcolor(ebblue)) ///
    (scatter coeff_DiffMVC_gains quarter_DiffMVC_gains, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_DiffMVC_gains ub_DiffMVC_gains quarter_DiffMVC_gains, lcolor(magenta)) ///
    (scatter coeff_DiffFuncSJVC_gains quarter_DiffFuncSJVC_gains, lcolor(dkgreen) mcolor(dkgreen)) ///
    (rcap lb_DiffFuncSJVC_gains ub_DiffFuncSJVC_gains quarter_DiffFuncSJVC_gains, lcolor(dkgreen)) ///
    (scatter coeff_SJVertSGC_gains quarter_SJVertSGC_gains, lcolor(teal) mcolor(teal)) ///
    (rcap lb_SJVertSGC_gains ub_SJVertSGC_gains quarter_SJVertSGC_gains, lcolor(teal)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ytitle("Coefficient values", size(medlarge)) ///
    legend(label(2 "Within team") label(4 "Across teams, within function") label(6 "Across teams, across functions") label(8 "All lateral moves") order(8 2 4 6) position(6) ring(0) size(small))
graph export "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_OverlayingQuarterCoefs.pdf", replace as(pdf)