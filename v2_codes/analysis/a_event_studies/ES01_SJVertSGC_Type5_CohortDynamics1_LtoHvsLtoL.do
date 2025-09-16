/* 
This do file runs event study regressions on outcome: SJVertSGC (count of standard job changes with simultaneous salary grade increases).
The high-flyer measure used here is CA30.

Special notes:
    (1) This do file computes a modified version of cohort-average treatment effects based on Liyang Sun and Sarah Abraham, "Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects," Journal of Econometrics 225, no. 2 (2021): 175–99, https://doi.org/10.1016/j.jeconom.2020.09.006.

Notes on the event study regressions.
    (1) To reduce the computational burden, only LtoH and LtoL event workers are included in the regressions. Never-treated workers are not included.
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84].

Notes on the implementation of cohort dynamics:
    (1) For each "event * relative month" indicator dummy appeared in the normal TWFE regression, I interact it with 10 other dummies (from 2011 to 2020) indicating the year in which the manager change event happens.
    (2) The coefficients of these dummies are estimated using reghdfe, controlling for time and individual fixed effects.
    (3) For each event group, and for each relative month, I calculate the share of regression sample that belongs to each cohort (so there are 10 numbers that sum to one indicating the weights associated with each cohort).
    (4) The coefficients on "event * relative month indicator * cohort indicator" are first aggregated to coefficients on "event * relative month indicator" using the weights calculated in step 3.
    (5) Furthermore, coefficients are aggregated to "event * relative quarter" level based on the same quarter aggregation procedure in the TWFE regression.
    (6) The above procedures are implemented by the Stata programs defined in 0207 do file.

Input: 
    "${TempData}/FinalAnalysisSample.dta" <== created in 0103_03 do file

Output:
    "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL.txt"
    "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL.dta"
    "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Coef1_Gains_Type5_CohortDynamics.gph"

RA: WWZ 
Time: 2025-07-16
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the interaction terms
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL.txt", replace text

use "${TempData}/FinalAnalysisSample.dta", clear

keep if CA30_LtoL==1 | CA30_LtoH==1
    //&? keep only LtoL and LtoH event workers 

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. the ordinary event * relative periods indicators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*&& Months -1, -2, and -3 are omitted as the reference group.
*impt: The variable name of the "event * relative period" dummies matter!
*impt: Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Pre1 CA30_LtoH_X_Post0 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoL_X_Pre_Before24 CA30_LtoH_X_Post_After84
*/

generate  CA30_Rel_Time = Rel_Time
summarize CA30_Rel_Time, detail // range: [-131, +130]

*!! time window of interest
local max_pre_period  = 24 
local Lto_max_post_period = 84

*!! CA30_LtoL
generate byte CA30_LtoL_X_Pre_Before`max_pre_period' = CA30_LtoL * (CA30_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte CA30_LtoL_X_Pre`time' = CA30_LtoL * (CA30_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte CA30_LtoL_X_Post`time' = CA30_LtoL * (CA30_Rel_Time == `time')
}
generate byte CA30_LtoL_X_Post_After`Lto_max_post_period' = CA30_LtoL * (CA30_Rel_Time > `Lto_max_post_period')

*!! CA30_LtoH
generate byte CA30_LtoH_X_Pre_Before`max_pre_period' = CA30_LtoH * (CA30_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte CA30_LtoH_X_Pre`time' = CA30_LtoH * (CA30_Rel_Time == -`time')
}
forvalues time = 0/`Lto_max_post_period' {
    generate byte CA30_LtoH_X_Post`time' = CA30_LtoH * (CA30_Rel_Time == `time')
}
generate byte CA30_LtoH_X_Post_After`Lto_max_post_period' = CA30_LtoH * (CA30_Rel_Time > `Lto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. global macros for the ordinary event * relative periods indicators
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local max_pre_period  = 24 
local Lto_max_post_period = 84

macro drop CA30_LtoL_X_Pre CA30_LtoL_X_Post CA30_LtoH_X_Pre CA30_LtoH_X_Post 

foreach event in CA30_LtoL CA30_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in CA30_LtoL CA30_LtoH {
    forvalues time = 0/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}

global two_events_dummies ${CA30_LtoL_X_Pre} ${CA30_LtoL_X_Post} ${CA30_LtoH_X_Pre} ${CA30_LtoH_X_Post}

display "${two_events_dummies}"

    // CA30_LtoL_X_Pre_Before24 CA30_LtoL_X_Pre24 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Pre_Before24 CA30_LtoH_X_Pre24 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. interaction with cohort indicators (which year the event takes place)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate YEi = year(dofm(Event_Time))

