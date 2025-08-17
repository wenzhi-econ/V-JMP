/* 
This do file runs regressions to investigate the share of high-flyer managers on past (country, function, month) performance.

RA: WWZ 
Time: 2025-06-05
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. prepare the main dataset 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. process the raw dataset
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${RawMNEData}/AllSnapshotWC.dta", clear 

keep IDlse YearMonth Country Func WL Bonus Pay

*!! classify functions into 6 categories: top 5 + others
tabulate Func
generate FuncSimpl = .
replace  FuncSimpl = 1 if Func==3
replace  FuncSimpl = 2 if Func==11
replace  FuncSimpl = 3 if Func==9
replace  FuncSimpl = 4 if Func==4
replace  FuncSimpl = 5 if Func==10
replace  FuncSimpl = 6 if FuncSimpl==.
label define FuncSimpl ///
    1 "Customer Development" ///
    2 "Supply Chain" ///
    3 "Marketing" ///
    4 "Finance" ///
    5 "Research/Development" ///
    6 "Others", replace
label value FuncSimpl FuncSimpl
tabulate FuncSimpl

*!! check countries
tabulate Country, missing
    //&? notes: some countries have very few observations
drop if missing(Country)

*!! mark WL2 observations 
generate WL2 = (WL==2)

*!! BonusPayRatio 
generate BonusPayRatio = Bonus / Pay

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. merge the HF measure to the raw dataset 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

rename IDlse IDlseMHR
merge 1:1 IDlseMHR YearMonth using "${TempData}/0102_03HFMeasure.dta"
    drop if _merge==2
    drop _merge 

generate HF = .
replace  HF = 0 if WL2==1 & CA30==0
replace  HF = 1 if WL2==1 & CA30==1

generate WL1Employee = .
replace  WL1Employee = 1 if WL==1
replace  WL1Employee = 0 if WL!=1 & WL!=.

generate WL2Employee = .
replace  WL2Employee = 1 if WL==2
replace  WL2Employee = 0 if WL!=2 & WL!=.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. reduce the dataset into country-function-month level 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

generate one = 1 
collapse (mean) HFShare=HF BonusPayRatio (sum) CellSize=one WL1Employee WL2Employee, by(Country FuncSimpl YearMonth)

sort Country FuncSimpl YearMonth
egen CellID = group(Country FuncSimpl)

sort CellID YearMonth
xtset CellID YearMonth, monthly
generate SizeGrowth = (CellSize - L.CellSize) / L.CellSize
generate WL1SizeGrowth = (WL1Employee - L.WL1Employee) / L.WL1Employee
generate WL2SizeGrowth = (WL2Employee - L.WL2Employee) / L.WL2Employee

keep  CellID YearMonth Country FuncSimpl CellSize SizeGrowth WL1SizeGrowth WL2SizeGrowth HFShare BonusPayRatio
order CellID YearMonth Country FuncSimpl CellSize SizeGrowth WL1SizeGrowth WL2SizeGrowth HFShare BonusPayRatio

label variable CellID        "ID for each (Country, FuncSimpl) combination"
label variable YearMonth     "Year-month"
label variable Country       "Country"
label variable FuncSimpl     "Function"
label variable HFShare       "Share of high-flyer managers among WL2 employees"
label variable BonusPayRatio "Average Bonus/Pay in each (Country, FuncSimpl, YearMonth) cell"
label variable CellSize      "Number of observations in each (Country, FuncSimpl, YearMonth) cell"
label variable SizeGrowth    "Employment growth rate (monthly) in each (Country, FuncSimpl) cell"
label variable WL1SizeGrowth "Work level 1 employment growth rate (monthly) in each (Country, FuncSimpl) cell"
label variable WL2SizeGrowth "Work level 2 employment growth rate (monthly) in each (Country, FuncSimpl) cell"

save "${TempData}/Corr0102_CountryFuncMonthLevel_HFShare.dta", replace

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. regressing lagged outcomes to current HF shares
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/Corr0102_CountryFuncMonthLevel_HFShare.dta", clear 

xtset CellID YearMonth, monthly 
foreach var in SizeGrowth BonusPayRatio WL1SizeGrowth WL2SizeGrowth {
    generate `var'_12mbefore = L12.`var'
    generate `var'_24mbefore = L24.`var'
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. WL1 employment growth 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe WL1SizeGrowth HFShare, absorb(Country FuncSimpl YearMonth) vce(cluster Country##FuncSimpl)
    eststo WL1SizeGrowth_0
    summarize WL1SizeGrowth if e(sample)==1
    estadd scalar cmean = r(mean)

reghdfe WL1SizeGrowth_12mbefore HFShare, absorb(Country FuncSimpl YearMonth) vce(cluster Country##FuncSimpl)
    eststo WL1SizeGrowth_12
    summarize WL1SizeGrowth if e(sample)==1
    estadd scalar cmean = r(mean)

reghdfe WL1SizeGrowth_24mbefore HFShare, absorb(Country FuncSimpl YearMonth) vce(cluster Country##FuncSimpl)
    eststo WL1SizeGrowth_24
    summarize WL1SizeGrowth if e(sample)==1
    estadd scalar cmean = r(mean)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. bonus/pay ratio
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

reghdfe BonusPayRatio HFShare, absorb(Country FuncSimpl YearMonth) vce(cluster Country##FuncSimpl)
    eststo BonusPayRatio_0
    summarize BonusPayRatio if e(sample)==1
    estadd scalar cmean = r(mean)

reghdfe BonusPayRatio_12mbefore HFShare, absorb(Country FuncSimpl YearMonth) vce(cluster Country##FuncSimpl)
    eststo BonusPayRatio_12
    summarize BonusPayRatio if e(sample)==1
    estadd scalar cmean = r(mean)

reghdfe BonusPayRatio_24mbefore HFShare, absorb(Country FuncSimpl YearMonth) vce(cluster Country##FuncSimpl)
    eststo BonusPayRatio_24
    summarize BonusPayRatio if e(sample)==1
    estadd scalar cmean = r(mean)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. produce the output table 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global latex_star         "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
global latex_begintabular "\begin{tabular}{lcccccc}"
global latex_endtabular   "\end{tabular}"
global latex_toprule      "\toprule"
global latex_midrule      "\midrule"
global latex_bottomrule   "\bottomrule"
global latex_numbers      "& \multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} & \multicolumn{1}{c}{(3)} & \multicolumn{1}{c}{(4)} & \multicolumn{1}{c}{(5)} & \multicolumn{1}{c}{(6)} \\"
global latex_outcomes     "& \multicolumn{3}{c}{Monthly employment growth (WL1)} & \multicolumn{3}{c}{Bonus/pay ratio} \\"
global latex_lines        "\cmidrule(lr){2-4} \cmidrule(lr){5-7} "
global latex_titles       "& \multicolumn{1}{c}{\shortstack{Current \\ month}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -12 months}}  & \multicolumn{1}{c}{\shortstack{Lagged \\ -24 months}} & \multicolumn{1}{c}{\shortstack{Current \\ month}} & \multicolumn{1}{c}{\shortstack{Lagged \\ -12 months}}  & \multicolumn{1}{c}{\shortstack{Lagged \\ -24 months}} \\"
global latex_file         "${OtherResults}/CA30_LaggedOutcomesAtContryFuncMonthLevelOnHFShares.tex"
global latex_equations2 WL1SizeGrowth_0 WL1SizeGrowth_12 WL1SizeGrowth_24 BonusPayRatio_0 BonusPayRatio_12 BonusPayRatio_24

esttab ${latex_equations2}  using "${latex_file}", ///
    replace style(tex) fragment nocons label nofloat nobaselevels nonumbers noobs nomtitles collabels(,none) ///
    b(4) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(HFShare) order(HFShare) varlabels(HFShare "Share of high-flyers") ///
    stats(cmean r2 N, labels("Mean" "R-squared" "N") fmt(%9.3f %9.3f %9.0g)) ///
    prehead("${latex_star}" "${latex_begintabular}" "${latex_toprule}" "${latex_toprule}") posthead("${latex_outcomes}" "${latex_lines}" "${latex_numbers}" "${latex_titles}" "${latex_midrule}") ///
    prefoot("${latex_midrule}") postfoot("${latex_bottomrule}" "${latex_bottomrule}" "${latex_endtabular}")
