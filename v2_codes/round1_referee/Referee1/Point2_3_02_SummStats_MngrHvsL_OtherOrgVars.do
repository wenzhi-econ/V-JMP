/* 
This do file investigates the correlation between managers' high-flyer status and their characteristics.

RA: WWZ 
Time: 2025-08-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. keep a panel of employees of interest 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. generate a list of managers who have been WL2 in the data
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalFullSample.dta", clear

*!! get any employee who is of WL2 at any point in the data 
generate WL2 = (WL==2) if WL!=.
sort IDlse YearMonth
bysort IDlse: egen Ever_WL2 = max(WL2)

keep if Ever_WL2==1
    //&? a panel of workers who are ever WL2 in the data 

keep IDlse
duplicates drop 

save "${TempData}/temp_EverWL2WorkerList.dta", replace 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. keep only those employees who have been observed as WL2
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalFullSample.dta", clear

merge m:1 IDlse using "${TempData}/temp_EverWL2WorkerList.dta", generate(EverWL2Worker)

keep if EverWL2Worker==3
    //&? a panel of employees who are ever WL2 in the data

label drop _merge
replace EverWL2Worker = 0 if EverWL2Worker!=3
replace EverWL2Worker = 1 if EverWL2Worker==3

label variable EverWL2Worker "Ever WL2 Workers"

drop IDlseMHR

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. get employees' high-flyer status
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename IDlse IDlseMHR
merge m:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta", keepusing(CA30) keep(match master) nogenerate 
rename IDlseMHR IDlse

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. determine whose promotion to WL2 can be observed
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
capture drop occurrence
bysort IDlse: generate occurrence = _n 
bysort IDlse: egen WL_FirstOccurrence = mean(cond(occurrence==1, WL, .))
generate q_WL2Prom = (WL_FirstOccurrence==1) if WL_FirstOccurrence!=.
    //&? since I only keep a panel of employees who have ever been WL2 in the data
    //&? if an employee's first occurrence WL is 1
    //&? then I must be able to observe his promotion to WL2

label variable q_WL2Prom "Promotion to WL2 can be observed"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. create the balance table
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

keep IDlse YearMonth SubFunc CA30 WL q_WL2Prom

sort IDlse YearMonth
bysort IDlse: egen YearMonth_FirstWL2 = min(cond(WL==2, YearMonth, .))

keep if YearMonth == YearMonth_FirstWL2
    //impt: keep the manager's subfunction at the first occurrence of WL2

merge 1:1 IDlse YearMonth using "${RawMNEData}/AllSnapshotWC.dta", keepusing(Org1 OUMaster OUGroup MCO) keep(match) nogenerate
/* 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. Org1
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate Org1, sort nolabel
/* 
    Total Cluster (9)
    Supply Chain (8)
    Category (1)
    Total PMUs (15)
    Global R&D (6)
    Enterprise and Technology Solutions (3)
    Food Solutions (4)
    Chief Marketing & Communications Office (2)
    Global Departments (5)
    Unilever Operations (16)
*/

generate Org1_9  = (Org1==9) if !missing(Org1)
generate Org1_8  = (Org1==8) if !missing(Org1)
generate Org1_1  = (Org1==1) if !missing(Org1)
generate Org1_15 = (Org1==15) if !missing(Org1)
generate Org1_6  = (Org1==6)  if !missing(Org1)
generate Org1_3  = (Org1==3) if !missing(Org1)
generate Org1_4  = (Org1==4) if !missing(Org1)
generate Org1_2  = (Org1==2) if !missing(Org1)
generate Org1_5  = (Org1==5) if !missing(Org1)
generate Org1_16 = (Org1==16) if !missing(Org1)
generate Org1_O  = 1 if !missing(Org1)
replace  Org1_O  = 0 if (Org1_9==1 | Org1_8==1 | Org1_1==1 | Org1_15==1 | Org1_6==1 | Org1_3==1 | Org1_4==1 | Org1_2==1 | Org1_5==1 | Org1_16==1)

label variable Org1_9  "Total Cluster"
label variable Org1_8  "Supply Chain"
label variable Org1_1  "Category"
label variable Org1_15 "Total PMUs"
label variable Org1_6  "Global R\&D"
label variable Org1_3  "Enterprise and Technology Solutions"
label variable Org1_4  "Food Solutions"
label variable Org1_2  "Chief Marketing \& Communications Office"
label variable Org1_5  "Global Departments"
label variable Org1_16 "Unilever Operations"
label variable Org1_O  "Other Org1"

