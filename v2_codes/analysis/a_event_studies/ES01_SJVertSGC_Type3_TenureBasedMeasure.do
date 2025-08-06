/* 
This do file runs event study regressions on outcome: SJVertSGC (count of standard job changes with simultaneous salary grade increases).
The high-flyer measure used here is TB05.

Notes on the event study regression:
    (1) Workers in the regression sample include all four event groups.
    (2) Never-treated employees are not included in the regressions.
    (3) The omitted group in the regression is month -3, -2, and -1 for all four treatment groups.
    (4) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60]. There are also binned relative time indicators at both ends.

Input: 
    "${TempData}/FinalAnalysisSample.dta"                             <== created in 0103_03 do file
    "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta" <== obtained in ES01_Type1 do file

Output:
    "${EventStudyResults}/CA28_Outcome1_SJVertSGC.txt"
    "${EventStudyResults}/CA28_Outcome1_SJVertSGC.dta"    
    "${EventStudyResults}/CA30TB05_Outcome1_SJVertSGC_Coef1_Gains.gph"

RA: WWZ 
Time: 2025-08-05
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. obtain quarterly coefficients under three HF measures
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach HFMeasure in TB05 {
    //impt: the high-flyer manager measure used here is TB05

    capture log close
    log using "${EventStudyResults}/`HFMeasure'_Outcome1_SJVertSGC.txt", replace text

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-1. construct variables and macros used in reghdfe command
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    use "${TempData}/FinalAnalysisSample.dta", clear

    GenerateEventDummies, event_prefix(`HFMeasure') max_pre_period(24) lto_max_post(84) hto_max_post(60)
        //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
        //&? It also stores all regressors in a global macro ${four_events_dummies}.

    display "${four_events_dummies}"
        // TB05_LtoL_X_Pre_Before24 TB05_LtoL_X_Pre24 ... TB05_LtoL_X_Pre4 TB05_LtoL_X_Post0 TB05_LtoL_X_Post1 ... TB05_LtoL_X_Post84 TB05_LtoL_X_Pre_After84 
        // TB05_LtoH_X_Pre_Before24 TB05_LtoH_X_Pre24 ... TB05_LtoH_X_Pre4 TB05_LtoH_X_Post0 TB05_LtoH_X_Post1 ... TB05_LtoH_X_Post84 TB05_LtoH_X_Pre_After84 
        // TB05_HtoH_X_Pre_Before24 TB05_HtoH_X_Pre24 ... TB05_HtoH_X_Pre4 TB05_HtoH_X_Post0 TB05_HtoH_X_Post1 ... TB05_HtoH_X_Post60 TB05_HtoH_X_Pre_After60 
        // TB05_HtoL_X_Pre_Before24 TB05_HtoL_X_Pre24 ... TB05_HtoL_X_Pre4 TB05_HtoL_X_Post0 TB05_HtoL_X_Post1 ... TB05_HtoL_X_Post60 TB05_HtoL_X_Pre_After60 

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-2. run regressions and obtain relevant coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    generate SJVertSG = TransferSJ
    replace  SJVertSG = 0 if ChangeSalaryGrade==0
    sort IDlse YearMonth
    bysort IDlse: generate SJVertSGC = sum(SJVertSG)

    foreach var in SJVertSGC {

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
    save "${EventStudyResults}/`HFMeasure'_Outcome1_SJVertSGC.dta", replace 

    log close

}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. visualize the results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. prepare the datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
drop if quarter==.
rename (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) (quarter_SJVertSGC_CA30 coeff_SJVertSGC_CA30 lb_SJVertSGC_CA30 ub_SJVertSGC_CA30)
save "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", replace 

use "${EventStudyResults}/TB05_Outcome1_SJVertSGC.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
drop if quarter==.
rename (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) (quarter_SJVertSGC_TB05 coeff_SJVertSGC_TB05 lb_SJVertSGC_TB05 ub_SJVertSGC_TB05)
save "${EventStudyResults}/TB05_Outcome1_SJVertSGC_ForMerge.dta", replace 

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", clear 
merge 1:1 quarter using "${EventStudyResults}/TB05_Outcome1_SJVertSGC_ForMerge.dta", nogenerate 

replace quarter_SJVertSGC_CA30 = quarter_SJVertSGC_CA30 - 0.2
replace quarter_SJVertSGC_TB05 = quarter_SJVertSGC_TB05 + 0.2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. contrast CA30 against alternative age-based HF measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter coeff_SJVertSGC_CA30 quarter_SJVertSGC_CA30, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SJVertSGC_CA30 ub_SJVertSGC_CA30 quarter_SJVertSGC_CA30, lcolor(ebblue)) ///
    (scatter coeff_SJVertSGC_TB05 quarter_SJVertSGC_TB05, lcolor(magenta) mcolor(magenta)) ///
    (rcap lb_SJVertSGC_TB05 ub_SJVertSGC_TB05 quarter_SJVertSGC_TB05, lcolor(magenta)) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Continuous age: 30 as the threshold (baseline)") label(4 "Tenure: 5 years as the threshold") order(2 4) position(6) ring(0) size(small))
graph save "${EventStudyResults}/CA30TB05_Outcome1_SJVertSGC_Coef1_Gains.gph", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. erase auxiliary datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

if ${if_erase_temp_file}==1 {
    erase "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta"
    erase "${EventStudyResults}/TB05_Outcome1_SJVertSGC_ForMerge.dta"
}