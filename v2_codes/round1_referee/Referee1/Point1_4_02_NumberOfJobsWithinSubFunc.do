/* 
This do file computes the number of distinct job titles within subfunctions.

RA: WWZ 
Time: 2025-07-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. number of distinct jobs within subfunctions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

keep StandardJob SubFunc
duplicates drop 
    //&? keep all unique (StandardJob SubFunc) pairs

sort SubFunc StandardJob
bysort SubFunc: generate occurrence = _n 
bysort SubFunc: generate NumStandardJob = _N

summarize NumStandardJob if occurrence==1, detail
global Median = r(p50)

histogram NumStandardJob if occurrence==1 ///
    , width(5) color(gray%50) xline(${Median}, lcolor(maroon)) ///
    text(0.07 10 "Median = 9", placement(e)) ///
    xlabel(0(10)200, grid gstyle(dot) labsize(small)) xtitle("Number of distinct job titles within subfunctions") ///
    ylabel(0(0.01)0.08, grid gstyle(dot))
graph export "${Round1Results}/NumberOfJobsWithinSubFunc.pdf", replace as(pdf)
