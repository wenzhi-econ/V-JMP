/* 
This file conducts endogenous-mobility-checks style regressions on pre- and post-event team size.

RA: WWZ 
Time: 2025-08-11
*/

use "${TempData}/0106TeamLevelEventsAndOutcomes.dta", clear 

global controls FuncM ISOCodeM Year

eststo clear 

reghdfe spanM CA30_toH if inrange(Rel_Time, -24, -1), cluster(IDlseMHRPreMost) absorb($controls)
    local r_squared = e(r2)
    eststo reg1
    summarize spanM if e(sample)==1 & CA30_toL==1
    estadd scalar mean_toL = r(mean)
    estadd scalar r_squared = `r_squared'

reghdfe spanM CA30_toH if inrange(Rel_Time, 1, 24), cluster(IDlseMHRPreMost) absorb($controls)
    local r_squared = e(r2)
    eststo reg2
    summarize spanM if e(sample)==1 & CA30_toL==1
    estadd scalar mean_toL = r(mean)
    estadd scalar r_squared = `r_squared'

global latex_file "${Round1Results}/CA30_EndogenousMobilityChecks_TeamSize_PreAndPost.tex"

esttab reg1 reg2 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels se nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) b(4) se(3) ///
    keep(CA30_toH) order(CA30_toH) varlabels(CA30_toH "High flyer manager") ///
    stats(r_squared N, labels("R-squared" "N") fmt(%9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lcc}" "\toprule" "\toprule" "& \multicolumn{2}{c}{Outcome: Team size} \\" "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} \\" "& \multicolumn{1}{c}{Pre-event} & \multicolumn{1}{c}{Post-event} \\") ///
    posthead("\midrule") ///
    prefoot("\midrule")  ///
    postfoot("\bottomrule" "\bottomrule" "\end{tabular}")

