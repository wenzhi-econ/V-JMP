/* 
This do file visualizes the event study results on two main outcomes with SubFunc##YearMonth FE.

RA: WWZ
Time: 2025-08-14
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. plotting the figures (one panel, one coef)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

/* graph use "${Round1Results}/CA30_Outcome1_SJVertSGC_Coef1_Gains_Type1_Baseline_SubFunc.gph"
graph export "${Round1Results}/CA30_Outcome1_SJVertSGC_Coef1_Gains_Type1_Baseline_SubFunc.pdf", replace

graph use "${Round1Results}/CA30_Outcome1_SJVertSGC_Coef2_Loss_Type1_Baseline_SubFunc.gph"
graph export "${Round1Results}/CA30_Outcome1_SJVertSGC_Coef2_Loss_Type1_Baseline_SubFunc.pdf", replace

graph use "${Round1Results}/CA30_Outcome2_SGRawC_Coef2_Loss_Type1_Baseline_SubFunc.gph"
graph export "${Round1Results}/CA30_Outcome2_SGRawC_Coef2_Loss_Type1_Baseline_SubFunc.pdf", replace

graph use "${Round1Results}/CA30_Outcome2_SGRawC_Coef1_Gains_Type1_Baseline_SubFunc.gph"
graph export "${Round1Results}/CA30_Outcome2_SGRawC_Coef1_Gains_Type1_Baseline_SubFunc.pdf", replace */

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. overlaying the results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. processing the datasets storing the required coefficients
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_SubFunc.dta", clear 
keep ///
    quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains ///
    quarter_SJVertSGC_loss coeff_SJVertSGC_loss lb_SJVertSGC_loss ub_SJVertSGC_loss
rename ///
    (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) ///
    (quarter_gains_SubFunc coeff_gains_SubFunc lb_gains_SubFunc ub_gains_SubFunc)
rename ///
    (quarter_SJVertSGC_loss coeff_SJVertSGC_loss lb_SJVertSGC_loss ub_SJVertSGC_loss) ///
    (quarter_loss_SubFunc coeff_loss_SubFunc lb_loss_SubFunc ub_loss_SubFunc)
generate quarter = quarter_gains_SubFunc
drop if quarter==.
save "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_SubFunc_ForMerge.dta", replace

use "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_SubFunc.dta", clear 
keep ///
    quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains ///
    quarter_SGRawC_loss coeff_SGRawC_loss lb_SGRawC_loss ub_SGRawC_loss
rename ///
    (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) ///
    (quarter_gains_SubFunc coeff_gains_SubFunc lb_gains_SubFunc ub_gains_SubFunc)
rename ///
    (quarter_SGRawC_loss coeff_SGRawC_loss lb_SGRawC_loss ub_SGRawC_loss) ///
    (quarter_loss_SubFunc coeff_loss_SubFunc lb_loss_SubFunc ub_loss_SubFunc)
generate quarter = quarter_gains_SubFunc
drop if quarter==.
save "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_SubFunc_ForMerge.dta", replace

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta", clear 
keep ///
    quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains ///
    quarter_SJVertSGC_loss coeff_SJVertSGC_loss lb_SJVertSGC_loss ub_SJVertSGC_loss
rename ///
    (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) ///
    (quarter_gains coeff_gains lb_gains ub_gains)
rename ///
    (quarter_SJVertSGC_loss coeff_SJVertSGC_loss lb_SJVertSGC_loss ub_SJVertSGC_loss) ///
    (quarter_loss coeff_loss lb_loss ub_loss)
generate quarter = quarter_gains
drop if quarter==.
save "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", replace

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta", clear 
keep ///
    quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains ///
    quarter_SGRawC_loss coeff_SGRawC_loss lb_SGRawC_loss ub_SGRawC_loss
rename ///
    (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) ///
    (quarter_gains coeff_gains lb_gains ub_gains)
rename ///
    (quarter_SGRawC_loss coeff_SGRawC_loss lb_SGRawC_loss ub_SGRawC_loss) ///
    (quarter_loss coeff_loss lb_loss ub_loss)
generate quarter = quarter_gains
drop if quarter==.
save "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. drawing the overlaying coefficients plots
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_SubFunc_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta"

replace quarter_gains         = quarter_gains - 0.2
replace quarter_loss          = quarter_loss - 0.2
replace quarter_gains_SubFunc = quarter_gains_SubFunc + 0.2
replace quarter_loss_SubFunc  = quarter_loss_SubFunc + 0.2

twoway ///
    (scatter coeff_gains quarter_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains ub_gains quarter_gains, lcolor(ebblue)) ///
    (scatter coeff_gains_SubFunc quarter_gains_SubFunc, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_gains_SubFunc ub_gains_SubFunc quarter_gains_SubFunc, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Employee FE + year-month FE") label(4 "Employee FE + year-month * subfunction FE") order(2 4) position(6) ring(0) size(small))
graph export "${Round1Results}/CA30SubFunc_Outcome1_SJVertSGC_Coef1_Gains.pdf", replace as(pdf)

twoway ///
    (scatter coeff_loss quarter_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss ub_loss quarter_loss, lcolor(ebblue)) ///
    (scatter coeff_loss_SubFunc quarter_loss_SubFunc, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_loss_SubFunc ub_loss_SubFunc quarter_loss_SubFunc, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Employee FE + year-month FE") label(4 "Employee FE + year-month * subfunction FE") order(2 4) position(6) ring(0) size(small))
graph export "${Round1Results}/CA30SubFunc_Outcome1_SJVertSGC_Coef2_Loss.pdf", replace as(pdf)


use "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_SubFunc_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta"

replace quarter_gains         = quarter_gains - 0.2
replace quarter_loss          = quarter_loss - 0.2
replace quarter_gains_SubFunc = quarter_gains_SubFunc + 0.2
replace quarter_loss_SubFunc  = quarter_loss_SubFunc + 0.2

twoway ///
    (scatter coeff_gains quarter_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_gains ub_gains quarter_gains, lcolor(ebblue)) ///
    (scatter coeff_gains_SubFunc quarter_gains_SubFunc, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_gains_SubFunc ub_gains_SubFunc quarter_gains_SubFunc, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Employee FE + year-month FE") label(4 "Employee FE + year-month * subfunction FE") order(2 4) position(6) ring(0) size(small))
graph export "${Round1Results}/CA30SubFunc_Outcome2_SGRawC_Coef1_Gains.pdf", replace as(pdf)

twoway ///
    (scatter coeff_loss quarter_loss, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_loss ub_loss quarter_loss, lcolor(ebblue)) ///
    (scatter coeff_loss_SubFunc quarter_loss_SubFunc, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_loss_SubFunc ub_loss_SubFunc quarter_loss_SubFunc, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)20, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Employee FE + year-month FE") label(4 "Employee FE + year-month * subfunction FE") order(2 4) position(6) ring(0) size(small))
graph export "${Round1Results}/CA30SubFunc_Outcome2_SGRawC_Coef2_Loss.pdf", replace as(pdf)