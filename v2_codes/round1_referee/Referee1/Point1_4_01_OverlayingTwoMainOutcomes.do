/* 
This do file overlays the event study coefficients on the two main outcomes.

RA: WWZ 
Time: 2025-08-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. process the datasets containing coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta", clear
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
drop if quarter==.
save "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", replace

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta", clear
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
drop if quarter==.
save "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", replace

use "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", nogenerate

replace quarter_SGRawC_gains    = quarter_SGRawC_gains + 0.15
replace quarter_SJVertSGC_gains = quarter_SJVertSGC_gains - 0.15

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. plotting
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

twoway ///
    (scatter coeff_SJVertSGC_gains quarter_SJVertSGC_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SJVertSGC_gains ub_SJVertSGC_gains quarter_SJVertSGC_gains, lcolor(ebblue)) ///
    (scatter coeff_SGRawC_gains quarter_SGRawC_gains, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SGRawC_gains ub_SGRawC_gains quarter_SGRawC_gains, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Lateral moves") label(4 "Salary grade increases") order(2 4) position(6) ring(0))
graph export "${Round1Results}/CA30_Outcome1And2_Coef1_Gains_Overlaying.pdf", replace as(pdf)