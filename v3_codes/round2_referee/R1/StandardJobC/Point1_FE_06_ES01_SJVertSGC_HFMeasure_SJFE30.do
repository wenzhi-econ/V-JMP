/* 
This do file runs event study regressions on outcome: SJVertSGC (count of standard job changes).
The high-flyer measure used here is SJFE30.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Some key results (quarterly aggregated coefficients with their p-values, and other key summary statistics) are stored in the output file. 

Input: 
    "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes.dta"   <== created in Point1_FE_03 do file

Output:
    "${Round1Results}/SJFE30_Outcome1_SJVertSGC_HFMeasureSJCFE?.txt"
    "${Round1Results}/SJFE30_Outcome1_SJVertSGC_HFMeasureSJCFE?.dta"
    "${Round1Results}/SJCFE30_Outcome1_SJVertSGC_Coef1_Gains.gph"

RA: WWZ 
Time: 2025-10-31
*/

forvalues i = 10(5)50 { 
    capture log close
    log using "${Round1Results}/SJFE`i'_Outcome1_SJVertSGC_HFMeasureSJCFE`i'.txt", replace text

    use "${TempData}/R1_Point1_FE_FinalAnalysisSample_MngrFEBasedOnTwoMainOutcomes.dta", clear

    keep if SJFE`i'_LtoL!=.
        //impt: keep only those event workers whose event groups can be identified using manager fixed effects

    /* keep if inrange(_n, 1, 10000)  */
        // used to test the codes
        // commented out when officially producing the results

    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
    *?? step 0. construct variables and macros used in reghdfe command
    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

    GenerateEventDummies, event_prefix(SJFE`i') max_pre_period(24) lto_max_post(84) hto_max_post(60)
        //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
        //&? It also stores all regressors in a global macro ${four_events_dummies}.

    display "${four_events_dummies}"
        // SJFE30_LtoL_X_Pre_Before24 SJFE30_LtoL_X_Pre24 ... SJFE30_LtoL_X_Pre4 SJFE30_LtoL_X_Post0 SJFE30_LtoL_X_Post1 ... SJFE30_LtoL_X_Post84 SJFE30_LtoL_X_Pre_After84 
        // SJFE30_LtoH_X_Pre_Before24 SJFE30_LtoH_X_Pre24 ... SJFE30_LtoH_X_Pre4 SJFE30_LtoH_X_Post0 SJFE30_LtoH_X_Post1 ... SJFE30_LtoH_X_Post84 SJFE30_LtoH_X_Pre_After84 
        // SJFE30_HtoH_X_Pre_Before24 SJFE30_HtoH_X_Pre24 ... SJFE30_HtoH_X_Pre4 SJFE30_HtoH_X_Post0 SJFE30_HtoH_X_Post1 ... SJFE30_HtoH_X_Post60 SJFE30_HtoH_X_Pre_After60 
        // SJFE30_HtoL_X_Pre_Before24 SJFE30_HtoL_X_Pre24 ... SJFE30_HtoL_X_Pre4 SJFE30_HtoL_X_Post0 SJFE30_HtoL_X_Post1 ... SJFE30_HtoL_X_Post60 SJFE30_HtoL_X_Pre_After60 

    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
    *?? step 1. event studies on the two main outcomes
    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

    generate SJVertSG = TransferSJ
    replace  SJVertSG = 0 if ChangeSalaryGrade==0
    sort IDlse YearMonth
    bysort IDlse: generate SJVertSGC = sum(SJVertSG)

    foreach var in SJVertSGC {

        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
        *-? step 1. main regression
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

        reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
        
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
        *-? step 2. LtoH versus LtoL
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

        *!! pre-event joint p-value
        pretrend_LH_minus_LL, event_prefix(SJFE`i') pre_window_len(24)
            global PTGain_`var' = r(pretrend)
            global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
            generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
                //&? store the results

        *!! quarterly estimates
        LH_minus_LL, event_prefix(SJFE`i') pre_window_len(24) post_window_len(84) outcome(`var') statistics(0)
        twoway ///
            (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
            (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
            , legend(off) ///
            xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
            xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
            ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
            xtitle("Quarters since manager change", size(medlarge)) ///
            note("Pre-trends joint p-value = ${PTGain_`var'}")
        graph save "${Round1Results}/SJCFE`i'_Outcome1_`var'_Coef1_Gains.gph", replace
        
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
        *-? step 3. HtoL versus HtoH
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

        *!! pre-event joint p-value
        pretrend_HL_minus_HH, event_prefix(SJFE`i') pre_window_len(24)
            global PTLoss_`var' = r(pretrend)
            global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
            generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
                //&? store the results

        *!! quarterly estimates
        HL_minus_HH, event_prefix(SJFE`i') pre_window_len(24) post_window_len(60) outcome(`var') statistics(0)

        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
        *-? step 4. Testing for asymmetries
        *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

        *!! pre-event joint p-value
        pretrend_Double_Diff, event_prefix(SJFE`i') pre_window_len(24)
            global PTDiff_`var' = r(pretrend)
            global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
            generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
                //&? store the results

        *!! post-event joint p-value
        postevent_Double_Diff, event_prefix(SJFE`i') post_window_len(60)
            global postevent_`var' = r(postevent)
            global postevent_`var' = string(${postevent_`var'}, "%4.3f")
            generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
                //&? store the results

        *!! quarterly estimates
        Double_Diff, event_prefix(SJFE`i') pre_window_len(24) post_window_len(60) outcome(`var')
    }

    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
    *?? step 2. store the event studies results
    *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

    keep PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_*

    keep if inrange(_n, 1, 41)

    save "${Round1Results}/SJFE`i'_Outcome1_SJVertSGC_HFMeasureSJCFE`i'.dta", replace 

    log close
}