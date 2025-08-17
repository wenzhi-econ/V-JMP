/* 
This do file runs event study regressions on outcome: PromWLC.
The high-flyer measure used here is CA30.

Notes on the event study regressions:
    (1) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (2) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (3) For LtoL and LtoH groups, the relative time period is [-24, +84], while for HtoH and HtoL groups, the relative time period is [-24, +60].

Some key results (quarterly aggregated coefficients with their p-values, and other key summary statistics) are stored in the output file. 

Input: 
    "${TempData}/FinalAnalysisSample.dta"   <== created in 0103_03 do file

Output:
    "${Round1Results}/CA30_Outcome5_PromWLC_DiffThreeCohorts.dta"

RA: WWZ 
Time: 2025-07-10
*/

use "${TempData}/FinalAnalysisSample.dta", clear

generate Event_Year = year(dofm(Event_Time)), after(Event_Time)

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 0. construct variables and macros used in reghdfe command 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*&& Month 0 is omitted as the reference group. 
*&& This is because there will be no pre-event work level promotions due to the sample selection.
*impt: The variable name of the "event * relative period" dummies matter!
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Post1 CA30_LtoH_X_Post1 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoH_X_Post_After84 CA30_HtoH_X_Post_After60
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-1. event * period dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate  CA30_Rel_Time = Rel_Time
summarize CA30_Rel_Time, detail

*!! time window of interest
local Lto_max_post_period = 84
local Hto_max_post_period = 60

*!! CA30_LtoL
forvalues time = 0/`Lto_max_post_period' {
    generate byte CA30_LtoL_X_Post`time' = CA30_LtoL * (CA30_Rel_Time == `time')
}
generate byte CA30_LtoL_X_Post_After`Lto_max_post_period' = CA30_LtoL * (CA30_Rel_Time > `Lto_max_post_period')

*!! CA30_LtoH
forvalues time = 0/`Lto_max_post_period' {
    generate byte CA30_LtoH_X_Post`time' = CA30_LtoH * (CA30_Rel_Time == `time')
}
generate byte CA30_LtoH_X_Post_After`Lto_max_post_period' = CA30_LtoH * (CA30_Rel_Time > `Lto_max_post_period')

*!! CA30_HtoH 
forvalues time = 0/`Hto_max_post_period' {
    generate byte CA30_HtoH_X_Post`time' = CA30_HtoH * (CA30_Rel_Time == `time')
}
generate byte CA30_HtoH_X_Post_After`Hto_max_post_period' = CA30_HtoH * (CA30_Rel_Time > `Hto_max_post_period')

*!! CA30_HtoL 
forvalues time = 0/`Hto_max_post_period' {
    generate byte CA30_HtoL_X_Post`time' = CA30_HtoL * (CA30_Rel_Time == `time')
}
generate byte CA30_HtoL_X_Post_After`Hto_max_post_period' = CA30_HtoL * (CA30_Rel_Time > `Hto_max_post_period')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-0-2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local Lto_max_post_period = 84
local Hto_max_post_period = 60

macro drop CA30_LtoL_X_Post CA30_LtoH_X_Post CA30_HtoH_X_Post CA30_HtoL_X_Post

foreach event in CA30_LtoL CA30_LtoH {
    forvalues time = 1/`Lto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Lto_max_post_period'
}
foreach event in CA30_HtoH CA30_HtoL {
    forvalues time = 1/`Hto_max_post_period' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`Hto_max_post_period'
}

global four_events_dummies ${CA30_LtoL_X_Post} ${CA30_LtoH_X_Post} ${CA30_HtoH_X_Post} ${CA30_HtoL_X_Post}

display "${four_events_dummies}"

    // CA30_LtoL_X_Post1 CA30_LtoL_X_Post2 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Post1 CA30_LtoH_X_Post2 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 
    // CA30_HtoH_X_Post1 CA30_HtoH_X_Post2 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Post1 CA30_HtoL_X_Post2 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