forval yy = 2011(1)2020 {
    generate byte cohort`yy' = (YEi == `yy') 
    foreach l in $two_events_dummies {
        generate byte `l'_`yy'  = cohort`yy'* `l' 
        local eventinteract "`eventinteract' `l'_`yy'"
    }
}
global eventinteract `eventinteract'
display "${eventinteract}"

    // CA30_LtoL_X_Pre_Before24_2011 CA30_LtoL_X_Pre24_2011 ... CA30_LtoL_X_Pre4_2011 CA30_LtoL_X_Post0_2011 CA30_LtoL_X_Post1_2011 ... CA30_LtoL_X_Post84_2011 CA30_LtoL_X_Pre_After84_2011
    // ...
    // CA30_LtoL_X_Pre_Before24_2020 CA30_LtoL_X_Pre24_2020 ... CA30_LtoL_X_Pre4_2020 CA30_LtoL_X_Post0_2020 CA30_LtoL_X_Post1_2020 ... CA30_LtoL_X_Post84_2020 CA30_LtoL_X_Pre_After84_2020
    // CA30_LtoH_X_Pre_Before24_2011 CA30_LtoH_X_Pre24_2011 ... CA30_LtoH_X_Pre4_2011 CA30_LtoH_X_Post0_2011 CA30_LtoH_X_Post1_2011 ... CA30_LtoH_X_Post84_2011 CA30_LtoH_X_Pre_After84_2011
    // ...
    // CA30_LtoH_X_Pre_Before24_2020 CA30_LtoH_X_Pre24_2020 ... CA30_LtoH_X_Pre4_2020 CA30_LtoH_X_Post0_2020 CA30_LtoH_X_Post1_2020 ... CA30_LtoH_X_Post84_2020 CA30_LtoH_X_Pre_After84_2020

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate SJVertSG = TransferSJ
replace  SJVertSG = 0 if ChangeSalaryGrade==0
sort IDlse YearMonth
bysort IDlse: generate SJVertSGC = sum(SJVertSG)

foreach var in SJVertSGC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-2-1. main regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${eventinteract} if (CA30_LtoL==1 | CA30_LtoH==1), absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-2-2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    LH_minus_LL_CohortDynamics, event_prefix(CA30) pre_window_len(24) post_window_len(84) outcome(`var')

}

keep coeff_* quarter_* lb_* ub_* 
keep if inrange(_n, 1, 41)
save "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL.dta", replace 

log close

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. visualize the results 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. prepare the datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
drop if quarter==.
rename (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) (quarter_SJVertSGC_CA30 coeff_SJVertSGC_CA30 lb_SJVertSGC_CA30 ub_SJVertSGC_CA30)
save "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", replace 

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL.dta", clear 
keep quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains
generate quarter = quarter_SJVertSGC_gains
drop if quarter==.
rename (quarter_SJVertSGC_gains coeff_SJVertSGC_gains lb_SJVertSGC_gains ub_SJVertSGC_gains) (quarter_SJVertSGC_CD coeff_SJVertSGC_CD lb_SJVertSGC_CD ub_SJVertSGC_CD)
save "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL_ForMerge.dta", replace 

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta", clear 
merge 1:1 quarter using "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL_ForMerge.dta", nogenerate 

replace quarter_SJVertSGC_CA30 = quarter_SJVertSGC_CA30 - 0.2
replace quarter_SJVertSGC_CD   = quarter_SJVertSGC_CD + 0.2

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-2. contrast TWFE against the cohort-dynamics specification
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

twoway ///
    (scatter coeff_SJVertSGC_CA30 quarter_SJVertSGC_CA30, lcolor(ebblue) mcolor(ebblue)) ///
    (rcap lb_SJVertSGC_CA30 ub_SJVertSGC_CA30 quarter_SJVertSGC_CA30, lcolor(ebblue)) ///
    (scatter coeff_SJVertSGC_CD quarter_SJVertSGC_CD, lcolor("237 68 74") mcolor("237 68 74")) ///
    (rcap lb_SJVertSGC_CD ub_SJVertSGC_CD quarter_SJVertSGC_CD, lcolor("237 68 74")) ///
    , yline(0, lcolor(maroon)) xline(-1, lcolor(maroon)) ///
    xlabel(-8(2)28, grid gstyle(dot) labsize(medsmall)) /// 
    ylabel(-0.3(0.05)0.3, grid gstyle(dot) labsize(medsmall)) ///
    xtitle("Quarters since manager change", size(medlarge)) ///
    legend(label(2 "Baseline TWFE estimates") label(4 "Sun and Abraham (2021) estimates") order(2 4) position(6) ring(0) size(small))
graph save "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Coef1_Gains_Type5_CohortDynamics.gph", replace

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-3. erase auxiliary datasets
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

if ${if_erase_temp_file}==1 {
    erase "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline_ForMerge.dta"
    erase "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL_ForMerge.dta"
}