
/* 
This do file runs regressions for endogenous mobility checks on the team-level dataset.

Notes on the regressions:
    (1) The regression sample consists of teams who experienced manager change in relative period [-24, -1], with the restrictions listed in (2) and (3).
    (2) The team contains more than 1 worker, and both the pre- and post-event managers are of WL2.
    (3) The worker does not have a simultaneous internal or lateral move.

Input: 
    "${TempData}/0106TeamLevelEventsAndOutcomes.dta" <== created in 0106 do file

Output:
    "${EventStudyResults}/CA30_EndogenousMobilityChecks_ToH_Pre24toPre1.tex"

RA: WWZ 
Time: 2025-09-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. preparations for regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0106TeamLevelEventsAndOutcomes.dta", clear 

generate lAvPay      = log(AvPay)
generate lAvPayBonus = log(AvPayBonus)

global perf  lAvPayBonus      AvBPRatio         ShareChangeSalaryGrade SharePromWL
global mob   ShareTransferSJV ShareTransferFunc ShareSameAge           ShareSameOffice
global div   TeamFracFemale   TeamFracAgeBand   TeamFracOfficeCode     TeamFracCountry

label variable CA30_toH "High-flyer manager"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global controls FuncM ISOCodeM Year

eststo clear 

local i = 1
foreach y in $perf $mob $div {
	
    reghdfe `y' CA30_toH if spanM>1 & inrange(Rel_Time, -24, -1), cluster(IDlseMHRPreMost) absorb($controls)
        eststo reg`i'
        summarize `y' if e(sample)==1 & CA30_toL==1
        estadd scalar mean_toL = r(mean)

    local i = `i' +1
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3: produce the table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\"
global latex_titles_A     "& \multicolumn{1}{c}{Pay + bonus (logs)} & \multicolumn{1}{c}{Bonus/pay ratio} & \multicolumn{1}{c}{Salary grade increase} & \multicolumn{1}{c}{Vertical move} \\"
global latex_titles_B     "& \multicolumn{1}{c}{Lateral move} & \multicolumn{1}{c}{Cross-functional move} & \multicolumn{1}{c}{Same age} & \multicolumn{1}{c}{Same office} \\"
global latex_titles_C     "& \multicolumn{1}{c}{Diversity, gender} & \multicolumn{1}{c}{Diversity, age} & \multicolumn{1}{c}{Diversity, office} & \multicolumn{1}{c}{Diversity, nationality} \\"
global latex_file         "${EventStudyResults}/CA30_EndogenousMobilityChecks_ToH_Pre24toPre1.tex"

esttab reg1 reg2 reg3 reg4 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_toH) ///
    stats(mean_toL r2 N, labels("Mean, low-flyer manager" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}" "\multicolumn{5}{c}{\textit{Panel (a): team performance}} \\ [7pt]" "${latex_numbers}" "${latex_titles_A}") ///
    posthead("${latex_midrule}") prefoot("${latex_midrule}") postfoot("${latex_midrule}")

esttab reg5 reg6 reg7 reg8 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_toH) ///
    stats(mean_toL r2 N, labels("Mean, low-flyer manager" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\multicolumn{5}{c}{\textit{Panel (b): team mobility}} \\ [7pt]") ///
    posthead("${latex_numbers}" "${latex_titles_B}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_midrule}")

esttab reg9 reg10 reg11 reg12 using "${latex_file}", ///
    append style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30_toH) ///
    stats(mean_toL r2 N, labels("Mean, low-flyer manager" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\multicolumn{5}{c}{\textit{Panel (c): team diversity}} \\ [7pt]") ///
    posthead("${latex_numbers}" "${latex_titles_C}" "${latex_midrule}") ///
    prefoot("${latex_midrule}")  ///
    postfoot("${latex_midrule}" "${latex_endtabular}")