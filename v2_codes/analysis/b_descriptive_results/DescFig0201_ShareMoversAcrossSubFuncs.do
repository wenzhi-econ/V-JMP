/* 
This do file plots the average monthly move rates across subfunctions.

Input:
    "${TempData}/FinalFullSample.dta" <== created in 0101 do file 

Results:
    "${Results}/AvgLateralMoveRatesAcrossSubfunctions.pdf"
    "${Results}/AvgSalaryGradeIncreaseRatesAcrossSubfunctions.pdf"

RA: WWZ 
Time: 2024-07-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. collapse into subfunction level data
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

bysort SubFunc YearMonth: egen SizeSF = count(IDlse)

generate one = 1 
collapse (mean) ChangeSalaryGrade TransferSJV SizeSF (sum) counts=one, by(SubFunc)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. average monthly lateral move rates across subfunctions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize TransferSJV [weight=SizeSF], detail
    local med = r(p50)
    local p25 = r(p25)
    local p75 = r(p75)
    local p99 = r(p99) // .1433902
twoway scatter TransferSJV SubFunc [weight=SizeSF] if TransferSJV<`p99' ///
    , legend(off) mcolor(ebblue) ///
    ylabel(, grid gstyle(dot)) ytitle("") ///
    yline(`p25', lcolor(red)) text(0.002 150 "p25") ///
    yline(`p75', lcolor(red)) text(0.007 150 "p75") /// // yline(`med', lcolor(red)) text(0.025 125 "p50") ///
    xtitle("Sub-function", size(medlarge)) ///
    note("p25=0.3%, p50=0.4%, p75=0.7%, p95=1.0%; weighted by subfunction size", size(medlarge))
    /* title("Average monthly probability of lateral moves", size(medlarge)) /// */
graph export "${DescriptiveResults}/AcrossSubFunc_AvgTransferSJV.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. average monthly salary grade increase rates across subfunctions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize ChangeSalaryGrade [weight=SizeSF], detail
    local med = r(p50)
    local p25 = r(p25)
    local p75 = r(p75)
    local p99 = r(p99) // .0273703
twoway scatter ChangeSalaryGrade SubFunc [weight=SizeSF] if ChangeSalaryGrade<`p99' ///
    , legend(off) mcolor(ebblue) ///
    ylabel(0(0.005)0.03, grid gstyle(dot)) ytitle("") ///
    yline(`p25', lcolor(red)) text(0.009 150 "p25") ///
    yline(`p75', lcolor(red)) text(0.018 150 "p75") ///
    xtitle("Sub-function", size(medlarge)) ///
    note("p25=1.00%, p50=1.28%, p75=1.68%, p95=2.14%; weighted by subfunction size", size(medlarge))
    /* title("Average monthly probability of salary grade increases", size(medlarge)) /// */
graph export "${DescriptiveResults}/AcrossSubFunc_AvgChangeSalaryGrade.pdf", replace as(pdf)

/* *??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. probability of making a lateral move and salary grade increase
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

*-? s-4-1. consider only new hires

sort IDlse YearMonth
bysort IDlse: egen MinTenure = min(Tenure)
keep if MinTenure<2
    //impt: keep only those new hires

*-? s-4-2. who are observable within 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 years later

sort IDlse YearMonth
bysort IDlse: egen MinYearMonth = min(YearMonth)
bysort IDlse: egen MaxYearMonth = max(YearMonth)

generate SpanYearMonth = MaxYearMonth - MinYearMonth

forvalues i = 1/10 {
    local j = 12 * `i'
    generate Available_Year`i' = SpanYearMonth >= `j'
}

*-? s-4-3. does the worker change his job or salary grade within a given year 

sort IDlse YearMonth
forvalues i = 1/10 {
    local j = 12 * `i'
    bysort IDlse: egen TransferSJ_Year`i' = max(cond(inrange(occurrence, 0, `j'), TransferSJ, .))
}

sort IDlse YearMonth
forvalues i = 1/10 {
    local j = 12 * `i'
    bysort IDlse: egen ChangeSalaryGrade_Year`i' = max(cond(inrange(occurrence, 0, `j'), ChangeSalaryGrade, .))
}

*-? s-4-4. final calculation 

keep if occurrence==1
    //impt: keep a cross section of new hires 

keep IDlse Available_Year1 - ChangeSalaryGrade_Year10

forvalues i = 1/10 {
    replace TransferSJ_Year`i' = . if Available_Year`i'==0
    replace ChangeSalaryGrade_Year`i' = . if Available_Year`i'==0
}

summarize TransferSJ_Year1, detail // mean: .2343052, obs: 98,265
summarize TransferSJ_Year2, detail // mean: .4682395, obs: 75,109
summarize TransferSJ_Year3, detail // mean: .669548, obs: 56,686
summarize TransferSJ_Year4, detail // mean: .7538703, obs: 42,116
summarize TransferSJ_Year5, detail // mean: .806171, obs: 32,183
summarize TransferSJ_Year6, detail // mean: .8482611, obs: 24,239
summarize TransferSJ_Year7, detail // mean: .8869137, obs: 18,057
summarize TransferSJ_Year8, detail // mean: .9265385, obs: 13,422
summarize TransferSJ_Year9, detail // mean: .9393972, obs: 9,257
summarize TransferSJ_Year10, detail // mean: .9440406, obs: 5,915

summarize ChangeSalaryGrade_Year1, detail // mean: .1291915, obs: 98,265
summarize ChangeSalaryGrade_Year2, detail // mean: .3072069, obs: 75,109
summarize ChangeSalaryGrade_Year3, detail // mean: .4726211, obs: 56,686
summarize ChangeSalaryGrade_Year4, detail // mean: .5964004, obs: 42,116
summarize ChangeSalaryGrade_Year5, detail // mean: .6741137, obs: 32,183
summarize ChangeSalaryGrade_Year6, detail // mean: .7187178, obs: 24,239
summarize ChangeSalaryGrade_Year7, detail // mean: .758044, obs: 18,057
summarize ChangeSalaryGrade_Year8, detail // mean: .8001788, obs: 13,422
summarize ChangeSalaryGrade_Year9, detail // mean: .8252134, obs: 9,257
summarize ChangeSalaryGrade_Year10, detail // mean: .8307692, obs: 5,915 */