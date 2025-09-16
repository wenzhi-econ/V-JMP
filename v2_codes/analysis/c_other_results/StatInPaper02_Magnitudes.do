/* 
This do file calculates a set of statistics cited in the paper.

RA: WWZ 
Time: 2025-08-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 1. the magnitude of the effects on SJVertSGC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome1_SJVertSGC_Type1_Baseline.dta", clear

summarize RI3_SJVertSGC // .3991216
global LtoL_Q28 = coef3_SJVertSGC[1] // 
global LtoH_Q28 = coef6_SJVertSGC[1] // 
display ${LtoH_Q28}-${LtoL_Q28} // .10114366
display (${LtoH_Q28}-${LtoL_Q28})/${LtoL_Q28} // .3991216
    //&? At 28 quarters after the manager transition, the number of lateral moves are {$0.10$} higher in the $LtoH$ group than the $LtoL$ group (or a {$40\%$} increase, p-value $<0.05$).

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 2. the magnitude of the effects on LogPayBonus
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome4_PayOutcomes.dta", clear
summarize coeff_LogPayBonus_gains if quarter_LogPayBonus_gains==28 // .1330006
    //&? 7 years after the event, compared to LtoL workers, LtoH workers' total salary is 13% higher
summarize coeff_LogBonus_gains if quarter_LogBonus_gains==28 // 1.159642
    //&? The bonus increases by {116%} 7 years after the event for LtoH workers, compared with LtoL workers.

use "${TempData}/FinalFullSample.dta", clear
keep if WL==1
summarize Pay, detail 
    global mean_Pay = r(mean)
summarize Bonus, detail
    global mean_Bonus = r(mean)
display ${mean_Bonus} / ${mean_Pay} // .09525724
    //&? The bonus is around {10%} of fixed pay for work-level 1 workers.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 3. the magnitude of the effects on ProductivityStd
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
merge 1:1 IDlse YearMonth using "${TempData}/0105SalesProdOutcomes.dta", keepusing(ProductivityStd Productivity ChannelFE)
    drop if _merge==2
    drop _merge
keep ///
    Year - CA30_Post ///
    Productivity ProductivityStd LogPayBonus LogPay LogBonus TransferSJ ///
    ISOCode Female AgeBand Office Func Country
order ///
    Year - CA30_Post ///
    Productivity ProductivityStd LogPayBonus LogPay LogBonus TransferSJ ///
    ISOCode Female AgeBand Office Func Country
keep if ((ProductivityStd!=.))

GenerateEventDummies, event_prefix(CA30) max_pre_period(6) lto_max_post(84) hto_max_post(60)
macro drop CA30_LtoL_X_Pre 
macro drop CA30_LtoL_X_Post 
macro drop CA30_LtoH_X_Pre 
macro drop CA30_LtoH_X_Post 
macro drop CA30_HtoH_X_Pre 
macro drop CA30_HtoH_X_Post 
macro drop CA30_HtoL_X_Pre 
macro drop CA30_HtoL_X_Post
macro drop four_events_dummies
local max_pre_period = 6
local lto_max_post = 84
local hto_max_post = 60
foreach event in CA30_LtoL CA30_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)2 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in CA30_LtoL CA30_LtoH {
    forvalues time = 0/`lto_max_post' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`lto_max_post'
}
foreach event in CA30_HtoH CA30_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)2 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in CA30_HtoH CA30_HtoL {
    forvalues time = 0/`hto_max_post' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`hto_max_post'
}
global four_events_dummies ///
    ${CA30_LtoL_X_Pre} ${CA30_LtoL_X_Post} ///
    ${CA30_LtoH_X_Pre} ${CA30_LtoH_X_Post} ///
    ${CA30_HtoH_X_Pre} ${CA30_HtoH_X_Post} ///
    ${CA30_HtoL_X_Pre} ${CA30_HtoL_X_Post}
display "${four_events_dummies}"
    // CA30_LtoL_X_Pre_Before6 CA30_LtoL_X_Pre6 ... CA30_LtoL_X_Pre2 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Pre_Before6 CA30_LtoH_X_Pre6 ... CA30_LtoH_X_Pre2 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 
    // CA30_HtoH_X_Pre_Before6 CA30_HtoH_X_Pre6 ... CA30_HtoH_X_Pre2 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before6 CA30_HtoL_X_Pre6 ... CA30_HtoL_X_Pre2 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60

reghdfe ProductivityStd ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
xlincom (((CA30_LtoH_X_Post34 - CA30_LtoL_X_Post34) + (CA30_LtoH_X_Post35 - CA30_LtoL_X_Post35) + (CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36))/3)
/* 
------------------------------------------------------------------------------
Productivi~d | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
        lc_1 |   .3470694   .1785271     1.94   0.052    -.0034074    .6975463
------------------------------------------------------------------------------
*/
    //&? The 12th quarter estimate (the average of month 34, 35, 36 estimates) is 0.347 (p = 0.052).

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 4. the magnitude of the effects on PrSJVertSG
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome7_PrSJVertSG.dta", clear

global LtoL_Q28 = coef3_PrSJVertSG[1] 
global LtoH_Q28 = coef6_PrSJVertSG[1] 
display ${LtoH_Q28}-${LtoL_Q28} // .05942915
display (${LtoH_Q28}-${LtoL_Q28})/${LtoL_Q28} // .25079528
    //&? This probability increases by {5.9} p.p. or {25%} for the workers in the LtoH transition with respect to the workers in the LtoL transition.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 5. the magnitude of the effects on PromWLC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome5_PromWLC_YearlyAggregation.dta", clear

summarize coef_PromWLC_gains if Year_PromWLC_gains==7 // .0216984
    //&? Seven years after transitioning to a high-flyer manager (relative to transitioning to another low-flyer manager), the number of work-level promotions is {0.02} higher.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 6. the magnitude of the effects on SGRawC
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type1_Baseline.dta", clear
summarize coeff_SGRawC_gains if quarter_SGRawC_gains==28 // .174391
    //&? At 28 quarters after transitioning to a high-flyer manager (relative to transitioning to another low-flyer manager), the salary grade promotion rates are {0.17} higher ($p < 0.05$).

use "${EventStudyResults}/CA30_Outcome2_SGRawC_Type6_Poisson.dta", clear
summarize coeff_SGRawC_gains if quarter_SGRawC_gains==20 // .3342054
display exp(0.334) // 1.3965431
    //&? workers gaining a high-flyer manager have a rate of salary increases {1.4} times greater, five years post-transition (where $\hat{\beta}_{LtoH, 20} - \hat{\beta}_{LtoL, 20} = 0.334$, and $e^{0.334}=1.40$)


