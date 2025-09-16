/* 

*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. moves 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

keep if CA30_LtoH==1
keep IDlse YearMonth Rel_Time TransferSJC TransferSJVC PromWLC

sort IDlse YearMonth
bysort IDlse: egen TransferSJC_60  = mean(cond(Rel_Time==60, TransferSJC, .))
bysort IDlse: egen TransferSJVC_60 = mean(cond(Rel_Time==60, TransferSJVC, .))
bysort IDlse: egen PromWLC_60      = mean(cond(Rel_Time==60, PromWLC, .))

keep if Rel_Time==0
generate ChangeSJ  = (TransferSJC_60  > TransferSJC)  if TransferSJC_60!=.
generate ChangeSJV = (TransferSJVC_60 > TransferSJVC) if TransferSJVC_60!=.
generate ChangeWL  = (PromWLC_60      > PromWLC)      if PromWLC_60!=.

summarize ChangeSJ ChangeSJV ChangeWL
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    ChangeSJ |      1,583    .7289956    .4446188          0          1
   ChangeSJV |      1,583    .3638661    .4812628          0          1
    ChangeWL |      1,583    .1313961    .3379398          0          1
*/


*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. movers that get promoted among the full sample
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

sort IDlse YearMonth
bysort IDlse: egen MinWL = min(WL)
keep if MinWL==1
    //impt: keep only those employees who have ever been in WL1

sort IDlse YearMonth
bysort IDlse: egen MaxWL = max(WL)
generate Promoted = (MaxWL>1)

replace TransferSJ = 0 if WL>1
    //&? ignore standard job changes after WL promotion
sort IDlse YearMonth
bysort IDlse: egen EverTransferSJ = max(TransferSJ)

summarize Promoted if EverTransferSJ==1 & occurrence==1
    //&? among a cross section of employees who have changed their standard jobs in WL1 
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |     91,127    .1006507    .3008673          0          1
*/

summarize Promoted if EverTransferSJ==0 & occurrence==1
    //&? among a cross section of employees who have never changed their standard jobs in WL1 

/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |    109,649    .0440314    .2051659          0          1
*/

ttest Promoted if occurrence==1, by(EverTransferSJ)
/* 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
       0 | 109,649    .0440314    .0006196    .2051659     .042817    .0452458
       1 |  91,127    .1006507    .0009967    .3008673    .0986973    .1026042
---------+--------------------------------------------------------------------
Combined | 200,776    .0697294    .0005684    .2546911    .0686154    .0708435
---------+--------------------------------------------------------------------
    diff |           -.0566193    .0011347               -.0588433   -.0543954
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t = -49.8995
H0: diff = 0                                     Degrees of freedom =   200774

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.0000         Pr(|T| > |t|) = 0.0000          Pr(T > t) = 1.0000
*/

regress Promoted EverTransferSJ if occurrence==1, robust
/* 

Linear regression                               Number of obs     =    200,776
                                                F(1, 200774)      =    2327.66
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0122
                                                Root MSE          =     .25313

--------------------------------------------------------------------------------
               |               Robust
      Promoted | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
---------------+----------------------------------------------------------------
EverTransferSJ |   .0566193   .0011736    48.25   0.000     .0543192    .0589195
         _cons |   .0440314   .0006196    71.07   0.000      .042817    .0452458
--------------------------------------------------------------------------------
*/

summarize Promoted if occurrence==1
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |    200,776    .0697294    .2546911          0          1

*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. movers get promoted among the event study sample (LtoH group)
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 

sort IDlse YearMonth
bysort IDlse: egen MinWL = min(WL)
keep if MinWL==1
    //impt: keep only those employees who have ever been in WL1

sort IDlse YearMonth
bysort IDlse: egen MaxWL = max(WL)
generate Promoted = (MaxWL>1)

replace TransferSJ = 0 if WL>1
    //&? ignore standard job changes after WL promotion
sort IDlse YearMonth
bysort IDlse: egen EverTransferSJ = max(TransferSJ)

summarize Promoted if EverTransferSJ==1 & occurrence==1 & CA30_LtoH==1
    //&? among a cross section of LtoH employees who have changed their standard jobs in WL1 
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |      2,744    .1454082    .3525761          0          1
*/
summarize Promoted if EverTransferSJ==1 & occurrence==1 & CA30_LtoL==1
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |     10,205    .1244488     .330109          0          1
*/

summarize Promoted if EverTransferSJ==0 & occurrence==1 & CA30_LtoH==1
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |      1,883    .0897504    .2858998          0          1
*/
summarize Promoted if EverTransferSJ==0 & occurrence==1 & CA30_LtoL==1
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    Promoted |      7,266    .0975778    .2967633          0          1
*/

ttest Promoted if EverTransferSJ==1 & occurrence==1 & ((CA30_LtoL==1)|(CA30_LtoH==1)), by(CA30_LtoH)
/* 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
       0 |  10,205    .1244488    .0032678     .330109    .1180433    .1308543
       1 |   2,744    .1454082    .0067307    .3525761    .1322104    .1586059
---------+--------------------------------------------------------------------
Combined |  12,949    .1288903    .0029447    .3350914    .1231182    .1346624
---------+--------------------------------------------------------------------
    diff |           -.0209594    .0072037               -.0350797    -.006839
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t =  -2.9095
H0: diff = 0                                     Degrees of freedom =    12947

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.0018         Pr(|T| > |t|) = 0.0036          Pr(T > t) = 0.9982
*/

ttest Promoted if EverTransferSJ==0 & occurrence==1 & ((CA30_LtoL==1)|(CA30_LtoH==1)), by(CA30_LtoH)
/* 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. err.   Std. dev.   [95% conf. interval]
---------+--------------------------------------------------------------------
       0 |   7,266    .0975778    .0034815    .2967633    .0907531    .1044024
       1 |   1,883    .0897504    .0065885    .2858998    .0768288     .102672
---------+--------------------------------------------------------------------
Combined |   9,149    .0959668    .0030796    .2945618    .0899301    .1020034
---------+--------------------------------------------------------------------
    diff |            .0078274    .0076171               -.0071038    .0227586
------------------------------------------------------------------------------
    diff = mean(0) - mean(1)                                      t =   1.0276
H0: diff = 0                                     Degrees of freedom =     9147

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.8479         Pr(|T| > |t|) = 0.3042          Pr(T > t) = 0.1521
*/



use "${TempData}/FinalFullSample.dta", clear 

sort IDlse YearMonth
bysort IDlse: egen MinTenure = min(Tenure)
keep if MinTenure<2
    //impt: keep only new hires (before collapsing the dataset into subfunction level)

bysort SubFunc YearMonth: egen SizeSF = count(IDlse)
generate one = 1 
collapse (mean) ChangeSalaryGrade TransferSJV SizeSF (sum) counts=one, by(SubFunc)

summarize TransferSJV [weight=SizeSF], detail
/* 
(analytic weights assumed)

                     (mean) TransferSJV
-------------------------------------------------------------
      Percentiles      Smallest
 1%     .0024331              0
 5%     .0032351              0
10%     .0032351              0       Obs                 126
25%     .0032351              0       Sum of wgt.  49,495.678

50%     .0064567                      Mean           .0068447
                        Largest       Std. dev.      .0036621
75%     .0096827       .0232558
90%     .0111779       .0294118       Variance       .0000134
95%     .0131147       .0338164       Skewness       1.607657
99%     .0159574       .0662252       Kurtosis       18.64803
*/