/* 
This do file runs event study regressions on outcome: PrSJVertSG 
    (the probability of doing at least one standard job change with simultaneous salary grade increase after the event).
The high-flyer measure used here is CA30.

Special notes:
    (1) The outcome variable is only defined after the event, so there cannot be any pre-event values.

Notes on the event study regression:
    (1) Workers in the regression sample include all four event groups, while the never-treated employees are not. 
    (2) Never-treated employees are those who have ever been WL1 in the dataset and are not in any of the four event groups.
    (3) The omitted group in the regression is month 0 for all four treatment groups.
    (4) For LtoL and LtoH groups, the relative time period is [0, +84], while for HtoH and HtoL groups, the relative time period is [0, +60]. There are also binned relative time indicators at right ends.

Input: 
    "${TempData}/FinalAnalysisSample.dta"   <== created in 0103_04 do file

Output:
    "${EventStudyResults}/CA30_Outcome7_PrSJVertSG.txt"
    "${EventStudyResults}/CA30_Outcome7_PrSJVertSG.dta"

RA: WWZ 
Time: 2025-07-16
*/

capture log close
log using "${EventStudyResults}/CA30_Outcome7_PrSJVertSG", replace text

use "${TempData}/FinalAnalysisSample.dta", clear

/* keep if inrange(_n, 1, 10000)  */
    // used to test the codes
    // commented out when officially producing the results

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. construct outcome variables 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*!! ignore pre-event transfers 
replace TransferSJV = 0 if Rel_Time<0 & Rel_Time!=.

*!! re-construct the cumulative count: ignore pre-event transfers 
capture drop TransferSJVC
generate temp = TransferSJV
by IDlse (YearMonth), sort: replace temp = temp[_n] + temp[_n-1] if _n>1 
replace temp = 0 if temp==. & StandardJob!=""
generate TransferSJVC = temp 
drop temp

*!! making at least one transfer 
generate PrSJVertSG = 0 if Rel_Time<=0
replace  PrSJVertSG = (TransferSJVC>=1) if Rel_Time>0

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct global macros used in regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
//&? Month 0 is omitted as the reference group.
//&? The variable name of the "event * relative period" dummies matter!
//&? Programs stored in the 02*.do files are specifically designed for the following names.
/* Naming patterns:
For normal "event * relative period" dummies, e.g. CA30_LtoL_X_Post1 CA30_LtoH_X_Post1 CA30_HtoH_X_Post12
For binned dummies, e.g. CA30_LtoH_X_Post_After84 CA30_HtoH_X_Post_After60
*/

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. event * period dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop CA30_Rel_Time
generate CA30_Rel_Time = Rel_Time
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
*-? s-2-2. global macros used in regressions 
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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. CA30_Post variable 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate CA30_Post = (CA30_Rel_Time>=0) if CA30_Rel_Time!=.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event study regressions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in PrSJVertSG {

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-1. main regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies} if CA30_Post==1, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    LH_minus_LL_OnlyPost, event_prefix(CA30) post_window_len(84) outcome(`var')
    twoway ///
        (scatter coeff_`var'_gains quarter_`var'_gains, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_`var'_gains ub_`var'_gains quarter_`var'_gains, lcolor(ebblue)) ///
        , legend(off) ///
        xline(0, lcolor(maroon)) yline(0, lcolor(maroon)) ///
        xlabel(0(2)28, grid gstyle(dot)) ///
        xtitle("Quarters since manager change", size(medlarge)) ///
        ylabel(, grid gstyle(dot))
    graph save "${EventStudyResults}/CA30_Outcome7_`var'_Coef1_Gains.gph", replace
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-3. HtoL versus HtoH
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! quarterly estimates
    HL_minus_HH_OnlyPost, event_prefix(CA30) post_window_len(60) outcome(`var')

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? s-3-4. Testing for asymmetries
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! post-event joint p-value
    postevent_Double_Diff_OnlyPost, event_prefix(CA30) post_window_len(60)
        global postevent_`var' = r(postevent)
        global postevent_`var' = string(${postevent_`var'}, "%4.3f")
        generate postevent_`var' = ${postevent_`var'} if inrange(_n, 1, 41)

    *!! quarterly estimates
    Double_Diff_OnlyPost, event_prefix(CA30) post_window_len(60) outcome(`var')
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. store regression results
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep ///
    coeff_* quarter_* lb_* ub_* postevent_* ///
    LtoL_* LtoH_* HtoH_* HtoL_* ///
    coef1_* coefp1_* coef2_* coefp2_* coef3_* coefp3_* coef4_* coefp4_* coef5_* coefp5_* coef6_* coefp6_* ///
    RI1_* rip1_* RI2_* rip2_* RI3_* rip3_*

keep if inrange(_n, 1, 41)

save "${EventStudyResults}/CA30_Outcome7_PrSJVertSG.dta", replace 

log close 