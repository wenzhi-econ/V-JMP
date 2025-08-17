
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. collapse into subfunction level data
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

keep IDlse YearMonth ChangeSalaryGradeC TransferSJVC SubFunc

xtset IDlse YearMonth, monthly
sort IDlse YearMonth
bysort IDlse: generate SGC_1yrLater  = F12.ChangeSalaryGradeC
bysort IDlse: generate SJVC_1yrLater = F12.TransferSJVC

generate SG_1yr  = (SGC_1yrLater > ChangeSalaryGradeC)
generate SJV_1yr = (SJVC_1yrLater > TransferSJVC)

bysort SubFunc YearMonth: egen SizeSF = count(IDlse)

generate one = 1 
collapse (mean) ChangeSalaryGrade=SG_1yr TransferSJV=SJV_1yr SizeSF (sum) counts=one, by(SubFunc)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. average monthly lateral move rates across subfunctions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize TransferSJV [weight=SizeSF], detail
/* 
(analytic weights assumed)

                       (mean) SJV_1yr
-------------------------------------------------------------
      Percentiles      Smallest
 1%     .1537109              0
 5%     .2137245              0
10%     .2310128       .0869565       Obs                 126
25%     .2623822         .09375       Sum of wgt.  89,984.605

50%     .2660354                      Mean           .2911283
                        Largest       Std. dev.      .0943305
75%      .322141              1
90%     .3714498              1       Variance       .0088982
95%     .3785602              1       Skewness       4.469749
99%      .923656              1       Kurtosis       31.19321
*/
    local med = r(p50)
    local p25 = r(p25)
    local p75 = r(p75)
    local p99 = r(p99) // .1433902
twoway scatter TransferSJV SubFunc [weight=SizeSF] if TransferSJV<`p99' ///
    , legend(off) mcolor(ebblue) ///
    ylabel(0(0.1)1, grid gstyle(dot)) ytitle("") ///
    yline(`p25', lcolor(red)) text(0.26 150 "p25") ///
    yline(`p75', lcolor(red)) text(0.33 150 "p75") ///
    xtitle("Sub-function", size(medlarge)) ///
    note("p25=26.2%, p50=26.6%, p75=32.2%, p95=37.9%; weighted by subfunction size", size(medlarge))
graph export "${Round1Results}/AcrossSubFunc_AvgTransferSJV_1yr.pdf", replace as(pdf)

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. average monthly salary grade increase rates across subfunctions
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

summarize ChangeSalaryGrade [weight=SizeSF], detail
/* 
(analytic weights assumed)

                        (mean) SG_1yr
-------------------------------------------------------------
      Percentiles      Smallest
 1%     .2139182              0
 5%     .2789997         .09375
10%     .3023935       .1111111       Obs                 126
25%     .3238102       .1351351       Sum of wgt.  89,984.605

50%     .3376361                      Mean           .3621413
                        Largest       Std. dev.      .0911174
75%     .3907331              1
90%     .4696255              1       Variance       .0083024
95%     .4710386              1       Skewness       3.647582
99%     .9260336              1       Kurtosis       23.70586
*/
    local med = r(p50)
    local p25 = r(p25)
    local p75 = r(p75)
    local p99 = r(p99) // .0273703
twoway scatter ChangeSalaryGrade SubFunc [weight=SizeSF] if ChangeSalaryGrade<`p99' ///
    , legend(off) mcolor(ebblue) ///
    ylabel(0(0.1)1, grid gstyle(dot)) ytitle("") ///
    yline(`p25', lcolor(red)) text(0.32 150 "p25") ///
    yline(`p75', lcolor(red)) text(0.40 150 "p75") ///
    xtitle("Sub-function", size(medlarge)) ///
    note("p25=32.4%, p50=33.8%, p75=39.1%, p95=47.1%; weighted by subfunction size", size(medlarge))
graph export "${Round1Results}/AcrossSubFunc_AvgChangeSalaryGrade_1yr.pdf", replace as(pdf)