#delimit ;
global coef_0yr_to_2yr 
    ((CA30_LtoH_X_Post1 - CA30_LtoL_X_Post1)
    + (CA30_LtoH_X_Post2 - CA30_LtoL_X_Post2)
    + (CA30_LtoH_X_Post3 - CA30_LtoL_X_Post3)
    + (CA30_LtoH_X_Post4 - CA30_LtoL_X_Post4)
    + (CA30_LtoH_X_Post5 - CA30_LtoL_X_Post5)
    + (CA30_LtoH_X_Post6 - CA30_LtoL_X_Post6)
    + (CA30_LtoH_X_Post7 - CA30_LtoL_X_Post7)
    + (CA30_LtoH_X_Post8 - CA30_LtoL_X_Post8)
    + (CA30_LtoH_X_Post9 - CA30_LtoL_X_Post9)
    + (CA30_LtoH_X_Post10 - CA30_LtoL_X_Post10)
    + (CA30_LtoH_X_Post11 - CA30_LtoL_X_Post11)
    + (CA30_LtoH_X_Post12 - CA30_LtoL_X_Post12)
    + (CA30_LtoH_X_Post13 - CA30_LtoL_X_Post13)
    + (CA30_LtoH_X_Post14 - CA30_LtoL_X_Post14)
    + (CA30_LtoH_X_Post15 - CA30_LtoL_X_Post15)
    + (CA30_LtoH_X_Post16 - CA30_LtoL_X_Post16)
    + (CA30_LtoH_X_Post17 - CA30_LtoL_X_Post17)
    + (CA30_LtoH_X_Post18 - CA30_LtoL_X_Post18)
    + (CA30_LtoH_X_Post19 - CA30_LtoL_X_Post19)
    + (CA30_LtoH_X_Post20 - CA30_LtoL_X_Post20)
    + (CA30_LtoH_X_Post21 - CA30_LtoL_X_Post21)
    + (CA30_LtoH_X_Post22 - CA30_LtoL_X_Post22)
    + (CA30_LtoH_X_Post23 - CA30_LtoL_X_Post23) 
    + (CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24))/24;
global coef_2yr_to_5yr
    ((CA30_LtoH_X_Post25 - CA30_LtoL_X_Post25)
    + (CA30_LtoH_X_Post26 - CA30_LtoL_X_Post26)
    + (CA30_LtoH_X_Post27 - CA30_LtoL_X_Post27)
    + (CA30_LtoH_X_Post28 - CA30_LtoL_X_Post28)
    + (CA30_LtoH_X_Post29 - CA30_LtoL_X_Post29)
    + (CA30_LtoH_X_Post30 - CA30_LtoL_X_Post30)
    + (CA30_LtoH_X_Post31 - CA30_LtoL_X_Post31)
    + (CA30_LtoH_X_Post32 - CA30_LtoL_X_Post32)
    + (CA30_LtoH_X_Post33 - CA30_LtoL_X_Post33)
    + (CA30_LtoH_X_Post34 - CA30_LtoL_X_Post34)
    + (CA30_LtoH_X_Post35 - CA30_LtoL_X_Post35)
    + (CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36)
    + (CA30_LtoH_X_Post37 - CA30_LtoL_X_Post37)
    + (CA30_LtoH_X_Post38 - CA30_LtoL_X_Post38)
    + (CA30_LtoH_X_Post39 - CA30_LtoL_X_Post39)
    + (CA30_LtoH_X_Post40 - CA30_LtoL_X_Post40)
    + (CA30_LtoH_X_Post41 - CA30_LtoL_X_Post41)
    + (CA30_LtoH_X_Post42 - CA30_LtoL_X_Post42)
    + (CA30_LtoH_X_Post43 - CA30_LtoL_X_Post43)
    + (CA30_LtoH_X_Post44 - CA30_LtoL_X_Post44)
    + (CA30_LtoH_X_Post45 - CA30_LtoL_X_Post45)
    + (CA30_LtoH_X_Post46 - CA30_LtoL_X_Post46)
    + (CA30_LtoH_X_Post47 - CA30_LtoL_X_Post47) 
    + (CA30_LtoH_X_Post48 - CA30_LtoL_X_Post48)
    + (CA30_LtoH_X_Post49 - CA30_LtoL_X_Post49)
    + (CA30_LtoH_X_Post50 - CA30_LtoL_X_Post50)
    + (CA30_LtoH_X_Post51 - CA30_LtoL_X_Post51)
    + (CA30_LtoH_X_Post52 - CA30_LtoL_X_Post52)
    + (CA30_LtoH_X_Post53 - CA30_LtoL_X_Post53)
    + (CA30_LtoH_X_Post54 - CA30_LtoL_X_Post54)
    + (CA30_LtoH_X_Post55 - CA30_LtoL_X_Post55)
    + (CA30_LtoH_X_Post56 - CA30_LtoL_X_Post56)
    + (CA30_LtoH_X_Post57 - CA30_LtoL_X_Post57)
    + (CA30_LtoH_X_Post58 - CA30_LtoL_X_Post58)
    + (CA30_LtoH_X_Post59 - CA30_LtoL_X_Post59)
    + (CA30_LtoH_X_Post60 - CA30_LtoL_X_Post60))/36;
