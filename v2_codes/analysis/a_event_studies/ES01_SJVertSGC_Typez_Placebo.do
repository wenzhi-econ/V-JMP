/* 
This do file runs event study regressions on outcome: SJVertSGC (count of standard job changes with simultaneous salary grade increases).
The high-flyer measure used here is Odd (hypothetical high-flyer measure).

Notes on the event study regression:
    (1) Workers in the regression sample include all four event groups. 
    (2) Never-treated employees are not included in the regressions.
    (3) The omitted group in the regression is month -3, -2, and -1 for all four treatment groups.

Input: 
    "${TempData}/FinalAnalysisSample.dta"   <== created in 0103_03 do file

Output:
    "${EventStudyResults}/Odd_Outcome1_SJVertSGC.txt"
    "${EventStudyResults}/Odd_Outcome1_SJVertSGC.dta"
    "${EventStudyResults}/Odd_Outcome1_SJVertSGC_Coef1_Gains.gph"
    "${EventStudyResults}/Odd_Outcome1_SJVertSGC_Coef2_Loss.gph"

RA: WWZ 
Time: 2025-08-07
*/

capture log close 
log using "${EventStudyResults}/Odd_Outcome1_SJVertSGC.txt", replace text

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct the placebo event groups
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. do pre- and post-event managers have an odd id
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate odd = mod(IDlseMHR, 2) 
order    odd, after(IDlseMHR)

sort IDlse YearMonth
bysort IDlse: egen MngrOdd_Pre  = mean(cond(Rel_Time==-1, odd, .))
bysort IDlse: egen MngrOdd_Post = mean(cond(Rel_Time==0 , odd, .))
order MngrOdd_Pre MngrOdd_Post, after(odd)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. reassign workers into different event groups
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop FT_LtoL
capture drop FT_LtoH
capture drop FT_HtoH
capture drop FT_HtoL

generate FT_LtoL = .
replace  FT_LtoL = 1 if MngrOdd_Pre==0 & MngrOdd_Post==0
replace  FT_LtoL = 0 if FT_LtoL==.

generate FT_LtoH = .
replace  FT_LtoH = 1 if MngrOdd_Pre==0 & MngrOdd_Post==1
replace  FT_LtoH = 0 if FT_LtoH==.

generate FT_HtoH = .
replace  FT_HtoH = 1 if MngrOdd_Pre==1 & MngrOdd_Post==1
replace  FT_HtoH = 0 if FT_HtoH==.

generate FT_HtoL = .
replace  FT_HtoL = 1 if MngrOdd_Pre==1 & MngrOdd_Post==0
replace  FT_HtoL = 0 if FT_HtoL==.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

GenerateEventDummies, event_prefix(FT) max_pre_period(24) lto_max_post(60) hto_max_post(60)
    //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
    //&? It also stores all regressors in a global macro ${four_events_dummies}.

display "${four_events_dummies}"
    // FT_LtoL_X_Pre_Before24 FT_LtoL_X_Pre24 ... FT_LtoL_X_Pre4 FT_LtoL_X_Post0 FT_LtoL_X_Post1 ... FT_LtoL_X_Post60 FT_LtoL_X_Pre_After60 
    // FT_LtoH_X_Pre_Before24 FT_LtoH_X_Pre24 ... FT_LtoH_X_Pre4 FT_LtoH_X_Post0 FT_LtoH_X_Post1 ... FT_LtoH_X_Post60 FT_LtoH_X_Pre_After60 
    // FT_HtoH_X_Pre_Before24 FT_HtoH_X_Pre24 ... FT_HtoH_X_Pre4 FT_HtoH_X_Post0 FT_HtoH_X_Post1 ... FT_HtoH_X_Post60 FT_HtoH_X_Pre_After60 
    // FT_HtoL_X_Pre_Before24 FT_HtoL_X_Pre24 ... FT_HtoL_X_Pre4 FT_HtoL_X_Post0 FT_HtoL_X_Post1 ... FT_HtoL_X_Post60 FT_HtoL_X_Pre_After60 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event studies on the two main outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate SJVertSG = TransferSJ
replace  SJVertSG = 0 if ChangeSalaryGrade==0
sort IDlse YearMonth
bysort IDlse: generate SJVertSGC = sum(SJVertSG)

foreach var in SJVertSGC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-1. main regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-2. LtoH versus LtoL (even_to_odd versus even_to_even)
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL, event_prefix(FT) pre_window_len(24)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    LH_minus_LL, event_prefix(FT) pre_window_len(24) post_window_len(60) outcome(`var') statistics(0)
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , legend(off) ///
        xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        xtitle("Quarters since manager change", size(medlarge)) ///
        ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
        note("Pre-trends joint p-value = ${PTGain_`var'}")
    graph save "${EventStudyResults}/Odd_Outcome1_`var'_Coef1_Gains.gph", replace

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_HL_minus_HH, event_prefix(FT) pre_window_len(24)
        global PTLoss_`var' = r(pretrend)
        global PTLoss_`var' = string(${PTLoss_`var'}, "%4.3f")
        generate PTLoss_`var' = ${PTLoss_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    HL_minus_HH, event_prefix(FT) pre_window_len(24) post_window_len(60) outcome(`var') statistics(0)
    twoway ///
        (scatter coeff_`var'_loss quarter_`var'_loss, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_loss ub_`var'_loss quarter_`var'_loss, lcolor(ebblue)) ///
        , legend(off) ///
        xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
        xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
        xtitle(Quarters since manager change, size(medlarge)) ///
        ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
        note("Pre-trends joint p-value = ${PTLoss_`var'}")
    graph save "${EventStudyResults}/Odd_Outcome1_`var'_Coef2_Loss.gph", replace   

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-4. test for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_Double_Diff, event_prefix(FT) pre_window_len(24)
        global PTDiff_`var' = r(pretrend)
        global PTDiff_`var' = string(${PTDiff_`var'}, "%4.3f")
        generate PTDiff_`var' = ${PTDiff_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! post-event joint p-value
    postevent_Double_Diff, event_prefix(FT) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! quarterly estimates
    Double_Diff, event_prefix(FT) pre_window_len(24) post_window_len(60) outcome(`var')
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. store the event studies results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep PTGain_* coeff_* quarter_* lb_* ub_* PTLoss_* PTDiff_* postevent_* 
keep if inrange(_n, 1, 41)
save "${EventStudyResults}/Odd_Outcome1_SJVertSGC.dta", replace 

capture log close
