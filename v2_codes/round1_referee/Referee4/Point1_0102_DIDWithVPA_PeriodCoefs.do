/* 
This do file uses VPA as an outcome in a DID-style regression.

RA: WWZ
Time: 2025-06-02
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. get the VPA variable
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear

merge 1:1 IDlse YearMonth using "${RawMNEData}/AllSnapshotWC.dta", keepusing(VPA) 
    keep if _merge==3
    drop _merge 
    //&? keep only employees in the analysis sample 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. transform the dataset into employee-year level
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

order Year YearMonth occurrence IDlse VPA
sort IDlse YearMonth

bysort IDlse Year: egen Mean_VPA = mean(VPA)
count if Mean_VPA!=VPA 
    //&? 0
    //impt: VPA is at employee-year level.
    //impt: so I need to reduce the employee-month level dataset also to employee-year level.

collapse ///
    (mean) VPA /// // outcome variable
    (mean) CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL Event_Time /// // treatment-related variables
    (max) Post_Event /// // treatment-related variable
    (last) IDlseMHR Country Female AgeBand Office Func /// // control variables
    , by(IDlse Year)

generate Event_Year = year(dofm(Event_Time))
generate Rel_Year = Year - Event_Year
/* 
. tab Rel_Year, m

   Rel_Year |      Freq.     Percent        Cum.
------------+-----------------------------------
        -10 |         25        0.01        0.01
         -9 |         60        0.03        0.05
         -8 |        125        0.07        0.12
         -7 |        210        0.12        0.24
         -6 |        407        0.24        0.48
         -5 |        686        0.40        0.87
         -4 |      1,366        0.79        1.66
         -3 |      3,061        1.77        3.43
         -2 |      7,469        4.31        7.74
         -1 |     19,390       11.20       18.94
          0 |     29,470       17.02       35.96
          1 |     24,568       14.19       50.14
          2 |     20,100       11.61       61.75
          3 |     16,276        9.40       71.15
          4 |     13,203        7.62       78.77
          5 |     10,836        6.26       85.03
          6 |      8,771        5.06       90.09
          7 |      7,028        4.06       94.15
          8 |      5,350        3.09       97.24
          9 |      3,512        2.03       99.27
         10 |      1,267        0.73      100.00
------------+-----------------------------------
      Total |    173,180      100.00
*/
generate Post_0to2     = (inrange(Rel_Year, 0, 2)) 
generate Post_2onwards = (inrange(Rel_Year, 3, 10)) 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. sample restriction 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

keep if VPA!=.
    //impt: keep only observations with non-missing VPA information.

sort IDlse Year 
bysort IDlse: egen AnyPrePeriod = min(Post_Event)
replace AnyPrePeriod = 1 - AnyPrePeriod

sort IDlse Year 
bysort IDlse: egen AnyPostPeriod = max(Post_Event)

generate BothPeriods = ((AnyPostPeriod==1) & (AnyPrePeriod==1))
    //impt: an indicator indicating that the employee has both pre- and post-event VPA information

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run DID-style regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. construct regressors used in the DID regressions  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL {
    generate `var'_X_Post = `var' * Post_Event
    generate `var'_X_Post0to2 = `var' * Post_0to2
    generate `var'_X_Post2onw = `var' * Post_2onwards

}

label variable Post_Event "Post-event"

global DID_dummies1 Post_Event CA30_LtoH_X_Post CA30_HtoH_X_Post CA30_HtoL_X_Post 
global DID_dummies2 Post_Event CA30_LtoH_X_Post0to2 CA30_HtoH_X_Post0to2 CA30_HtoL_X_Post0to2 CA30_LtoH_X_Post2onw CA30_HtoH_X_Post2onw CA30_HtoL_X_Post2onw

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. run DID-style regressions  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe VPA ${DID_dummies1}, absorb(IDlse Year) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    summarize VPA if CA30_LtoL==1 & Post_Event==0 & e(sample)==1
        local cmean = r(mean)
    xlincom (gain_1 = CA30_LtoH_X_Post) (loss_1 = CA30_HtoL_X_Post-CA30_HtoH_X_Post) (pe = Post_Event), post
        eststo VPA_All1
        estadd scalar mean_LtoL = `cmean'
        estadd scalar r_squared = `r_squared'

reghdfe VPA ${DID_dummies2}, absorb(IDlse Year) vce(cluster IDlseMHR) 
    local r_squared = e(r2)
    summarize VPA if CA30_LtoL==1 & Post_Event==0 & e(sample)==1
        local cmean = r(mean)
    xlincom (gain_2 = CA30_LtoH_X_Post0to2) (loss_2 = CA30_HtoL_X_Post0to2-CA30_HtoH_X_Post0to2) (gain_3 = CA30_LtoH_X_Post2onw) (loss_3 = CA30_HtoL_X_Post2onw-CA30_HtoH_X_Post2onw) (pe = Post_Event), post
        eststo VPA_All2
        estadd scalar mean_LtoL = `cmean'
        estadd scalar r_squared = `r_squared'

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the regression table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} \\"
global latex_outcome      "& \multicolumn{2}{c}{Outcome: Perf. scores} \\"
global latex_line         "\cmidrule(lr){2-3}"

global latex_file         "${Round1Results}/CA30_DIDOnVPAScores_TwoPeriodCoefs_OnlyLto.tex"

esttab VPA_All1 VPA_All2 using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(gain_1 gain_2 gain_3 pe) order(gain_1 gain_2 gain_3 pe) varlabels(gain_1 "(LtoH - LtoL) * Post" gain_2 "(LtoH - LtoL) * Year [0, 2]" gain_3 "(LtoH - LtoL) * Year [3, +$\infty$)" pe "Post") ///
    stats(mean_LtoL N, labels("Mean perf. scores across pre-event periods, LtoL" "N") fmt(%9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_outcome}" "${latex_line}" "${latex_numbers}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")