balancetable CA30 Org1_9 Org1_8 Org1_1 Org1_15 Org1_6 Org1_3 Org1_4 Org1_2 Org1_5 Org1_16 Org1_O using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_Org1.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}") */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. OUMaster
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate OUMaster, sort generate(OU)

generate OU_sa = (OU1==1 | OU8==1 | OU9==1 | OU13==1)
generate OU_ts = (OU10==1 | OU6==1)
generate OU_sc = (OU2==1 | OU3==1 | OU5==1 | OU12==1)
generate OU_rd = (OU11==1)
generate OU_af = (OU4==1 | OU14==1)
generate OU_hr = (OU7==1)
generate OU_ot = (OU15==1 | OU16==1 | OU17==1 | OU18==1 | OU19==1 | OU20==1 | OU21==1 | OU22==1 | OU23==1)
label variable OU_af "Audit \& Finance"
label variable OU_hr "Human resources"
label variable OU_rd "R\&D"
label variable OU_sa "Sales"
label variable OU_sc "Supply chain"
label variable OU_ts "Technology solutions"
label variable OU_ot "Other divisions"

balancetable CA30 OU_af OU_hr OU_rd OU_sa OU_sc OU_ts OU_ot using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_OUMaster_Recoded.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}")
/* 
label variable OU3 "OUMaster==Foods \& Refreshment"
label variable OU4 "OUMaster==Finance \& Audit"
label variable OU5 "OUMaster==Beauty \& Personal Care"
label variable OU6 "OUMaster==Enterprise \& Technology Solutions"
label variable OU11 "OUMaster==Global R\&D"
label variable OU18 "OUMaster==Baking, Cooking \& Spreading"
label variable OU20 "OUMaster==Health \& Wellbeing"

balancetable CA30 OU1 OU2 OU3 OU4 OU5 OU6 OU7 OU8 OU9 OU10 OU11 OU12 OU13 OU14 OU15 OU16 OU17 OU18 OU19 OU20 OU21 OU22 OU23 using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_OUMaster_All.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}")


tabulate OUMaster, sort
/* 
    Total Cluster (14)
    Supply Chain (13)
    Foods & Refreshment (6)
    Finance & Audit (5)
    Beauty & Personal Care (1)
    Enterprise & Technology Solutions (4)
    Human Resources (9)
    Cross-Category (3)
    CMCO (2)
    Markets Organisation (22)
*/

generate OUMaster_14 = (OUMaster==14) if !missing(OUMaster)
generate OUMaster_13 = (OUMaster==13) if !missing(OUMaster)
generate OUMaster_6  = (OUMaster==6)  if !missing(OUMaster)
generate OUMaster_5  = (OUMaster==5)  if !missing(OUMaster)
generate OUMaster_1  = (OUMaster==1)  if !missing(OUMaster)
generate OUMaster_4  = (OUMaster==4)  if !missing(OUMaster)
generate OUMaster_9  = (OUMaster==9)  if !missing(OUMaster)
generate OUMaster_3  = (OUMaster==3)  if !missing(OUMaster)
generate OUMaster_2  = (OUMaster==2)  if !missing(OUMaster)
generate OUMaster_22 = (OUMaster==22) if !missing(OUMaster)
generate OUMaster_O  = 1 if !missing(OUMaster)
replace  OUMaster_O  = 0 if (OUMaster_14==1 | OUMaster_13==1 | OUMaster_6==1 | OUMaster_5==1 | OUMaster_1==1 | OUMaster_4==1 | OUMaster_9==1 | OUMaster_3==1 | OUMaster_2==1 | OUMaster_22==1)


label variable OUMaster_14  "Total Cluster"
label variable OUMaster_13  "Supply Chain"
label variable OUMaster_6   "Foods \& Refreshment"
label variable OUMaster_5   "Finance \& Audit"
label variable OUMaster_1   "Beauty \& Personal Care"
label variable OUMaster_4   "Enterprise \& Technology Solutions"
label variable OUMaster_9   "Human Resources"
label variable OUMaster_3   "Cross-Category"
label variable OUMaster_2   "CMCO"
label variable OUMaster_22  "Markets Organisation"
label variable OUMaster_O   "Other OUMaster"

balancetable CA30 OUMaster_14 OUMaster_13 OUMaster_6 OUMaster_5 OUMaster_1 OUMaster_4 OUMaster_9 OUMaster_3 OUMaster_2 OUMaster_22 OUMaster_O using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_OUMaster.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}") */
/* 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-3. OUGroup
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate OUGroup, sort
/* 
    Europe (12)
    Finance - Total Cluster (23)
    Information Technology (43)
    Food Solutions (25)
    Cross-Category (10)
    North America (52)
    Europe SC (13)
    Procurement (60)
    South Asia (67)
    North Asia (54)
*/

