/* 
This do file runs event study by spliting the sample by high- and low-performers (based on salary growth).

RA: WWZ
Time: 2025-07-17
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. split the analysis sample 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

keep Year - CA30_HtoL TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC LogPayBonus LogPay LogBonus ONETDistC

merge 1:1 IDlse YearMonth using "${TempData}/FinalFullSample.dta", keepusing(VPA) keep(match) nogenerate

sort IDlse YearMonth
bysort IDlse: egen VPA1 = mean(cond(inrange(Rel_Time, -24, -1), VPA , .))
summarize VPA1, detail
/* 
                            VPA1
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%           40              0
10%     57.14286              0       Obs             344,609
25%           95              0       Sum of wgt.     344,609

50%          100                      Mean            94.8363
                        Largest       Std. dev.      26.71273
75%          105            150
90%     123.3333            150       Variance       713.5699
95%          125            150       Skewness      -2.015268
99%       131.25            150       Kurtosis       7.609397
*/
generate HighPerf_VPA = (VPA1 > r(p50)) if VPA1!=.

keep if HighPerf_VPA!=.
    //impt: keep only observations with identifiable pre-event VPA

codebook IDlse if HighPerf_VPA==1 // 2,233
codebook IDlse if HighPerf_VPA==0 // 5,195

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

foreach var in ONETDistC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-1. main regression for high-performers
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if HighPerf_VPA==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(48) outcome(`var') statistics(0)
    rename (quarter_`var'_gains coeff_`var'_gains lb_`var'_gains ub_`var'_gains) (quarter_`var'_High coeff_`var'_High lb_`var'_High ub_`var'_High)

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-1-2. main regression for low-performers
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if HighPerf_VPA==0, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 

    *!! quarterly estimates
    LH_minus_LL, event_prefix(CA30) pre_window_len(24) post_window_len(48) outcome(`var') statistics(0)
    rename (quarter_`var'_gains coeff_`var'_gains lb_`var'_gains ub_`var'_gains) (quarter_`var'_Low coeff_`var'_Low lb_`var'_Low ub_`var'_Low)
}

keep quarter_ONETDistC_High - ub_ONETDistC_Low

save "${Round1Results}/CA30_ONETDistC_VPAAsBaselinePerf_GreaterThan100_Post48.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. draw plots
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Round1Results}/CA30_ONETDistC_VPAAsBaselinePerf_GreaterThan100_Post48.dta", clear
replace quarter_ONETDistC_High = quarter_ONETDistC_High - 0.2
replace quarter_ONETDistC_Low  = quarter_ONETDistC_Low  + 0.2

twoway ///
    (scatter coeff_ONETDistC_High quarter_ONETDistC_High, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_ONETDistC_High ub_ONETDistC_High quarter_ONETDistC_High, lcolor(ebblue)) ///
    (scatter coeff_ONETDistC_Low quarter_ONETDistC_Low, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_ONETDistC_Low ub_ONETDistC_Low quarter_ONETDistC_Low, lcolor("237 68 74")) ///
    , ///
    xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
    xlabel(-8(2)16, grid gstyle(dot) labsize(medsmall)) /// 
    xtitle("Quarters since manager change", size(medlarge)) ///
    ylabel(-0.1(0.02)0.1, grid gstyle(dot) labsize(medsmall)) ///
    legend(label(2 "Top 50% performance at baseline (perf. score)") label(4 "Bottom 50% performance at baseline (perf. score)") order(2 4) rows(2) ring(0) position(6))
graph export "${Round1Results}/CA30_Outcome9_ONETDistC_Coef1_Gains_VPAAsBaselinePerf_GreaterThan100_Post48.pdf", replace as(pdf)