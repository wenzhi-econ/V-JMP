/* 
This do file analyzes the self-reported survey outcomes.

Notes:
    (1) The level of analysis is employee-month, even though the survey is administrated only once in each year in September.
    (2) The survey asked about the whole year's experience, which gives different weights to different managers a worker experienced in any year.
    (3) The correlation is between contemporaneous manager's high-flyer status (monthly frequency), and the survey outcomes (yearly frequency).

Input:
    "${TempData}/04MainOutcomesInEventStudies.dta" <== created in 0104 do file 
    "${RawMNEData}/UniVoice.dta"                   <== raw data 

Results:
    "${OtherResults}/CA30_SelfReportedSurveyOutcomes_PCAAndMean.tex"
    "${OtherResults}/CA30_SelfReportedSurveyOutcomes_HeteroByTransfer.tex"

RA: WWZ
Time: 2025-06-02
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. create a relevant dataset
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-0. generate variables used further  
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalAnalysisSample.dta", clear 

*!! mark if the employee makes any lateral transfer after the event
sort IDlse YearMonth
bysort IDlse: egen maxTransfer = max(cond(Post_Event==1, TransferSJ, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. merge the survey dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

global SurveyVars ///
    LineManager Inclusive TeamAgility TrustLeadership LeadershipInclusion HeartCustomers ///
    WorkLifeBalance Satisfied Refer Proud LivePurpose Leaving ExtraMile ///
    AccessLearning PrioritiseControl DevOpportunity Wellbeing ReportUnethical ///
    StrategyWin USLP GoodTechnologies Competition EffectiveBarriers Integrity RecommendProducts

*!! merge the survey outcomes
merge m:1 IDlse Year using "${RawMNEData}/UniVoice.dta", keepusing(${SurveyVars})
//impt: merge based on IDlse and Year, even though the survey data is only in September.
    rename _merge _mergeSurvey
    keep if _mergeSurvey==3

*!! merge the managers' characteristics
merge m:1 IDlseMHR YearMonth using "${TempData}/0104Mngr_Characteristics.dta", keepusing(WLM)
    keep if _merge==3
    drop _merge 

*!! merge the managers' high-flyer status
merge m:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta", keepusing(CA30) 
    keep if _merge==3
    drop _merge 

*!! keep only relevant variables
keep ///
    IDlse Year YearMonth IDlseMHR CA30 WLM ///
    AgeBand Female Country maxTransfer Office Func ///
    Post_Event Rel_Time Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    $SurveyVars

order ///
    IDlse Year YearMonth IDlseMHR CA30 WLM ///
    AgeBand Female Country maxTransfer ///
    Post_Event Rel_Time Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL ///
    $SurveyVars

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. generate outcomes of interest (variable aggregation) 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! transform into binary variables 
foreach var in $SurveyVars {
	generate `var'B = 0
	replace  `var'B = 1 if `var'>=5
	replace  `var'B = . if `var'==.
}

*!! pca to get the first component
global Uteampc    LineManagerB InclusiveB TeamAgilityB TrustLeadershipB LeadershipInclusionB HeartCustomersB
global Uhappypc   WorkLifeBalanceB SatisfiedB ReferB ProudB LivePurposeB LeavingB ExtraMileB   
global Ufocuspc   AccessLearningB PrioritiseControlB DevOpportunityB WellbeingB ReportUnethicalB
global Ucompanypc StrategyWinB USLPB GoodTechnologiesB CompetitionB EffectiveBarriersB IntegrityB RecommendProductsB
foreach group in Uteampc Uhappypc Ufocuspc Ucompanypc {
    pca ${`group'}
    predict `group'1, score 
    egen `group'Mean = rowmean($`group')
}

*!! outcome variables of interest 
label variable Uteampc1       "Team Effectiveness"
label variable Ufocuspc1      "Autonomy"
label variable Uhappypc1      "Job Satisfaction"
label variable Ucompanypc1    "Company Effectiveness"
label variable UteampcMean    "Team Effectiveness"
label variable UfocuspcMean   "Autonomy"
label variable UhappypcMean   "Job Satisfaction"
label variable UcompanypcMean "Company Effectiveness"
label variable LineManagerB   "Effective Leader"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. generate other variables
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! a consistent regression sample 
generate SurveySample = ((LineManagerB!=.) & (Uteampc1!=.) & (Ufocuspc1!=.) & (Uhappypc1!=.) & (Ucompanypc1!=.))

*!! interact lateral job movers with manager's high-flyer status 
generate CA30_X_maxTransfer = CA30 * maxTransfer
label variable CA30_X_maxTransfer "High-flyer manager $\times$ worker changed job"

save "${TempData}/SurveyTab0101_SurveyOutcomesAgainstHF.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. run regressions 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/SurveyTab0101_SurveyOutcomesAgainstHF.dta", clear

label variable CA30 "High-flyer manager"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. using the pca-generated outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

eststo clear 
foreach var in LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 { 
    reghdfe `var' CA30 if Post_Event==1 & WLM==2 & SurveySample==1, cluster(IDlseMHR) absorb(AgeBand##Female Year Office##Func)
        eststo `var'
        summarize `var' if (e(sample)==1 & Post_Event==1 & CA30==0 & WLM==2), detail
        estadd scalar Mean = r(mean)	
}
esttab LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. using the mean-generated outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean { 
    reghdfe `var' CA30 if Post_Event==1 & WLM==2 & SurveySample==1, cluster(IDlseMHR) absorb(AgeBand##Female Year Office##Func)
        eststo `var'
        summarize `var' if (e(sample)==1 & Post_Event==1 & CA30==0 & WLM==2), detail
        estadd scalar Mean = r(mean)	
}
esttab LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. does standard job change matters
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

foreach var in LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean { 
    reghdfe `var' CA30 maxTransfer CA30_X_maxTransfer if Post_Event==1 & WLM==2 & SurveySample==1, cluster(IDlseMHR) absorb(AgeBand##Female Year Office##Func)
        eststo `var'_Heter
        summarize `var' if (e(sample)==1 & CA30==0 & Post_Event==1 & WLM==2), detail
        estadd scalar Mean = r(mean)
}

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the table  
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-3-1. using the mean of the raw outcome variables 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

esttab LineManagerB UteampcMean UfocuspcMean UhappypcMean UcompanypcMean using "${OtherResults}/CA30_SelfReportedSurveyOutcomes_PCAAndMean.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30) ///
    order(CA30) ///
    b(3) se(2) ///
    stats(r2 Mean N, labels("R-squared" "Mean, low-flyers" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Effective Leader} & \multicolumn{1}{c}{Team Effectiveness} & \multicolumn{1}{c}{Job Satisfaction} & \multicolumn{1}{c}{Autonomy} & \multicolumn{1}{c}{Company Effectiveness} \\ ") ///
    posthead("\midrule \\ [-10pt]" "\multicolumn{6}{c}{\emph{Panel (a): using averages for the indices}} \\ [5pt]") ///
    prefoot("\midrule") ///
    postfoot("")

esttab LineManagerB Uteampc1 Ufocuspc1 Uhappypc1 Ucompanypc1 using "${OtherResults}/CA30_SelfReportedSurveyOutcomes_PCAAndMean.tex", ///
    append style(tex) fragment nocons label nofloat nobaselevels noobs nonumbers ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30) ///
    order(CA30) ///
    b(3) se(2) ///
    stats(r2 Mean N, labels("R-squared" "Mean, low-flyers" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("") ///
    posthead("\midrule \\ [-10pt]" "\multicolumn{6}{c}{\emph{Panel (b): using the first component of PCA for the indices}} \\ [5pt]") ///
    prefoot("\midrule")  ///
    postfoot("\midrule" "\midrule" "\end{tabular}")


esttab LineManagerB_Heter UteampcMean_Heter UfocuspcMean_Heter UhappypcMean_Heter UcompanypcMean_Heter using "${OtherResults}/CA30_SelfReportedSurveyOutcomes_HeteroByTransfer.tex", ///
    replace style(tex) fragment nocons label nofloat nobaselevels noobs ///
    nomtitles collabels(,none) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(CA30 CA30_X_maxTransfer) ///
    order(CA30 CA30_X_maxTransfer) ///
    b(3) se(2) ///
    stats(r2 Mean N, labels("R-squared" "Mean, low-flyers" "Obs") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" "\begin{tabular}{lccccc}" "\toprule" "\toprule" "& \multicolumn{1}{c}{Effective Leader} & \multicolumn{1}{c}{Team Effectiveness} & \multicolumn{1}{c}{Job Satisfaction} & \multicolumn{1}{c}{Autonomy} & \multicolumn{1}{c}{Company Effectiveness} \\ ") ///
    posthead("\midrule") ///
    prefoot("\midrule") ///
    postfoot("\midrule" "\midrule" "\end{tabular}")
