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

use "${Round1Results}/FFE30_Outcome2_SGRawC_HFMeasureFFE30.dta", clear 
keep quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains
generate quarter = quarter_SGRawC_gains
rename ///
    (quarter_SGRawC_gains coeff_SGRawC_gains lb_SGRawC_gains ub_SGRawC_gains) ///
    (quarter_FFE30_gains  coeff_FFE30_gains  lb_FFE30_gains  ub_FFE30_gains)
drop if quarter==.
keep  quarter quarter_FFE30_gains coeff_FFE30_gains lb_FFE30_gains ub_FFE30_gains
order quarter quarter_FFE30_gains coeff_FFE30_gains lb_FFE30_gains ub_FFE30_gains
save "${Round1Results}/FFE30_Outcome2_SGRawC_HFMeasureFFE30_ForMerge.dta", replace

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

use "${Round1Results}/FFE30_Outcome2_SGRawC_HFMeasureFFE30_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome2_SGRawC_Type1_Baseline_ForMerge.dta", nogenerate

replace quarter_CA30_gains  = quarter_CA30_gains - 0.1
replace quarter_FFE30_gains = quarter_FFE30_gains + 0.1

twoway ///
    (scatter coeff_CA30_gains quarter_CA30_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_CA30_gains ub_CA30_gains quarter_CA30_gains, lcolor(ebblue)) ///
    (scatter coeff_FFE30_gains quarter_FFE30_gains, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_FFE30_gains ub_FFE30_gains quarter_FFE30_gains, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Original age-based high-flyer measure") label(4 "Manager FE based high-flyer measure") order(2 4) position(6) ring(0) size(small) rows(1))
graph export "${Round1Results}/CA30FFE30_Outcome2_SGRawC_Coef1_Gains.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. outcome: SJVertSGC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. prepare the dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${Round1Results}/FFE30_Outcome1_SJVertSGC_HFMeasureFFE30.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
rename ///
    (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) ///
    (quarter_FFE30_gains  coeff_FFE30_gains  lb_FFE30_gains  ub_FFE30_gains)
drop if quarter==.
keep  quarter quarter_FFE30_gains coeff_FFE30_gains lb_FFE30_gains ub_FFE30_gains
order quarter quarter_FFE30_gains coeff_FFE30_gains lb_FFE30_gains ub_FFE30_gains
save "${Round1Results}/FFE30_Outcome1_SJVertSGC_HFMeasureFFE30_ForMerge.dta", replace

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

use "${Round1Results}/FFE30_Outcome1_SJVertSGC_HFMeasureFFE30_ForMerge.dta", clear 
merge 1:1 quarter using "${Round1Results}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", nogenerate

replace quarter_CA30_gains  = quarter_CA30_gains - 0.1
replace quarter_FFE30_gains = quarter_FFE30_gains + 0.1

twoway ///
    (scatter coeff_CA30_gains quarter_CA30_gains, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_CA30_gains ub_CA30_gains quarter_CA30_gains, lcolor(ebblue)) ///
    (scatter coeff_FFE30_gains quarter_FFE30_gains, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_FFE30_gains ub_FFE30_gains quarter_FFE30_gains, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Original age-based high-flyer measure") label(4 "Manager FE based high-flyer measure") order(2 4) position(6) ring(0) size(small) rows(1))
graph export "${Round1Results}/CA30FFE30_Outcome1_SJVertSGC_Coef1_Gains.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step z. comparing different HF measures
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-1. density of the FE
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased.dta", clear 

pctile pctile_PayFE = PayFE, nquantiles(10)

global PayFE_50p = pctile_PayFE[5]
global PayFE_60p = pctile_PayFE[6]
global PayFE_70p = pctile_PayFE[7]

histogram PayFE, ///
    bcolor(ebblue%20) kdensity ///
    xline(${PayFE_50p}, lcolor(maroon)) ///
    xline(${PayFE_60p}, lcolor(maroon)) ///
    xline(${PayFE_70p}, lcolor(maroon)) ///
    xtitle("Manager fixed effects estimated on the full sample") ///
    note("The three vertical lines are p50, p60, p70 values")

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-z-2. correlation between different HF measures
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/R3_Point1_FE_HFMeasure_PayMngrFEBased.dta", clear 
rename IDMngr IDlseMHR
merge 1:m IDlseMHR using "${TempData}/0102_03HFMeasure.dta", keepusing(CA30 YearMonth) keep(match) nogenerate

sort IDlseMHR YearMonth
bysort IDlseMHR: generate occurrence = _n 
keep if occurrence==1

rename (FE50 FE40 FE30) (FFE50 FFE40 FFE30) 

correlate CA30 FFE50 FFE40 FFE30 
/* 
. correlate CA30 FFE30 FFE40 FFE30 
(obs=19,658)

             |     CA30    FFE30    FFE40    FFE30
-------------+------------------------------------
        CA30 |   1.0000
       FFE30 |   0.0209   1.0000
       FFE40 |   0.0225   0.8007   1.0000
       FFE30 |   0.0238   0.6275   0.7837   1.0000
*/