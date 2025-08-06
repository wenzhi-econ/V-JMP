/* 
This do file runs event study regressions on outcome: SGRawC (count of salary grade increases).
The high-flyer measures used here are CA28 CA32 DA30.

Notes on the event study regression:
    (1) Workers in the regression sample include all four event groups.
    (2) Never-treated employees are not included in the regressions.
    (3) The omitted group in the regression is month -3, -2, and -1 for all four treatment groups.
    (4) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60]. There are also binned relative time indicators at both ends.

Input: 
    "${TempData}/FinalAnalysisSample.dta"                             <== created in 0103_03 do file
    "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta"    <== obtained in ES02_Type1 do file

Output:
    "${EventStudyResults}/CA28_Outcome2_SGRawC.txt"
    "${EventStudyResults}/CA28_Outcome2_SGRawC.dta"    
    "${EventStudyResults}/CA32_Outcome2_SGRawC.txt"
    "${EventStudyResults}/CA32_Outcome2_SGRawC.dta"
    "${EventStudyResults}/DA30_Outcome2_SGRawC.txt"
    "${EventStudyResults}/DA30_Outcome2_SGRawC.dta"
    "${EventStudyResults}/CA30CA28_Outcome2_SGRawC_Coef1_Gains.gph"
    "${EventStudyResults}/CA30CA32_Outcome2_SGRawC_Coef1_Gains.gph"
    "${EventStudyResults}/CA30DA30_Outcome2_SGRawC_Coef1_Gains.gph"

RA: WWZ 
Time: 2025-08-05
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain quarterly coefficients under three HF measures
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach HFMeasure in CA28 CA32 DA30 {
    //impt: iterate three alternative age-based high-flyer measures

    capture log close
    log using "${EventStudyResults}/`HFMeasure'_Outcome2_SGRawC.txt", replace text

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-1. construct variables and macros used in reghdfe command
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    use "${TempData}/FinalAnalysisSample.dta", clear

    GenerateEventDummies, event_prefix(`HFMeasure') max_pre_period(24) lto_max_post(84) hto_max_post(60)
        //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
        //&? It also stores all regressors in a global macro ${four_events_dummies}.

    display "${four_events_dummies}"
        // `HFMeasure'_LtoL_X_Pre_Before24 `HFMeasure'_LtoL_X_Pre24 ... `HFMeasure'_LtoL_X_Pre4 `HFMeasure'_LtoL_X_Post0 `HFMeasure'_LtoL_X_Post1 ... `HFMeasure'_LtoL_X_Post84 `HFMeasure'_LtoL_X_Pre_After84 
        // `HFMeasure'_LtoH_X_Pre_Before24 `HFMeasure'_LtoH_X_Pre24 ... `HFMeasure'_LtoH_X_Pre4 `HFMeasure'_LtoH_X_Post0 `HFMeasure'_LtoH_X_Post1 ... `HFMeasure'_LtoH_X_Post84 `HFMeasure'_LtoH_X_Pre_After84 
        // `HFMeasure'_HtoH_X_Pre_Before24 `HFMeasure'_HtoH_X_Pre24 ... `HFMeasure'_HtoH_X_Pre4 `HFMeasure'_HtoH_X_Post0 `HFMeasure'_HtoH_X_Post1 ... `HFMeasure'_HtoH_X_Post60 `HFMeasure'_HtoH_X_Pre_After60 
        // `HFMeasure'_HtoL_X_Pre_Before24 `HFMeasure'_HtoL_X_Pre24 ... `HFMeasure'_HtoL_X_Pre4 `HFMeasure'_HtoL_X_Post0 `HFMeasure'_HtoL_X_Post1 ... `HFMeasure'_HtoL_X_Post60 `HFMeasure'_HtoL_X_Pre_After60 

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-2. run regressions and obtain relevant coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    rename ChangeSalaryGradeC SGRawC

    foreach var in SGRawC {

        *!! s-1-2-1. main regression
        reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

        *!! s-1-2-2. LtoH versus LtoL
        *&? pre-event joint p-value
        pretrend_LH_minus_LL, event_prefix(`HFMeasure') pre_window_len(24)
            global PTGain_`var' = r(pretrend)
            global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
            generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
        *&? quarterly estimates
        LH_minus_LL, event_prefix(`HFMeasure') pre_window_len(24) post_window_len(84) outcome(`var') statistics(0)

        *!! s-1-2-3. HtoL versus HtoH
        *&? pre-event joint p-value
        pretrend_HL_minus_HH, event_prefix(`HFMeasure') pre_window_len(24)
            global PTLoss_`var' = r(pretrend)
            global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
            generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
        *&? quarterly estimates
        HL_minus_HH, event_prefix(`HFMeasure') pre_window_len(24) post_window_len(60) outcome(`var') statistics(0)

        *!! s-1-2-4. test for asymmetries
        *&? pre-event joint p-value
        pretrend_Double_Diff, event_prefix(`HFMeasure') pre_window_len(24)
            global PTDiff_`var' = r(pretrend)
            global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
            generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
        *&? post-event joint p-value
        postevent_Double_Diff, event_prefix(`HFMeasure') post_window_len(60)
            global postevent_`var' = r(postevent)
            global postevent_`var' = string(${postevent_`var'}, "%4.3f")
            generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
        *&? quarterly estimates
        Double_Diff, event_prefix(`HFMeasure') pre_window_len(24) post_window_len(60) outcome(`var')
    }

    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
    *?? step 3. store the event studies results
    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

    keep PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_*
    keep if inrange(_n, 1, 41)
    save "${EventStudyResults}/`HFMeasure'_Outcome2_SGRawC.dta", replace 

    log close

}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. visualize the results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. prepare the datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
rename (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) (quarter_SGRawC_CA30 coeff_SGRawC_CA30 lb_SGRawC_CA30 ub_SGRawC_CA30)
save "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", replace 

use "${EventStudyResults}/CA28_Outcome2_SGRawC.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
rename (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) (quarter_SGRawC_CA28 coeff_SGRawC_CA28 lb_SGRawC_CA28 ub_SGRawC_CA28)
save "${EventStudyResults}/CA28_Outcome2_SGRawC_ForMerge.dta", replace 

use "${EventStudyResults}/CA32_Outcome2_SGRawC.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
rename (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) (quarter_SGRawC_CA32 coeff_SGRawC_CA32 lb_SGRawC_CA32 ub_SGRawC_CA32)
save "${EventStudyResults}/CA32_Outcome2_SGRawC_ForMerge.dta", replace

use "${EventStudyResults}/DA30_Outcome2_SGRawC.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
rename (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) (quarter_SGRawC_DA30 coeff_SGRawC_DA30 lb_SGRawC_DA30 ub_SGRawC_DA30)
save "${EventStudyResults}/DA30_Outcome2_SGRawC_ForMerge.dta", replace 

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", clear 
merge 1:1 quarter using "${EventStudyResults}/CA28_Outcome2_SGRawC_ForMerge.dta", nogenerate 
merge 1:1 quarter using "${EventStudyResults}/CA32_Outcome2_SGRawC_ForMerge.dta", nogenerate 
merge 1:1 quarter using "${EventStudyResults}/DA30_Outcome2_SGRawC_ForMerge.dta", nogenerate 

replace quarter_SGRawC_CA30 = quarter_SGRawC_CA30 - 0.2
replace quarter_SGRawC_CA28 = quarter_SGRawC_CA28 + 0.2
replace quarter_SGRawC_CA32 = quarter_SGRawC_CA32 + 0.2
replace quarter_SGRawC_DA30 = quarter_SGRawC_DA30 + 0.2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. contrast CA30 against alternative age-based HF measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter coeff_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SGRawC_CA30 ub_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue)) ///
    (scatter coeff_SGRawC_CA28 quarter_SGRawC_CA28, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_SGRawC_CA28 ub_SGRawC_CA28 quarter_SGRawC_CA28, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Continuous age: 30 as the threshold (baseline)") label(4 "Continuous age: 28 as the threshold") order(2 4) position(6) ring(0) size(small))
graph save "${EventStudyResults}/CA30CA28_Outcome2_SGRawC_Coef1_Gains.gph", replace

twoway ///
    (scatter coeff_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SGRawC_CA30 ub_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue)) ///
    (scatter coeff_SGRawC_CA32 quarter_SGRawC_CA32, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_SGRawC_CA32 ub_SGRawC_CA32 quarter_SGRawC_CA32, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Continuous age: 30 as the threshold (baseline)") label(4 "Continuous age: 32 as the threshold") order(2 4) position(6) ring(0) size(small))
graph save "${EventStudyResults}/CA30CA32_Outcome2_SGRawC_Coef1_Gains.gph", replace

twoway ///
    (scatter coeff_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SGRawC_CA30 ub_SGRawC_CA30 quarter_SGRawC_CA30, lcolor(ebblue)) ///
    (scatter coeff_SGRawC_DA30 quarter_SGRawC_DA30, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_SGRawC_DA30 ub_SGRawC_DA30 quarter_SGRawC_DA30, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Continuous age: 30 as the threshold (baseline)") label(4 "Discrete age: age bracket 18-29 as high-flyers") order(2 4) position(6) ring(0) size(small))
graph save "${EventStudyResults}/CA30DA30_Outcome2_SGRawC_Coef1_Gains.gph", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. erase auxiliary datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

if ${if_erase_temp_file}==1 {
    erase "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta"
    erase "${EventStudyResults}/CA28_Outcome2_SGRawC_ForMerge.dta"
    erase "${EventStudyResults}/CA32_Outcome2_SGRawC_ForMerge.dta"
    erase "${EventStudyResults}/DA30_Outcome2_SGRawC_ForMerge.dta"
}