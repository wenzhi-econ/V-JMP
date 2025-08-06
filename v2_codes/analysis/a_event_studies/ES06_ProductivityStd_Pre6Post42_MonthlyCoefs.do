/* 
This do file runs event study regressions on the productivity outcome.
The high-flyer measure used here is CA30.

Notes:
    (1) Instead of controlling for individual and year-month fixed effects, I control for Country#YearMonth and Female#AgeBand fixed effects.
    (2) All four treatment groups are included (though Lto and Hto groups do not have same time window), while never-treated workers are not. 
    (3) The omitted group in the regressions are month -3, -2, and -1 for all four treatment groups.
    (4) For LtoL and LtoH groups, the relative time period is [-6, +84], while for HtoH and HtoL groups, the relative time period is [-6, +60]. 

RA: WWZ 
Time: 2025-07-02
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the productivity dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. new productivity variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! productivity outcomes 
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

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. sample restrictions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if ((ProductivityStd!=.))
    //impt: keep only those employees who have non-missing productivity outcomes

summarize Rel_Time, detail 
/* 
                 Relative time to the event
-------------------------------------------------------------
      Percentiles      Smallest
 1%          -14            -37
 5%           -1            -36
10%            8            -36       Obs              46,450
25%           25            -35       Sum of wgt.      46,450

50%           56                      Mean           54.80635
                        Largest       Std. dev.      35.17812
75%           84            129
90%          101            129       Variance         1237.5
95%          109            130       Skewness      -.0763767
99%          118            130       Kurtosis       1.935189
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. construct variables and macros used in reghdfe command
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

GenerateEventDummies, event_prefix(CA30) max_pre_period(6) lto_max_post(42) hto_max_post(42)
    //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
    //&? It also stores all regressors in a global macro ${four_events_dummies}.

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
local lto_max_post = 42
local hto_max_post = 42

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
    // CA30_LtoL_X_Pre_Before6 CA30_LtoL_X_Pre6 ... CA30_LtoL_X_Pre2 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post42 CA30_LtoL_X_Pre_After42 
    // CA30_LtoH_X_Pre_Before6 CA30_LtoH_X_Pre6 ... CA30_LtoH_X_Pre2 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post42 CA30_LtoH_X_Pre_After42 
    // CA30_HtoH_X_Pre_Before6 CA30_HtoH_X_Pre6 ... CA30_HtoH_X_Pre2 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post42 CA30_HtoH_X_Pre_After42 
    // CA30_HtoL_X_Pre_Before6 CA30_HtoL_X_Pre6 ... CA30_HtoL_X_Pre2 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post42 CA30_HtoL_X_Pre_After42 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. event studies on the productivity outcome
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

foreach var in ProductivityStd {

    if "`var'" == "ProductivityStd" global title "Sales bonus (s.d.)"
    if "`var'" == "ProductivityStd" global number "6"

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. Main Regression
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    reghdfe `var' ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. LtoH versus LtoL
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    *!! pre-event joint p-value
    pretrend_LH_minus_LL_Month, event_prefix(CA30) pre_window_len(6)
        global PTGain_`var' = r(pretrend)
        global PTGain_`var' = string(${PTGain_`var'}, "%4.3f")
        generate PTGain_`var' = ${PTGain_`var'} if inrange(_n, 1, 41)
            //&? store the results

    *!! monthly estimates
    LH_minus_LL_Months_90, event_prefix(CA30) pre_window_len(6) post_window_len(42) outcome(`var')
        rename (month_ProductivityStd_gains coeff_ProductivityStd_gains lb_ProductivityStd_gains ub_ProductivityStd_gains) (month_90Conf coeff_90Conf lb_90Conf ub_90Conf)
    LH_minus_LL_Month, event_prefix(CA30) pre_window_len(6) post_window_len(42) outcome(`var')
        rename (month_ProductivityStd_gains coeff_ProductivityStd_gains lb_ProductivityStd_gains ub_ProductivityStd_gains) (month_95Conf coeff_95Conf lb_95Conf ub_95Conf)

    twoway ///
        (scatter coeff_90Conf month_90Conf, lcolor(ebblue) mcolor(ebblue)) ///
        (rcap lb_90Conf ub_90Conf month_90Conf, lcolor(ebblue)) ///
        (rcap lb_95Conf ub_95Conf month_95Conf, lcolor(ebblue)) ///
        , legend(off) ///
        xline(-1, lcolor(maroon)) yline(0, lcolor(maroon)) ///
        xlabel(-6(2)42, grid gstyle(dot) labsize(medsmall)) /// 
        xtitle("Months since manager change", size(medlarge)) ///
        ylabel(-1(0.2)1, grid gstyle(dot) labsize(medsmall)) ///
        note("Pre-trends joint p-value = ${PTGain_`var'}")
    graph export "${EventStudyResults}/CA30_Outcome${number}_`var'_Coef1_Gains_90And95Confidence.pdf", replace
}

keep PTGain_ProductivityStd month_90Conf coeff_90Conf lb_90Conf ub_90Conf month_95Conf coeff_95Conf lb_95Conf ub_95Conf
keep if inrange(_n, 1, 42)
save "${EventStudyResults}/CA30_Outcome6_ProductivityStd.dta", replace