#delimit cr

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. event studies on the two main outcomes
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in PromWLC {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. overall coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR)

    LH_minus_LL_OnlyPost, event_prefix(CA30) post_window_len(84) outcome(`var') statistics(0)
        rename coeff_`var'_gains   coeff_0
        rename quarter_`var'_gains quarter_0
        rename lb_`var'_gains      lb_0
        rename ub_`var'_gains      ub_0
    
    xlincom (coef_0yr_to_2yr = ${coef_0yr_to_2yr}) (coef_2yr_to_5yr = ${coef_2yr_to_5yr}), post
        replace coeff_0 = r(table)["b", "coef_0yr_to_2yr"] if _n==40
        replace coeff_0 = r(table)["b", "coef_2yr_to_5yr"] if _n==41
        replace lb_0    = r(table)["ll", "coef_0yr_to_2yr"] if _n==40
        replace lb_0    = r(table)["ll", "coef_2yr_to_5yr"] if _n==41
        replace ub_0    = r(table)["ul", "coef_0yr_to_2yr"] if _n==40
        replace ub_0    = r(table)["ul", "coef_2yr_to_5yr"] if _n==41

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. cohort-specific coefficients
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    forvalues i = 1/3 {

        if `i'==1 global year inrange(Event_Year, 2011, 2013)
        if `i'==2 global year inrange(Event_Year, 2014, 2016)
        if `i'==3 global year inrange(Event_Year, 2017, 2019)

        reghdfe `var' ${four_events_dummies} if ${year}, absorb(IDlse YearMonth) vce(cluster IDlseMHR)
        
        LH_minus_LL_OnlyPost, event_prefix(CA30) post_window_len(84) outcome(`var') statistics(0)
            rename coeff_`var'_gains   coeff_`i'
            rename quarter_`var'_gains quarter_`i'
            rename lb_`var'_gains      lb_`i'
            rename ub_`var'_gains      ub_`i'
            
        xlincom (coef_0yr_to_2yr = ${coef_0yr_to_2yr}) (coef_2yr_to_5yr = ${coef_2yr_to_5yr}), post
            replace coeff_`i' = r(table)["b", "coef_0yr_to_2yr"] if _n==40
            replace coeff_`i' = r(table)["b", "coef_2yr_to_5yr"] if _n==41
            replace lb_`i'    = r(table)["ll", "coef_0yr_to_2yr"] if _n==40
            replace lb_`i'    = r(table)["ll", "coef_2yr_to_5yr"] if _n==41
            replace ub_`i'    = r(table)["ul", "coef_0yr_to_2yr"] if _n==40
            replace ub_`i'    = r(table)["ul", "coef_2yr_to_5yr"] if _n==41
    }
}


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. store the event studies results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep coeff_* quarter_* lb_* ub_*

keep if inrange(_n, 1, 41)

save "${Round1Results}/CA30_Outcome5_PromWLC_DiffThreeCohorts.dta", replace 
