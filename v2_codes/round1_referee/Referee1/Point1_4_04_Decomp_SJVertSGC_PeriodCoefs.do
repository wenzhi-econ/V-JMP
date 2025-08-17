/* 
This do file plots coefficients on the decomposed outcomes across two periods.

RA: WWZ 
Time: 2025-08-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. process the datasets containing required coefficients
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome3_SJVertSGC_Decomp_QuarterYearAndPeriodCoefs.dta", clear 

keep Year_* ccoef_* llb_* uub_* 
rename (ccoef_SJVertSGC_gains llb_SJVertSGC_gains uub_SJVertSGC_gains ccoef_SameMVC_gains llb_SameMVC_gains uub_SameMVC_gains ccoef_DiffMVC_gains llb_DiffMVC_gains uub_DiffMVC_gains ccoef_DiffFuncSJVC_gains llb_DiffFuncSJVC_gains uub_DiffFuncSJVC_gains) (coef_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains coef_SameMVC_gains lb_SameMVC_gains ub_SameMVC_gains coef_DiffMVC_gains lb_DiffMVC_gains ub_DiffMVC_gains coef_DiffFuncSJVC_gains lb_DiffFuncSJVC_gains ub_DiffFuncSJVC_gains)

generate Year = Year_SJVertSGC_gains

foreach var in SameMVC DiffMVC DiffFuncSJVC {
    generate frac_`var'_gains = coef_`var'_gains / coef_SJVertSGC_gains
    generate frac_`var'_gains_int = round(frac_`var'_gains * 100)
    tostring frac_`var'_gains_int, generate(frac_`var'_gains_str)
}

egen test = rowtotal(frac_SameMVC_gains frac_DiffMVC_gains frac_DiffFuncSJVC_gains)
tabulate test, sort
    //&? roughly 1, as expected

foreach var in SameMVC DiffMVC DiffFuncSJVC {
    forvalues i = 1/9 {
        global frac_`var'_`i' = frac_`var'_gains_str[`i']
    }
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. draw the stacked bar plot
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture drop Period
tostring Year, generate(Period)
format Period %15s
replace Period="Year 0-3" if Period=="8"
replace Period="Year 4-7" if Period=="9"

graph bar coef_SameMVC_gains coef_DiffMVC_gains coef_DiffFuncSJVC_gains if inrange(Year, 8, 9), ///
    over(Period, gap(10)) stack ///
    scheme(tab2) name(bar_stacked, replace) ///
    legend(label(1 "Within team") label(2 "Across teams, within function") label(3 "Across teams, across functions")) ///
    b1title("") ytitle("Coefficients value") ///
    ylabel(0(0.01)0.15, grid gstyle(dot)) ///
    text(0.130  0.00 "reporting % of total lateral moves", size(medium) placement(e)) ///
    text(0.0025 27.5 "${frac_SameMVC_8}%"     , size(vsmall)  placement(e)) ///
    text(0.018  27.5 "${frac_DiffMVC_8}%"     , size(vsmall)  placement(e)) ///
    text(0.03   28.0 "${frac_DiffFuncSJVC_8}%", size(vsmall)  placement(e)) ///
    text(0.015  70.0 "${frac_SameMVC_9}%"     , size(medium)  placement(e)) ///
    text(0.060  70.0 "${frac_DiffMVC_9}%"     , size(medium)  placement(e)) ///
    text(0.095  73.0 "${frac_DiffFuncSJVC_9}%", size(medium)  placement(n))
graph export "${Round1Results}/CA30_Outcome3_SJVertSGC_Decomp_PeriodCoefs.pdf", replace as(pdf)