generate OUGroup_12 = (OUGroup==12) if !missing(OUGroup)
generate OUGroup_23 = (OUGroup==23) if !missing(OUGroup)
generate OUGroup_43 = (OUGroup==43) if !missing(OUGroup)
generate OUGroup_25 = (OUGroup==25) if !missing(OUGroup)
generate OUGroup_10 = (OUGroup==10) if !missing(OUGroup)
generate OUGroup_52 = (OUGroup==52) if !missing(OUGroup)
generate OUGroup_13 = (OUGroup==13) if !missing(OUGroup)
generate OUGroup_60 = (OUGroup==60) if !missing(OUGroup)
generate OUGroup_67 = (OUGroup==67) if !missing(OUGroup)
generate OUGroup_54 = (OUGroup==54) if !missing(OUGroup)
generate OUGroup_O  = 1 if !missing(OUGroup)
replace  OUGroup_O  = 0 if (OUGroup_12==1 | OUGroup_23==1 | OUGroup_43==1 | OUGroup_25==1 | OUGroup_10==1 | OUGroup_52==1 | OUGroup_13==1 | OUGroup_60==1 | OUGroup_67==1 | OUGroup_54==1)

label variable OUGroup_12   "Europe"
label variable OUGroup_23   "Finance - Total Cluster"
label variable OUGroup_43   "Information Technology"
label variable OUGroup_25   "Food Solutions"
label variable OUGroup_10   "Cross-Category"
label variable OUGroup_52   "North America"
label variable OUGroup_13   "Europe SC"
label variable OUGroup_60   "Procurement"
label variable OUGroup_67   "South Asia"
label variable OUGroup_54   "MNorth Asia"
label variable OUGroup_O    "Other OUGroup"

balancetable CA30 OUGroup_12 OUGroup_23 OUGroup_43 OUGroup_25 OUGroup_10 OUGroup_52 OUGroup_13 OUGroup_60 OUGroup_67 OUGroup_54 OUGroup_O using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_OUGroup.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}") */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-4. MCO
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

tabulate MCO, sort
/* 
    UK & Ireland (35)
    North America (24)
    India (13)
    Benelux (3)
    China (6)
    DACH (7)
    Brazil (4)
    CEE (5)
    Southern Africa (29)
    Malaysia Singapore & MCL (19)
*/
generate MCO_35 = (MCO==35) if !missing(MCO)
generate MCO_24 = (MCO==24) if !missing(MCO)
generate MCO_13 = (MCO==13) if !missing(MCO)
generate MCO_3  = (MCO==3)  if !missing(MCO)
generate MCO_6  = (MCO==6)  if !missing(MCO)
generate MCO_7  = (MCO==7)  if !missing(MCO)
generate MCO_4  = (MCO==4)  if !missing(MCO)
generate MCO_5  = (MCO==5)  if !missing(MCO)
generate MCO_29 = (MCO==29) if !missing(MCO)
generate MCO_19 = (MCO==19) if !missing(MCO)
generate MCO_O  = 1 if !missing(MCO)
replace  MCO_O  = 0 if (MCO_35==1 | MCO_24==1 | MCO_13==1 | MCO_3==1 | MCO_6==1 | MCO_7==1 | MCO_4==1 | MCO_5==1 | MCO_29==1 | MCO_19==1)

generate MCO_EU = (MCO_3==1 | MCO_5==1 | MCO_7==1 | MCO_35==1)

label variable MCO_4    "Brazil"
label variable MCO_6    "China"
label variable MCO_EU   "Europe"
label variable MCO_13   "India"
label variable MCO_19   "Malaysia \& Singapore"
label variable MCO_24   "North America"
label variable MCO_29   "Southern Africa"
label variable MCO_O    "Other geography"

balancetable CA30 MCO_4 MCO_6 MCO_EU MCO_13 MCO_19 MCO_24 MCO_29 MCO_O using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_MCO_Recoded.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}")

/* 
balancetable CA30 MCO_35 MCO_24 MCO_13 MCO_3 MCO_6 MCO_7 MCO_4 MCO_5 MCO_29 MCO_19 MCO_O using "${Round1Results}/CA30_SummaryStatistics_MngrHvsL_MCO.tex", ///
    replace pvalues varlabels vce(cluster IDlse) ctitles("Low-flyers" "High-flyers" "Difference")   ///
    nolines nonumbers ///
    prehead("\begin{tabular}{lccc}" "\toprule \toprule") ///
    posthead("& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} \\" "\midrule") ///
    prefoot("\midrule") ///
    postfoot("\bottomrule \bottomrule" "\end{tabular}") */

