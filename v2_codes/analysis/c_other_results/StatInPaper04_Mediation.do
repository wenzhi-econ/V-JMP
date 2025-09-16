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
                                                F(1, 2764)        =       7.22
                                                Prob > F          =     0.0073
                                                R-squared         =     0.0024
                                                Root MSE          =     .52544

                        (Std. err. adjusted for 2,765 clusters in IDMngr_Post)
------------------------------------------------------------------------------
             |               Robust
SJLatWLVe~48 | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
   CA30_LtoH |   .0651651   .0242598     2.69   0.007      .017596    .1127343
       _cons |   .2554976    .008719    29.30   0.000     .2384012    .2725941
------------------------------------------------------------------------------

Linear regression                               Number of obs     =      5,437
                                                F(2, 2764)        =     699.43
                                                Prob > F          =     0.0000
                                                R-squared         =     0.2290
                                                Root MSE          =     1.0799

                            (Std. err. adjusted for 2,765 clusters in IDMngr_Post)
----------------------------------------------------------------------------------
                 |               Robust
ChangeSalaryGr~C | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-----------------+----------------------------------------------------------------
       CA30_LtoH |   .0385878   .0530103     0.73   0.467    -.0653559    .1425315
SJLatWLVertSGC48 |   1.116842   .0299826    37.25   0.000     1.058052    1.175633
           _cons |   1.053575    .022812    46.19   0.000     1.008845    1.098305
----------------------------------------------------------------------------------
(4,437 missing values generated)
(4,437 missing values generated)
(4,437 missing values generated)
------------------------------------------------------------------------------------
        Effect                 |  Mean           [95% Conf. Interval]
-------------------------------+----------------------------------------------------
        ACME                   |  .0731586      .0194619      .1327312
        Direct Effect          |  .0359419     -.0650031      .1425057
        Total Effect           |  .1091005     -.0109014      .2229351
        % of Tot Eff mediated  |  .6431646     -2.280525      4.839945
------------------------------------------------------------------------------------
*/
    //&? A mediation analysis reveals that \checked{$64\%$} of the higher salary is explained by lateral job changes.