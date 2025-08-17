
/* 
This do file plots the distribution of the event month.

RA: WWZ 
Time: 2025-08-11
*/

use "${TempData}/FinalAnalysisSample.dta", clear 
keep if occurrence==1

generate Event_Month = month(dofm(Event_Time))

histogram Event_Month, discrete fraction width(1) ///
    color(ebblue%20) ///
    xlabel(1(1)12) xtitle("Month of events")
graph export "${Round1Results}/EventMonthDist.pdf", replace as(pdf)