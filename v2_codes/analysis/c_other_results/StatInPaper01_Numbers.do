/* 
This do file calculates a set of statistics cited in the paper.

RA: WWZ 
Time: 2025-08-07
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 1. the share of high-flyer managers
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/0102_03HFMeasure.dta", clear
codebook IDlseMHR
sort IDlseMHR YearMonth
bysort IDlseMHR: egen ind_CA30 = max(CA30)
bysort IDlseMHR: generate occurrence = _n 
count if ind_CA30==1 & occurrence==1 // 8,694
summarize ind_CA30 if occurrence==1
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    ind_CA30 |     33,198    .2618832     .439666          0          1
*/
    //&? Among 33,198 managers of interest (those who have ever been WL2 in the data), 8,694 are high-flyer managers, i.e., about 26.2\% are high-flyers.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 2. description of the full sample 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-1. number of functions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalFullSample.dta", clear 
tabulate Func, sort missing
/* 
                 Function |      Freq.     Percent        Cum.
--------------------------+-----------------------------------
     Customer Development |  4,001,982       39.69       39.69
             Supply Chain |  2,536,338       25.15       64.84
                Marketing |    901,642        8.94       73.78
                  Finance |    829,550        8.23       82.01
     Research/Development |    807,566        8.01       90.02
          Human Resources |    342,467        3.40       93.41
   Information Technology |    245,296        2.43       95.85
       General Management |    148,344        1.47       97.32
       Workplace Services |    120,059        1.19       98.51
                    Legal |     64,526        0.64       99.15
           Communications |     40,555        0.40       99.55
Information and Analytics |     20,484        0.20       99.75
               Operations |      8,127        0.08       99.83
                    Audit |      6,740        0.07       99.90
         Data & Analytics |      4,872        0.05       99.95
       Data and Analytics |      3,826        0.04       99.99
       Project Management |      1,251        0.01      100.00
                    UNKNW |         13        0.00      100.00
--------------------------+-----------------------------------
                    Total | 10,083,638      100.00
*/
    //&? 16 different functions: 
    //&? "Data & Analytics" and "Data and Analytics" is one function
    //&? "UNKNW" should be taken as missing values

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-2-2. size of subfunctions
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalFullSample.dta", clear 

capture drop Size_SubFunc
sort SubFunc YearMonth IDlse
bysort SubFunc YearMonth: egen Size_SubFunc = count(IDlse)

egen tag_SubFunc_YM = tag(SubFunc YearMonth)
summarize Size_SubFunc if tag_SubFunc_YM==1, detail
/* 
                        Size_SubFunc
-------------------------------------------------------------
      Percentiles      Smallest
 1%            2              1
 5%            7              1
10%           16              1       Obs              10,974
25%           67              1       Sum of wgt.      10,974

50%          240                      Mean           918.8662
                        Largest       Std. dev.      2595.251
75%          788          24291
90%         2103          24330       Variance        6735328
95%         3080          24355       Skewness       7.124653
99%        21235          24523       Kurtosis       58.83218
*/
    //&? The median size of a sub-function is {240} workers, the 10th percentile is {16} workers and the 90th percentile is {2103} workers.

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. number of distinct job titles
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

use "${TempData}/FinalFullSample.dta", clear

codebook StandardJob if WL==1
    // Unique values: 992 
    //&? There are almost \checked{1,000} horizontally differentiated job titles within the firm among work level 1 employees.

sort IDlseMHR YearMonth IDlse
bysort IDlseMHR YearMonth: egen Size_StandardJob = nvals(StandardJob)

egen tag_Mngr_YM = tag(IDlseMHR YearMonth)
summarize Size_StandardJob if tag_Mngr_YM==1, detail
/* 
                      Size_StandardJob
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              1
 5%            1              1
10%            1              1       Obs           2,015,771
25%            1              1       Sum of wgt.   2,015,771

50%            2                      Mean            1.98061
                        Largest       Std. dev.      1.439259
75%            2             39
90%            4             40       Variance       2.071467
95%            5             42       Skewness       2.726959
99%            7             55       Kurtosis       18.12677
*/
    //&? On average, there are \checked{two} distinct job titles in a team supervised by the same manager.

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? 3. numbers related to event studies
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear 
    //&? total employee-month level obs: 1,884,145

codebook IDlse // Unique values: 29,470
codebook IDlseMHR if inrange(Rel_Time, -1, 0) // Unique values: 14,637 
    //&? The event-study data comprises {29,470} transition events, involving {29,470} unique workers and {14,637} unique managers.

generate Event_Year = year(dofm(Event_Time))
tabulate Event_Year if Rel_Time==0
/* 
 Event_Year |      Freq.     Percent        Cum.
------------+-----------------------------------
       2011 |      3,685       12.50       12.50
       2012 |      6,774       22.99       35.49
       2013 |      4,289       14.55       50.04
       2014 |      2,701        9.17       59.21
       2015 |      2,238        7.59       66.80
       2016 |      1,966        6.67       73.47
       2017 |      1,596        5.42       78.89
       2018 |      1,821        6.18       85.07
       2019 |      1,503        5.10       90.17
       2020 |      1,085        3.68       93.85
       2021 |      1,812        6.15      100.00
------------+-----------------------------------
      Total |     29,470      100.00
*/
    //&? Events occur every year but the majority of them take place in the first three years of the panel (2011-2013) since I only consider the first manager transition.

count if Rel_Time==0 
    //&? number of workers: 29,470
count if Rel_Time==0 & CA30_LtoL==1
    //&? number of LtoL events: 18,242
count if Rel_Time==0 & CA30_LtoH==1
    //&? number of LtoH events: 4,757
count if Rel_Time==0 & CA30_HtoH==1
    //&? number of HtoH events: 3,339
count if Rel_Time==0 & CA30_HtoL==1
    //&? number of HtoL events: 3,132

display 3339 / 29470
    //&? .11330166 of events are HtoH

sort IDlse YearMonth
bysort IDlse: egen TenureMin = min(Tenure)
codebook IDlse if TenureMin<2 
    //&? 18,830 event workers in the new hires robustness
display 18830 / 29470
