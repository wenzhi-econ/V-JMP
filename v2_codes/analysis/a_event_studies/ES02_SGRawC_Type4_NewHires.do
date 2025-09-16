/* 
This do file runs event study regressions on outcome: SGRawC (count of salary grade increases).
The high-flyer measure used here is CA30.

Notes on the event study regression:
    (1) Workers in the regression sample include all four event groups. 
    (2) Never-treated employees are not included in the regressions.
    (3) The omitted group in the regression is month -3, -2, and -1 for all four treatment groups.
    (4) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60]. There are also binned relative time indicators at both ends.

Special notes:
    (1) Only new hires (those whose minimum tenure observed in the dataset is strictly less than 2) are included in the regression.

Input: 
    "${TempData}/FinalAnalysisSample.dta"   <== created in 0103_03 do file

Output:
    "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires.txt"
    "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires.dta"
    "${EventStudyResults}/CA30_Outcome2_SGRawC_Coef1_Gains_Type4_NewHires.gph"

RA: WWZ 
Time: 2025-07-16
*/

capture log close
log using "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

GenerateEventDummies, event_prefix(CA30) max_pre_period(24) lto_max_post(84) hto_max_post(60)
    //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
    //&? It also stores all regressors in a global macro ${four_events_dummies}.

display "${four_events_dummies}"
    // CA30_LtoL_X_Pre_Before24 CA30_LtoL_X_Pre24 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Pre_Before24 CA30_LtoH_X_Pre24 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 
    // CA30_HtoH_X_Pre_Before24 CA30_HtoH_X_Pre24 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before24 CA30_HtoL_X_Pre24 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

sort IDlse YearMonth
bysort IDlse: egen TenureMin = min(Tenure)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. event studies on the two main outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

rename ChangeSalaryGradeC SGRawC

foreach var in SGRawC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-1. main regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if TenureMin<2, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(CA30) pre_window_len(24)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , legend(off) ///
        xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
        xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
        xtitle("Quarters since manager change", size(medlarge)) ///
        ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
        note("Pre-trends joint p-value = ${PTGain_`var'}")
    graph save "${EventStudyResults}/CA30_Outcome2_`var'_Coef1_Gains_Type4_NewHires.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(CA30) pre_window_len(24)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(CA30) pre_window_len(24) post_window_len(60) outcome(`var')

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-4. test for asymmetries
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
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. store the event studies results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep ///
    PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* ///
    LtoL_* LtoH_* HtoH_* HtoL_* ///
    coef1_* coefp1_* coef2_* coefp2_* coef3_* coefp3_* coef4_* coefp4_* coef5_* coefp5_* coef6_* coefp6_* ///
    RI1_* rip1_* RI2_* rip2_* RI3_* rip3_*

keep if inrange(_n, 1, 41)

save "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires.dta", replace 

log close

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. visualize the results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. prepare the datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
rename (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) (quarter_SGRawC_CA30 coeff_SGRawC_CA30 lb_SGRawC_CA30 ub_SGRawC_CA30)
save "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", replace 

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
rename (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) (quarter_SGRawC_New coeff_SGRawC_New lb_SGRawC_New ub_SGRawC_New)
save "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires_ForMerge.dta", replace 

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", clear 
merge 1:1 quarter using "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires_ForMerge.dta", nogenerate 

replace quarter_SGRawC_CA30 = quarter_SGRawC_CA30 - 0.2
replace quarter_SGRawC_New  = quarter_SGRawC_New + 0.2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. contrast full-sample results against new hires results
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter coeff_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SGRawC_CA30 ub_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue)) ///
    (scatter coeff_SGRawC_New quarter_SGRawC_New, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SGRawC_New ub_SGRawC_New quarter_SGRawC_New, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Full event study sample") label(4 "New hires sample") order(2 4) position(6) ring(0) size(small))
graph save "${EventStudyResults}/CA30_Outcome2_SGRawC_Coef1_Gains_Type4_NewHires.gph", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. erase auxiliary datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

if ${if_erase_temp_file}==1 {
    erase "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta"
    erase "${EventStudyResults}/CA30_Outcome2_SGRawC_Type4_NewHires_ForMerge.dta"
}