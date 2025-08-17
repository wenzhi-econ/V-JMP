/* 
This do file runs event study by spliting the sample by high- and low-performers (based on salary growth).

RA: WWZ
Time: 2025-07-17
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. split the analysis sample 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

keep Year - CA30_HtoL TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC LogPayBonus LogPay LogBonus

xtset IDlse YearMonth 
generate PayGrowth = d.LogPayBonus 

sort IDlse YearMonth
bysort IDlse: egen PayGrowth1 = mean(cond(inrange(Rel_Time, -24, -1), PayGrowth , .))
summarize PayGrowth1, detail
generate HighPerf_Pay = (PayGrowth1 >= r(p50)) if PayGrowth1!=.

keep if HighPerf_Pay!=.
    //impt: keep only observations with identifiable pre-event salary growth

codebook IDlse if HighPerf_Pay==1 // 3,522
codebook IDlse if HighPerf_Pay==0 // 4,849

codebook Event_Time // [2016m2, 2021m12] 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run event study 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. regressors in the main regression 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

GenerateEventDummies, event_prefix(CA30) max_pre_period(24) lto_max_post(48) hto_max_post(48)
    //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
    //&? It also stores all regressors in a global macro ${four_events_dummies}.

display "${four_events_dummies}"
    // CA30_LtoL_X_Pre_Before24 CA30_LtoL_X_Pre24 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post48 CA30_LtoL_X_Pre_After48 
    // CA30_LtoH_X_Pre_Before24 CA30_LtoH_X_Pre24 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post48 CA30_LtoH_X_Pre_After48 
    // CA30_HtoH_X_Pre_Before24 CA30_HtoH_X_Pre24 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post48 CA30_HtoH_X_Pre_After48 
    // CA30_HtoL_X_Pre_Before24 CA30_HtoL_X_Pre24 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post48 CA30_HtoL_X_Pre_After48 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. regressors in the main regression 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate SJVertSG = TransferSJ
replace  SJVertSG = 0 if ChangeSalaryGrade==0
sort IDlse YearMonth
bysort IDlse: generate SJVertSGC = sum(SJVertSG)

rename ChangeSalaryGradeC SGRawC

foreach var in SJVertSGC SGRawC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-1. main regression for high-performers
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if HighPerf_Pay==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(48) outcome(`var') statistics(0)
    rename (quarter_`var'_gains coeff_`var'_gains lb_`var'_gains ub_`var'_gains) (quarter_`var'_High coeff_`var'_High lb_`var'_High ub_`var'_High)

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-2. main regression for low-performers
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if HighPerf_Pay==0, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(48) outcome(`var') statistics(0)
    rename (quarter_`var'_gains coeff_`var'_gains lb_`var'_gains ub_`var'_gains) (quarter_`var'_Low coeff_`var'_Low lb_`var'_Low ub_`var'_Low)
}

keep quarter_SJVertSGC_High - ub_SGRawC_Low

save "${Round1Results}/CA30_TwoMainOutcomes_PayAsBaselinePerf_Post48.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. draw plots
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Round1Results}/CA30_TwoMainOutcomes_PayAsBaselinePerf_Post48.dta", clear
replace quarter_SJVertSGC_High = quarter_SJVertSGC_High - 0.2
replace quarter_SJVertSGC_Low  = quarter_SJVertSGC_Low  + 0.2
replace quarter_SGRawC_High    = quarter_SGRawC_High    - 0.2
replace quarter_SGRawC_Low     = quarter_SGRawC_Low     + 0.2

twoway ///
    (scatter coeff_SJVertSGC_High quarter_SJVertSGC_High, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SJVertSGC_High ub_SJVertSGC_High quarter_SJVertSGC_High, lcolor(ebblue)) ///
    (scatter coeff_SJVertSGC_Low quarter_SJVertSGC_Low, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SJVertSGC_Low ub_SJVertSGC_Low quarter_SJVertSGC_Low, lcolor("237 68 74")) ///
    , ///
    xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
    xlabel(-8(2)16, grid gstyle(dot) labsize(medsmall)) /// 
    xtitle("Quarters since manager change", size(medlarge)) ///
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    legend(label(2 "Top 50% performance at baseline (salary growth)") label(4 "Bottom 50% performance at baseline (salary growth)") order(2 4) rows(2) ring(0) position(6))
graph export "${Round1Results}/CA30_Outcome1_SJVertSGC_Coef1_Gains_PayAsBaselinePerf_Post48.pdf", replace as(pdf)

twoway ///
    (scatter coeff_SGRawC_High quarter_SGRawC_High, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SGRawC_High ub_SGRawC_High quarter_SGRawC_High, lcolor(ebblue)) ///
    (scatter coeff_SGRawC_Low quarter_SGRawC_Low, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SGRawC_Low ub_SGRawC_Low quarter_SGRawC_Low, lcolor("237 68 74")) ///
    , ///
    xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
    xlabel(-8(2)16, grid gstyle(dot) labsize(medsmall)) /// 
    xtitle("Quarters since manager change", size(medlarge)) ///
    ylabel(-0.3(0.05)0.5, grid gstyle(dot) labsize(medsmall)) ///
    legend(label(2 "Top 50% performance at baseline (salary growth)") label(4 "Bottom 50% performance at baseline (salary growth)") order(2 4) rows(2) ring(0) position(6))
graph export "${Round1Results}/CA30_Outcome2_SGRawC_Coef1_Gains_PayAsBaselinePerf_Post48.pdf", replace as(pdf)
