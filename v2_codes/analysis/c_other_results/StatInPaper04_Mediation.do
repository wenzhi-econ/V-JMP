/* 
This do file conducts the mediation analysis.

RA: WWZ 
Time: 2025-08-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. mediation analysis
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
keep  ///
    IDlse YearMonth IDlseMHR ///
    Rel_Time Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL IDMngr_Post IDMngr_Pre ///
    StandardJob WL PromWL TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC ONETDistC
order ///
    IDlse YearMonth IDlseMHR ///
    Rel_Time Event_Time CA30_LtoL CA30_LtoH CA30_HtoH CA30_HtoL IDMngr_Post IDMngr_Pre ///
    StandardJob WL PromWL TransferSJ TransferSJC ChangeSalaryGrade ChangeSalaryGradeC ONETDistC
keep if CA30_LtoL==1 | CA30_LtoH==1
    //impt: keep only LtoL and LtoH event workers, and view LtoH event as a "treatment"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-1. create the mediator
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! standard job changes with simultaneous salary grade increases
generate SJVertSG = TransferSJ
replace  SJVertSG = 0 if ChangeSalaryGrade==0

*!! standard job changes with simultaneous salary grade increases (yet without simultaneous work level promotions)
*&? variables: SJLatWLVertSG SJLatWLVertSGC
generate SJLatWLVertSG = SJVertSG
replace  SJLatWLVertSG = 0 if PromWL==1
sort IDlse YearMonth
bysort IDlse: generate SJLatWLVertSGC = sum(SJLatWLVertSG)

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-2. mediators: 48 months after the event 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
bysort IDlse: egen SJLatWLVertSGC48 = mean(cond(Rel_Time==48, SJLatWLVertSGC, .))

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-3. keep a cross section of event workers
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

sort IDlse YearMonth
keep if Rel_Time==84 
    //impt: a cross section of LtoL and LtoH workers 
    //impt: the outcome variable is at month +84
    //&? 5,519 observations left 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-1-4. mediation analysis
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

medeff (regress SJLatWLVertSGC48 CA30_LtoH) (regress ChangeSalaryGradeC CA30_LtoH SJLatWLVertSGC48), treat(CA30_LtoH) mediate(SJLatWLVertSGC48) sims(1000) seed(7) vce(cluster IDMngr_Post)
/* 
Linear regression                               Number of obs     =      5,437
                                                F(1, 2764)        =       7.11
                                                Prob > F          =     0.0077
                                                R-squared         =     0.0023
                                                Root MSE          =     .52561

                        (Std. err. adjusted for 2,765 clusters in IDMngr_Post)
------------------------------------------------------------------------------
             |               Robust
SJLatWLVe~48 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
   CA30_LtoH |   .0647117   .0242612     2.67   0.008     .0171399    .1122836
       _cons |    .255951   .0087228    29.34   0.000     .2388471     .273055
------------------------------------------------------------------------------

Linear regression                               Number of obs     =      5,437
                                                F(2, 2764)        =     697.07
                                                Prob > F          =     0.0000
                                                R-squared         =     0.2275
                                                Root MSE          =     1.0833

                            (Std. err. adjusted for 2,765 clusters in IDMngr_Post)
----------------------------------------------------------------------------------
                 |               Robust
ChangeSalaryGr~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-----------------+----------------------------------------------------------------
       CA30_LtoH |   .0355472   .0530318     0.67   0.503    -.0684388    .1395332
SJLatWLVertSGC48 |   1.115601    .029992    37.20   0.000     1.056792     1.17441
           _cons |   1.057014   .0228762    46.21   0.000     1.012157     1.10187
----------------------------------------------------------------------------------
(4,437 missing values generated)
(4,437 missing values generated)
(4,437 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .0725713      .0189417       .132079
        Direct Effect          |  .0329003     -.0680858      .1395075
        Total Effect           |  .1054715     -.0146094      .2193216
        % of Tot Eff mediated  |  .6585831     -2.228406      5.981854
------------------------------------------------------------------------------------
*/
    //&? A mediation analysis reveals that \checked{$66\%$} of the higher salary is explained by lateral job changes.