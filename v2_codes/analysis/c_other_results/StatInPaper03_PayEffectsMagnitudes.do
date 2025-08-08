/* 
This do file calculates several statistics about the magnitude of the pay gap between the LtoH and LtoL groups.

RA: WWZ 
Time: 2025-08-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. economic magnitude of the pay effects between LtoH and LtoL groups 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

capture log close
log using "${EventStudyResults}/CA30_Outcome4_PayEffectsMagnitude.txt", replace text

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-1. PDV effects 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear

GenerateEventDummies, event_prefix(CA30) max_pre_period(24) lto_max_post(84) hto_max_post(60)
    //&? The GenerateEventDummies program generates the "event group * relative months" dummies used in the event studies.
    //&? It also stores all regressors in a global macro ${four_events_dummies}.

display "${four_events_dummies}"
    // CA30_LtoL_X_Pre_Before24 CA30_LtoL_X_Pre24 ... CA30_LtoL_X_Pre4 CA30_LtoL_X_Post0 CA30_LtoL_X_Post1 ... CA30_LtoL_X_Post84 CA30_LtoL_X_Pre_After84 
    // CA30_LtoH_X_Pre_Before24 CA30_LtoH_X_Pre24 ... CA30_LtoH_X_Pre4 CA30_LtoH_X_Post0 CA30_LtoH_X_Post1 ... CA30_LtoH_X_Post84 CA30_LtoH_X_Pre_After84 
    // CA30_HtoH_X_Pre_Before24 CA30_HtoH_X_Pre24 ... CA30_HtoH_X_Pre4 CA30_HtoH_X_Post0 CA30_HtoH_X_Post1 ... CA30_HtoH_X_Post60 CA30_HtoH_X_Pre_After60 
    // CA30_HtoL_X_Pre_Before24 CA30_HtoL_X_Pre24 ... CA30_HtoL_X_Pre4 CA30_HtoL_X_Post0 CA30_HtoL_X_Post1 ... CA30_HtoL_X_Post60 CA30_HtoL_X_Pre_After60 

reghdfe LogPayBonus ${four_events_dummies}, absorb(IDlse YearMonth) vce(cluster IDlseMHR) 
    lincom CA30_LtoH_X_Post12 - CA30_LtoL_X_Post12
        global eff_1yrLater = r(estimate)
    lincom CA30_LtoH_X_Post24 - CA30_LtoL_X_Post24
        global eff_2yrLater = r(estimate)
    lincom CA30_LtoH_X_Post36 - CA30_LtoL_X_Post36
        global eff_3yrLater = r(estimate)
    lincom CA30_LtoH_X_Post48 - CA30_LtoL_X_Post48
        global eff_4yrLater = r(estimate)
    lincom CA30_LtoH_X_Post60 - CA30_LtoL_X_Post60
        global eff_5yrLater = r(estimate)
    lincom CA30_LtoH_X_Post72 - CA30_LtoL_X_Post72
        global eff_6yrLater = r(estimate)
    lincom CA30_LtoH_X_Post84 - CA30_LtoL_X_Post84
        global eff_7yrLater = r(estimate)

display "=================================================================="
display "PDV Calculation==================================================="
display "=================================================================="

display ///
    0 + ///
    ${eff_1yrLater}/(1.05)^1 + ///
    ${eff_2yrLater}/(1.05)^2 + ///
    ${eff_3yrLater}/(1.05)^3 + ///
    ${eff_4yrLater}/(1.05)^4 + ///
    ${eff_5yrLater}/(1.05)^5 + ///
    ${eff_6yrLater}/(1.05)^6 + ///
    ${eff_7yrLater}/(1.05)^7 + ///
    ${eff_7yrLater}/(1.05)^8 + ///
    ${eff_7yrLater}/(1.05)^9 + ///
    ${eff_7yrLater}/(1.05)^10 + ///
    ${eff_7yrLater}/(1.05)^11 + ///
    ${eff_7yrLater}/(1.05)^12 + ///
    ${eff_7yrLater}/(1.05)^13 + ///
    ${eff_7yrLater}/(1.05)^14 + ///
    ${eff_7yrLater}/(1.05)^15 + ///
    ${eff_7yrLater}/(1.05)^16 + ///
    ${eff_7yrLater}/(1.05)^17 + ///
    ${eff_7yrLater}/(1.05)^18 + ///
    ${eff_7yrLater}/(1.05)^19 + ///
    ${eff_7yrLater}/(1.05)^20 + ///
    ${eff_7yrLater}/(1.05)^21 + ///
    ${eff_7yrLater}/(1.05)^22 + ///
    ${eff_7yrLater}/(1.05)^23 + ///
    ${eff_7yrLater}/(1.05)^24 + ///
    ${eff_7yrLater}/(1.05)^25 + ///
    ${eff_7yrLater}/(1.05)^26 + ///
    ${eff_7yrLater}/(1.05)^27 + ///
    ${eff_7yrLater}/(1.05)^28 + ///
    ${eff_7yrLater}/(1.05)^29
    //&? 1.6765812

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-2. a money amount in USD
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop Year
generate Year = year(dofm(YearMonth))

capture dop PayBonus
generate PayBonus = Pay + Bonus
summarize PayBonus if ISOCode =="USA" & Year==2019 & WL==1, detail 
    //&? It is measured in Euros 
    //&? 1 euro = 1.1194 dollars in 2019 (average)
    //&? The exchange rate is taken from https://fred.stlouisfed.org/series/DEXUSEU

display "=================================================================="
display "Money Amount Calculation=========================================="
display "=================================================================="

display "Calculation based on mean: "
display ${eff_7yrLater} * r(mean) * 1.1194
    //&? 11965.81

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-4-3. tenure lengths according to a mincerian-style regression 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen TenureMin = min(Tenure)

reghdfe LogPayBonus c.Tenure##c.Tenure if WL==1 & TenureMin<2, absorb(Country YearMonth) vce(cluster IDlseMHR)

global coef_0 = _b[_cons]
global coef_1 = _b[Tenure]
global coef_2 = _b[c.Tenure#c.Tenure]

display "=================================================================="
display "Tenure Equivalent Calculation====================================="
display "=================================================================="

display "The constant term in the equation: "
display ${eff_7yrLater} 
    //&? 0.13526208
display "The linear term in the equation: "
display ${coef_1} 
    //&? 0.02215986
display "The quadratic term in the equation: "
display ${coef_2} 
    //&? -0.00045828

/* 
To calculate the 7th year coefficient equivalent in the tenure regression, I solve for the following equation:
    ${coef_2} * x^2 + ${coef_1} * x = ${eff_7yrLater}, i.e.,
    -0.00045828 * x^2 + 0.02215986 * x = 0.13526208

The roots are calculated using the following Python codes:
    import numpy as np
    linear_term_tenure_regression = 0.02215986
    squared_term_tenure_regression = -0.00045828
    effect_7yrslater = 0.13526208

    coefficients = [
        squared_term_tenure_regression,
        linear_term_tenure_regression,
        -effect_7yrslater,
    ]
    roots = np.roots(coefficients)
    print(f"The roots are: {roots}")
which gives the following results:
    The roots are: [41.18854592  7.16586623]
*/

log close