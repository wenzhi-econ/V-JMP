/* 
This do file constructs the distribution of age at promotion (to WL2).

Input:
    "${TempData}/FinalFullSample.dta" <== created in 0101_01 do file

Output:
    "${DescriptiveResults}/AgeWL2FT_TenureRestriction.pdf"

RA: WWZ 
Time: 2025-07-10
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. dataset for the age-at-promotion profile
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear
keep IDlse YearMonth WL AgeBand
merge 1:1 IDlse YearMonth using "${TempData}/0102_02AgeContinuous.dta", keepusing(AgeContinuous)

generate WL2 = (WL==2)
sort IDlse YearMonth
bysort IDlse: egen EverWL2 = max(cond(WL2==1, 1, 0))
keep if EverWL2==1
    //impt: keep only those employees who have ever been WL2 in the dataset

sort IDlse YearMonth
bysort IDlse: egen MinAgeContinuous_AtWL2 = min(cond(WL2==1, AgeContinuous, .))

keep IDlse MinAgeContinuous_AtWL2
duplicates drop 
    //impt: keep a cross section of employees who have ever been WL2 in the dataset

generate CA30 = (MinAgeContinuous_AtWL2<=30)
summarize CA30, detail
/* 
                            CA30
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs              33,198
25%            0              0       Sum of wgt.      33,198

50%            0                      Mean           .2637508
                        Largest       Std. dev.      .4406724
75%            1              1
90%            1              1       Variance       .1941922
95%            1              1       Skewness       1.072237
99%            1              1       Kurtosis       2.149693
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. distribution plot 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

histogram MinAgeContinuous_AtWL2 ///
    , width(1) fraction fcolor("145 179 215") lcolor(white%0) ///
    xlabel(15(5)75, grid gstyle(dot)) xtitle("Age") ///
    xline(30, lcolor("237 68 74") lpattern(dash_dot)) ///
    text(0.1 25 "Threshold age", placement(c)) ///
    ytitle("Fraction")

graph export "${DescriptiveResults}/MinAgeContinuousAtWL2.pdf", replace as(pdf)