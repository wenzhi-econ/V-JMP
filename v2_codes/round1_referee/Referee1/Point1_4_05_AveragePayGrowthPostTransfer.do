/* 
This do file compares whether workers are transferred to ex ante better teams.

RA: WWZ 
Time: 2025-07-07
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create team-level average salary growth rates
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

keep  YearMonth IDlse IDlseMHR LogPayBonus

sort IDlse YearMonth
xtset IDlse YearMonth, monthly
generate SalaryGrowthRate = D.LogPayBonus

order IDlseMHR YearMonth IDlse LogPayBonus
sort  IDlseMHR YearMonth IDlse
rename IDlse IDTeamMember

bysort IDlseMHR YearMonth: egen TeamGrowthRate = mean(SalaryGrowthRate)

keep IDlseMHR YearMonth TeamGrowthRate
duplicates drop 

xtset IDlseMHR YearMonth, monthly
generate L6_TeamGrowthRate = L6.TeamGrowthRate
generate L12_TeamGrowthRate = L12.TeamGrowthRate

save "${TempData}/R2_Point2_2_TeamLevel_AvgSalaryGrowthRate.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. obtain an event worker dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. keep relevant post-event periods
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep IDlse YearMonth IDlseMHR Rel_Time Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL Female AgeBand Office Func
keep if Rel_Time==24 | Rel_Time==36 | Rel_Time==60 | Rel_Time==84 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. obtain team-level average salary growth rates
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

merge m:1 IDlseMHR YearMonth using "${TempData}/R2_Point2_2_TeamLevel_AvgSalaryGrowthRate.dta", keep(match master) keepusing(TeamGrowthRate L6_TeamGrowthRate L12_TeamGrowthRate) nogenerate

save "${TempData}/R2_Point2_2_EventWorkersPostPeriods_WithTeamLevelGrowthRates.dta", replace 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/R2_Point2_2_EventWorkersPostPeriods_WithTeamLevelGrowthRates.dta", clear 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. exit controls 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe L6_TeamGrowthRate  CA30_LtoH CA30_HtoH CA30_HtoL if Rel_Time==24, vce(robust) absorb(Func##Office Female##AgeBand)
    local r_squared = e(r2)
    summarize L6_TeamGrowthRate if CA30_LtoL==1 & e(sample)==1
        local cmean = r(mean)
    xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
        eststo L6_2Years
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'

reghdfe L6_TeamGrowthRate  CA30_LtoH CA30_HtoH CA30_HtoL if Rel_Time==36, vce(robust) absorb(Func##Office Female##AgeBand)
    local r_squared = e(r2)
    summarize L6_TeamGrowthRate if CA30_LtoL==1 & e(sample)==1
        local cmean = r(mean)
    xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
        eststo L6_3Years
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'

reghdfe L6_TeamGrowthRate  CA30_LtoH CA30_HtoH CA30_HtoL if Rel_Time==60, vce(robust) absorb(Func##Office Female##AgeBand)
    local r_squared = e(r2)
    summarize L6_TeamGrowthRate if CA30_LtoL==1 & e(sample)==1
        local cmean = r(mean)
    xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
        eststo L6_5Years
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'

reghdfe L6_TeamGrowthRate  CA30_LtoH CA30_HtoH CA30_HtoL if Rel_Time==84, vce(robust) absorb(Func##Office Female##AgeBand)
    local r_squared = e(r2)
    summarize L6_TeamGrowthRate if CA30_LtoL==1 & e(sample)==1
        local cmean = r(mean)
    xlincom (CA30_LtoH) (CA30_HtoL-CA30_HtoH), post
        eststo L6_7Years
        estadd scalar cmean = `cmean'
        estadd scalar r_squared = `r_squared'

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. produce regression tables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} \\"
global latex_panels       "& \multicolumn{1}{c}{2 years later} & \multicolumn{1}{c}{3 years later} & \multicolumn{1}{c}{5 years later} & \multicolumn{1}{c}{7 years later}  \\"
global latex_var          "\multicolumn{5}{c}{Outcome: Lagged (-6 months) team-level average salary growth rates} \\"
global latex_file         "${Round1Results}/LaggedTeamAvgSalaryGrowthRates.tex"

global eq L6_2Years L6_3Years L6_5Years L6_7Years

esttab ${eq} using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(3) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(lc_1) order(lc_1) varlabels(lc_1 "LtoH - LtoL") ///
    stats(cmean r_squared N, labels("Mean dependent variable, LtoL group" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_var}" "${latex_midrule}" "${latex_panels}" "${latex_numbers}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")
