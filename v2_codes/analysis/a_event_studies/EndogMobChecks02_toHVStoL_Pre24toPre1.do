
/* 
This do file runs regressions for endogenous mobility checks on the team-level dataset.

Notes on the regressions:
    (1) The regression sample consists of teams who experienced manager change in relative period [-36, -6], with the restrictions listed in (2) and (3).
    (2) The team contains more than 1 worker, and both the pre- and post-event managers are of WL2.
    (3) The worker does not have a simultaneous internal or lateral move.

Input: 
    "${TempData}/0106TeamLevelEventsAndOutcomes.dta" <== created in 0106 do file

Output:
    

RA: WWZ 
Time: 2025-04-21
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. preparations for regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0106TeamLevelEventsAndOutcomes.dta", clear 

generate lAvPay      = log(AvPay)
generate lAvPayBonus = log(AvPayBonus)

global perf  lAvPay           lAvPayBonus       ShareChangeSalaryGrade AvBPRatio
global mob   ShareTransferSJV ShareTransferFunc ShareSameAge           ShareSameOffice
global div   TeamFracFemale   TeamFracAgeBand   TeamFracOfficeCode     TeamFracCountry

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global controls FuncM ISOCodeM Year

eststo clear 

local i = 1
foreach y in $perf $mob $div {
	
    reghdfe `y' CA30_LtoH CA30_HtoH CA30_HtoL if spanM>1 & inrange(Rel_Time, -24, -1), cluster(IDlseMHRPreMost) absorb($controls)
        local r_squared = e(r2)
        summarize `y' if e(sample)==1 & CA30_LtoL==1
            local cmean = r(mean)
        xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
            eststo reg`i'
            estadd scalar mean_LtoL = `cmean'
            estadd scalar r_squared = `r_squared'

    local i = `i' +1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_file         "${EventStudyResults}/CA30_EndogenousMobilityChecks_FullTransition_Pre24toPre1.tex"

esttab reg1 reg2 reg3 reg4 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("\hline Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcccc}" "\toprule" "\toprule" "\multicolumn{5}{c}{\textit{Panel (a): team performance}} \\ [7pt]" "& \multicolumn{1}{c}{Pay (logs)} & \multicolumn{1}{c}{Pay + bonus (logs)} & \multicolumn{1}{c}{Salary grade increase} & \multicolumn{1}{c}{Bonus/pay ratio} \\") ///
    posthead("\midrule") ///
    prefoot("")  ///
    postfoot("\midrule")

esttab reg5 reg6 reg7 reg8 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("\hline Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\multicolumn{5}{c}{\textit{Panel (b): team mobility}} \\ [7pt]") ///
    posthead("& \multicolumn{1}{c}{Lateral move} & \multicolumn{1}{c}{Cross-functional move} & \multicolumn{1}{c}{Same age} & \multicolumn{1}{c}{Same office} \\" "\midrule") ///
    prefoot("")  ///
    postfoot("\midrule")

esttab reg9 reg10 reg11 reg12 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels se ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(lc_1 lc_2) order(lc_1 lc_2) varlabels(lc_1 "LtoH - LtoL" lc_2 "HtoL - HtoH") ///
    stats(mean_LtoL r_squared N, labels("\hline Mean, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\multicolumn{5}{c}{\textit{Panel (c): team diversity}} \\ [7pt]") ///
    posthead("& \multicolumn{1}{c}{Diversity, gender} & \multicolumn{1}{c}{Diversity, age} & \multicolumn{1}{c}{Diversity, office} & \multicolumn{1}{c}{Diversity, nationality} \\" "\midrule") ///
    prefoot("") ///
    postfoot("\midrule" "\end{tabular}")