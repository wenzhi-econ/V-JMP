/* 
This do file overlays coefficient plots for the baseline age-based HF measure and the manager fixed effects-based measure.

RA: WWZ 
Time: 2025-08-12
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. outcome: SGRawC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. prepare the dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/SJFE30_Outcome2_SGRawC_HFMeasureSJFE30.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
rename ///
    (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) ///
    (quarter_SJFE30_gains  coeff_SJFE30_gains  lb_SJFE30_gains  ub_SJFE30_gains)
drop if quarter==.
keep  quarter quarter_SJFE30_gains coeff_SJFE30_gains lb_SJFE30_gains ub_SJFE30_gains
order quarter quarter_SJFE30_gains coeff_SJFE30_gains lb_SJFE30_gains ub_SJFE30_gains
save "${Round1Results}/SJFE30_Outcome2_SGRawC_HFMeasureSJFE30_ForMerge.dta", replace

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
rename ///
    (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) ///
    (quarter_CA30_gains   coeff_CA30_gains   lb_CA30_gains   ub_CA30_gains)
drop if quarter==.
keep  quarter quarter_CA30_gains coeff_CA30_gains lb_CA30_gains ub_CA30_gains
order quarter quarter_CA30_gains coeff_CA30_gains lb_CA30_gains ub_CA30_gains
save "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the datasets and plot the overlaying results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/SJFE30_Outcome2_SGRawC_HFMeasureSJFE30_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", nogenerate

replace quarter_CA30_gains  = quarter_CA30_gains - 0.1
replace quarter_SJFE30_gains = quarter_SJFE30_gains + 0.1

twoway ///
    (scatter coeff_CA30_gains quarter_CA30_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_CA30_gains ub_CA30_gains quarter_CA30_gains, lcolor(ebblue)) ///
    (scatter coeff_SJFE30_gains quarter_SJFE30_gains, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SJFE30_gains ub_SJFE30_gains quarter_SJFE30_gains, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Original age-based high-flyer measure") label(4 "Manager FE based high-flyer measure (FE estimated against salary grade increases)") order(2 4) position(6) ring(0) size(small) rows(2))
graph export "${Round1Results}/CA30SJFE30_Outcome2_SGRawC_Coef1_Gains.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. outcome: SJVertSGC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. prepare the dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/SJFE30_Outcome1_SJVertSGC_HFMeasureSJFE30.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
rename ///
    (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) ///
    (quarter_SJFE30_gains  coeff_SJFE30_gains  lb_SJFE30_gains  ub_SJFE30_gains)
drop if quarter==.
keep  quarter quarter_SJFE30_gains coeff_SJFE30_gains lb_SJFE30_gains ub_SJFE30_gains
order quarter quarter_SJFE30_gains coeff_SJFE30_gains lb_SJFE30_gains ub_SJFE30_gains
save "${Round1Results}/SJFE30_Outcome1_SJVertSGC_HFMeasureSJFE30_ForMerge.dta", replace

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
rename ///
    (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) ///
    (quarter_CA30_gains   coeff_CA30_gains   lb_CA30_gains   ub_CA30_gains)
drop if quarter==.
keep  quarter quarter_CA30_gains coeff_CA30_gains lb_CA30_gains ub_CA30_gains
order quarter quarter_CA30_gains coeff_CA30_gains lb_CA30_gains ub_CA30_gains
save "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. merge the datasets and plot the overlaying results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/SJFE30_Outcome1_SJVertSGC_HFMeasureSJFE30_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", nogenerate

replace quarter_CA30_gains  = quarter_CA30_gains - 0.1
replace quarter_SJFE30_gains = quarter_SJFE30_gains + 0.1

twoway ///
    (scatter coeff_CA30_gains quarter_CA30_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_CA30_gains ub_CA30_gains quarter_CA30_gains, lcolor(ebblue)) ///
    (scatter coeff_SJFE30_gains quarter_SJFE30_gains, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SJFE30_gains ub_SJFE30_gains quarter_SJFE30_gains, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Original age-based high-flyer measure") label(4 "Manager FE based high-flyer measure (FE estimated against salary grade increases)") order(2 4) position(6) ring(0) size(small) rows(2))
graph export "${Round1Results}/CA30SJFE30_Outcome1_SJVertSGC_Coef1_Gains.pdf", replace as(pdf)