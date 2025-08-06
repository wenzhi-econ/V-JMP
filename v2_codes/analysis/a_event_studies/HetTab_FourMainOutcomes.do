/* 
This do file investigates a wide variety of heterogeneities on the main outcomes. 

For ChangeSalaryGradeC TransferSJVC outcomes, a simplified event study is implemented (months -1, -2, -3 are taken as the reference group).
For PromWLC outcome, a simplified and modified event study is implemented (month 0 is taken as the omitted group).
For LeaverPerm outcome, a cross-sectional regression is implemented. 

Input:
    "${TempData}/0104AnalysisSample_WithHeteroIndicators.dta" <== created in 0104 do file 

Results:
    "${latex_file}"

RA: WWZ 
Time: 2025-04-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. load the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0104AnalysisSample_WithHeteroIndicators.dta", clear 

global Hetero_Vars TenureMHigh SameOffice Young SameGender OfficeSizeHigh JobNum LaborRegHigh WPerf WPerf0p10p90 TeamPerfMBase

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. "event * post" dummies
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate Post1 = (Rel_Time > 0) if Rel_Time != .
generate LtoLXPost1 = CA30_LtoL * Post1
generate LtoHXPost1 = CA30_LtoH * Post1
generate HtoHXPost1 = CA30_HtoH * Post1
generate HtoLXPost1 = CA30_HtoL * Post1

/* 
Notes:
    (1) The definition of "Post" in the above procedures is a different from the convention: FT_Rel_Time==0 is not included in FT_Post1. 
    (2) This is because in the "PromWLC" regression, we need to use month 0 as the reference month. 
    (3) The uniqueness of the "PromWLC" regression comes from the fact that we only focus on WL1 workers, mechanically leading to no work level promotions before manager change.
    (4) This won't affect regressions for other outcome variables, since we never include month 0 in "ChangeSalaryGradeC" and "TransferSJVC" regressions.
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. "event * post * heterogeneity indicator" dummies
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in $Hetero_Vars {
    generate LtoLXPost1X`var' = LtoLXPost1 * `var'1
    generate LtoHXPost1X`var' = LtoHXPost1 * `var'1
    generate HtoHXPost1X`var' = HtoHXPost1 * `var'1
    generate HtoLXPost1X`var' = HtoLXPost1 * `var'1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event-study regressions on non-exit outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach hetero_var in $Hetero_Vars {
    global hetero_regressors ///
        LtoLXPost1 LtoLXPost1X`hetero_var' ///
        LtoHXPost1 LtoHXPost1X`hetero_var' ///
        HtoHXPost1 HtoHXPost1X`hetero_var' ///
        HtoLXPost1 HtoLXPost1X`hetero_var'

    foreach outcome in ChangeSalaryGradeC TransferSJVC PromWLC {

        //&? For salary change and later move variables, the reference month is -1, -2, -3.
        if "`outcome'" != "PromWLC" {
            reghdfe `outcome' $hetero_regressors  ///
                if (Rel_Time==-1 | Rel_Time==-2 | Rel_Time==-3 | Rel_Time==58 | Rel_Time==59 | Rel_Time==60) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
        }

        //&? For work level promotion, due to the nature of the sample restrictions, the reference month is 0.
        if "`outcome'" == "PromWLC" {
            reghdfe `outcome' $hetero_regressors  ///
                if (Rel_Time==0 | Rel_Time==58 | Rel_Time==59 | Rel_Time==60) ///
                , absorb(IDlse YearMonth)  vce(cluster IDlseMHR)
        }

        //&? "LtoH * post * heterogeneity indicator" - "LtoL * post * heterogeneity indicator"
        xlincom (LtoHXPost1X`hetero_var' - LtoLXPost1X`hetero_var'), level(95) post
            if "`outcome'" == "ChangeSalaryGradeC" local outcome_name CSGC
            if "`outcome'" == "TransferSJVC"       local outcome_name TSJVC
            if "`outcome'" == "PromWLC"            local outcome_name PWLC
            est store `hetero_var'_`outcome_name'
    }

}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run cross-sectional regressions: exit outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. new variables for event outcomes  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! s-3-1-1. relative exit time
capture drop Leaver
sort IDlse YearMonth
bysort IDlse: egen Leaver = max(LeaverPerm)

bysort IDlse: egen temp = max(YearMonth)
generate Leave_Time = . 
replace  Leave_Time = temp if Leaver == 1
format Leave_Time %tm
drop temp

generate Rel_Leave_Time = Leave_Time - Event_Time

label variable Leaver            "=1, if the worker left the firm during the dataset period"
label variable Leave_Time        "Time when the worker left the firm, missing if he stays during the sample period"
label variable Rel_Leave_Time    "Leave_Time - Event_Time"

*!! s-3-1-2. outcome variable: if the worker left the firm within 2 years after the event
generate LV_2yrs  = inrange(Rel_Leave_Time, 0, 24)

*!! s-3-1-3. event * heterogeneity indicators
foreach var in $Hetero_Vars {
    generate LtoLX`var' = CA30_LtoL * `var'1
    generate LtoHX`var' = CA30_LtoH * `var'1
    generate HtoHX`var' = CA30_HtoH * `var'1
    generate HtoLX`var' = CA30_HtoL * `var'1
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. keep only a cross-section of treated workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if YearMonth==Event_Time
    //&? keep one observation for one worker,
    //&? we are using control variables at the time of treatment for four treatment groups

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. run cross-sectional regressions on exit outcomes
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

summarize Event_Time, detail
    global LastMonth = r(max)
    global LastPossibleEventTime = ${LastMonth} - 12 * 2 
        //&? only exit outcomes of these workers (whose event dates are before this time) can be correctly identified 

foreach hetero_var in $Hetero_Vars {
    
    global hetero_regressors ///
        LtoLX`hetero_var' ///
        CA30_LtoH LtoHX`hetero_var' ///
        CA30_HtoH HtoHX`hetero_var' ///
        CA30_HtoL HtoLX`hetero_var'
            //&? CA30_LtoL group is omitted.

    reghdfe LV_2yrs ${hetero_regressors} if Event_Time<=${LastPossibleEventTime}, ///
        vce(cluster IDlseMHR) absorb(Office##Func AgeBand##Female Event_Time)

    xlincom (LtoHX`hetero_var'), level(95) post
        est store `hetero_var'_Exit
    
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\"
global latex_titles       "& \multicolumn{1}{c}{Lateral move} & \multicolumn{1}{c}{Salary grade increase} & \multicolumn{1}{c}{Work level promotion} & \multicolumn{1}{c}{Exit from firm} \\"
global latex_file         "${EventStudyResults}/HetTab_FourMainOutcomes.tex"

global latex_panel_A      "\addlinespace[5pt] \multicolumn{5}{l}{{\textit{Panel (a): worker and manager characteristics}}} \\ [5pt]"
global latex_panel_B      "\addlinespace[5pt] \multicolumn{5}{l}{{\textit{Panel (b): office and country-wide characteristics}}} \\ [5pt]"
global latex_panel_C      "\addlinespace[5pt] \multicolumn{5}{l}{{\textit{Panel (c): worker performance}}} \\ [7pt]"

esttab TenureMHigh_TSJVC TenureMHigh_CSGC TenureMHigh_PWLC TenureMHigh_Exit using "${latex_file}" ///
    , replace style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Manager tenure, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") ///
    posthead("${latex_titles}" "${latex_numbers}" "${latex_midrule}" "${latex_panel_A}")
esttab SameOffice_TSJVC SameOffice_CSGC SameOffice_PWLC SameOffice_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same office as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab SameGender_TSJVC SameGender_CSGC SameGender_PWLC SameGender_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Same gender as manager") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab Young_TSJVC Young_CSGC Young_PWLC Young_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker age, young") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab OfficeSizeHigh_TSJVC OfficeSizeHigh_CSGC OfficeSizeHigh_PWLC OfficeSizeHigh_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office size, large") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("${latex_midrule}" "${latex_panel_B}") posthead("") prefoot("") postfoot("")
esttab JobNum_TSJVC JobNum_CSGC JobNum_PWLC JobNum_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Office job diversity, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab LaborRegHigh_TSJVC LaborRegHigh_CSGC LaborRegHigh_PWLC LaborRegHigh_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Labor laws, high") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")

esttab WPerf_TSJVC WPerf_CSGC WPerf_PWLC WPerf_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("${latex_midrule}" "${latex_panel_C}") posthead("") prefoot("") postfoot("")
esttab WPerf0p10p90_TSJVC WPerf0p10p90_CSGC WPerf0p10p90_PWLC WPerf0p10p90_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Worker performance, high (p90)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("")
esttab TeamPerfMBase_TSJVC TeamPerfMBase_CSGC TeamPerfMBase_PWLC TeamPerfMBase_Exit using "${latex_file}" ///
    , append style(tex) fragment nocons nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    keep(lc_1) coeflabels(lc_1 "Team performance, high (p50)") ///
    cells(b(star fmt(3)) se(par fmt(2))) starlevels(* 0.1 ** 0.05 *** 0.01) /// 
    prehead("") posthead("") prefoot("") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "\end{tabular}")