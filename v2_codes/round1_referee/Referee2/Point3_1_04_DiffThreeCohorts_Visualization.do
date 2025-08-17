/* 
This do file visualizes the results to be presented in the referee report.

RA: WWZ 
Time: 2025-07-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Round1Results}/CA30_Outcome2_SGRawC_DiffThreeCohorts.dta", clear 
keep if quarter_1==8 | quarter_1==20 | _n==40 | _n==41
replace quarter_1 = 2 if _n==3
replace quarter_1 = 5 if _n==4
generate quarter = quarter_1
drop quarter_*
reshape long coeff_ lb_ ub_, i(quarter) j(cohort)
drop if coeff_==0
rename (coeff_ lb_ ub_) (coeff_SGRawC lb_SGRawC ub_SGRawC)
save "${Round1Results}/CA30_Outcome2_SGRawC_DiffThreeCohorts_ForMerge.dta", replace 

use "${Round1Results}/CA30_Outcome1_SJVertSGC_DiffThreeCohorts.dta", clear 
keep if quarter_1==8 | quarter_1==20 | _n==40 | _n==41
replace quarter_1 = 2 if _n==3
replace quarter_1 = 5 if _n==4
generate quarter = quarter_1
drop quarter_*
reshape long coeff_ lb_ ub_, i(quarter) j(cohort)
drop if coeff_==0
rename (coeff_ lb_ ub_) (coeff_SJVertSGC lb_SJVertSGC ub_SJVertSGC)
save "${Round1Results}/CA30_Outcome1_SJVertSGC_DiffThreeCohorts_ForMerge.dta", replace 

use "${Round1Results}/CA30_Outcome5_PromWLC_DiffThreeCohorts.dta", clear 
keep if quarter_1==8 | quarter_1==20 | _n==40 | _n==41
replace quarter_1 = 2 if _n==3
replace quarter_1 = 5 if _n==4
generate quarter = quarter_1
drop quarter_*
reshape long coeff_ lb_ ub_, i(quarter) j(cohort)
drop if coeff_==0
rename (coeff_ lb_ ub_) (coeff_PromWLC lb_PromWLC ub_PromWLC)
save "${Round1Results}/CA30_Outcome5_PromWLC_DiffThreeCohorts_ForMerge.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. merge the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${Round1Results}/CA30_Outcome2_SGRawC_DiffThreeCohorts_ForMerge.dta", clear 
merge 1:1 quarter cohort using "${Round1Results}/CA30_Outcome1_SJVertSGC_DiffThreeCohorts_ForMerge.dta", nogenerate
merge 1:1 quarter cohort using "${Round1Results}/CA30_Outcome5_PromWLC_DiffThreeCohorts_ForMerge.dta", nogenerate

label define cohort 0 "All event years" 1 "2011-13" 2 "2014-16" 3 "2017-19"
label values cohort cohort

generate cohort_outcome1 = cohort + 0
generate cohort_outcome2 = cohort + 3 + 2
generate cohort_outcome3 = cohort + 6 + 4

twoway ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==2 & cohort==0, msymbol(square) mcolor(magenta)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==2 & cohort==0, lcolor(magenta)) ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==2 & cohort==1, msymbol(diamond) mcolor(ebblue)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==2 & cohort==1, lcolor(ebblue)) ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==2 & cohort==2, msymbol(triangle) mcolor(dkgreen)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==2 & cohort==2, lcolor(dkgreen)) ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==2 & cohort==3, msymbol(circle) mcolor(cranberry)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==2 & cohort==3, lcolor(cranberry)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==2 & cohort==0, msymbol(square) mcolor(magenta)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==2 & cohort==0, lcolor(magenta)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==2 & cohort==1, msymbol(diamond) mcolor(ebblue)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==2 & cohort==1, lcolor(ebblue)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==2 & cohort==2, msymbol(triangle) mcolor(dkgreen)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==2 & cohort==2, lcolor(dkgreen)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==2 & cohort==3, msymbol(circle) mcolor(cranberry)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==2 & cohort==3, lcolor(cranberry)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==2 & cohort==0, msymbol(square) mcolor(magenta)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==2 & cohort==0, lcolor(magenta)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==2 & cohort==1, msymbol(diamond) mcolor(ebblue)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==2 & cohort==1, lcolor(ebblue)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==2 & cohort==2, msymbol(triangle) mcolor(dkgreen)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==2 & cohort==2, lcolor(dkgreen)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==2 & cohort==3, msymbol(circle) mcolor(cranberry)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==2 & cohort==3, lcolor(cranberry)) ///
    , xsize(20) ysize(10) ///
    text(0.25 1.8  "Lateral moves", placement(c) size(medium)) ///
    text(0.2 1.5  "`=ustrunescape("\u23AB")'" "`=ustrunescape("\u23AC")'"  "`=ustrunescape("\u23AD")'", orientation(vertical) placement(c) size(100pt) lwidth(1pt)) ///
    text(0.25 6.8  "Salary grade increases", placement(c) size(medium)) ///
    text(0.2 6.5  "`=ustrunescape("\u23AB")'" "`=ustrunescape("\u23AC")'"  "`=ustrunescape("\u23AD")'", orientation(vertical) placement(c) size(100pt) lwidth(1pt)) ///
    text(0.25 11.8 "Work level promotions", placement(c) size(medium)) ///
    text(0.2 11.5  "`=ustrunescape("\u23AB")'" "`=ustrunescape("\u23AC")'"  "`=ustrunescape("\u23AD")'", orientation(vertical) placement(c) size(100pt) lwidth(1pt)) ///
    yline(0, lcolor(maroon)) ///
    xlabel(, nolabels noticks nogrid) xscale(range(0 11)) /// 
    ylabel(-0.1(0.05)0.3, grid gstyle(dot) labsize(medsmall)) yscale(range(-0.1 0.35)) ///
    title("Effects of gaining a high-flyer manager, by event cohorts") ///
    subtitle("Year 0-2 average estimates", span pos(12)) ///
    legend(label(1 "All cohorts") label(3 "Early-cohort: 2011-13") label(5 "Mid-cohort: 2014-16") label(7 "Late-cohort: 2017-19") order(1 3 5 7) position(6) ring(0) rows(1))
graph export "${Round1Results}/CA30_ThreeOutcomes_FourCohortCoefs_Year0to2.png", replace as(png)

twoway ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==5 & cohort==0, msymbol(square) mcolor(magenta)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==5 & cohort==0, lcolor(magenta)) ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==5 & cohort==1, msymbol(diamond) mcolor(ebblue)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==5 & cohort==1, lcolor(ebblue)) ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==5 & cohort==2, msymbol(triangle) mcolor(dkgreen)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==5 & cohort==2, lcolor(dkgreen)) ///
    (scatter coeff_SJVertSGC cohort_outcome1           if quarter==5 & cohort==3, msymbol(circle) mcolor(cranberry)) ///
    (rcap    lb_SJVertSGC ub_SJVertSGC cohort_outcome1 if quarter==5 & cohort==3, lcolor(cranberry)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==5 & cohort==0, msymbol(square) mcolor(magenta)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==5 & cohort==0, lcolor(magenta)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==5 & cohort==1, msymbol(diamond) mcolor(ebblue)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==5 & cohort==1, lcolor(ebblue)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==5 & cohort==2, msymbol(triangle) mcolor(dkgreen)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==5 & cohort==2, lcolor(dkgreen)) ///
    (scatter coeff_SGRawC cohort_outcome2              if quarter==5 & cohort==3, msymbol(circle) mcolor(cranberry)) ///
    (rcap    lb_SGRawC ub_SGRawC cohort_outcome2       if quarter==5 & cohort==3, lcolor(cranberry)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==5 & cohort==0, msymbol(square) mcolor(magenta)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==5 & cohort==0, lcolor(magenta)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==5 & cohort==1, msymbol(diamond) mcolor(ebblue)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==5 & cohort==1, lcolor(ebblue)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==5 & cohort==2, msymbol(triangle) mcolor(dkgreen)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==5 & cohort==2, lcolor(dkgreen)) ///
    (scatter coeff_PromWLC cohort_outcome3             if quarter==5 & cohort==3, msymbol(circle) mcolor(cranberry)) ///
    (rcap    lb_PromWLC ub_PromWLC cohort_outcome3     if quarter==5 & cohort==3, lcolor(cranberry)) ///
    , xsize(20) ysize(10) ///
    text(0.31 1.8  "Lateral moves", placement(c) size(medium)) ///
    text(0.27 1.5  "`=ustrunescape("\u23AB")'" "`=ustrunescape("\u23AC")'"  "`=ustrunescape("\u23AD")'", orientation(vertical) placement(c) size(100pt) lwidth(1pt)) ///
    text(0.31 6.8  "Salary grade increases", placement(c) size(medium)) ///
    text(0.27 6.5  "`=ustrunescape("\u23AB")'" "`=ustrunescape("\u23AC")'"  "`=ustrunescape("\u23AD")'", orientation(vertical) placement(c) size(100pt) lwidth(1pt)) ///
    text(0.31 11.8 "Work level promotions", placement(c) size(medium)) ///
    text(0.27 11.5  "`=ustrunescape("\u23AB")'" "`=ustrunescape("\u23AC")'"  "`=ustrunescape("\u23AD")'", orientation(vertical) placement(c) size(100pt) lwidth(1pt)) ///
    yline(0, lcolor(maroon)) ///
    xlabel(, nolabels noticks nogrid) xscale(range(0 11)) /// 
    ylabel(-0.1(0.05)0.3, grid gstyle(dot) labsize(medsmall)) yscale(range(-0.1 0.35)) ///
    title("Effects of gaining a high-flyer manager, by event cohorts") ///
    subtitle("Year 2-5 average estimates", span pos(12)) ///
    legend(label(1 "All cohorts") label(3 "Early-cohort: 2011-13") label(5 "Mid-cohort: 2014-16") label(7 "Late-cohort: 2017-19") order(1 3 5 7) position(6) ring(0) rows(1))
graph export "${Round1Results}/CA30_ThreeOutcomes_FourCohortCoefs_Year2to5.png", replace as(png)