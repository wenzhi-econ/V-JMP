/* 
This do file calculates a set of statistics cited in the paper.

RA: WWZ 
Time: 2025-07-15
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. numbers related to event studies
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalAnalysisSample.dta", clear

codebook IDlseMHR if inrange(Rel_Time, -1, 0)
    //&? 14,637 managers in the event study sample 

use "${TempData}/FinalFullSample.dta", clear
sort IDlse YearMonth
bysort IDlse: egen EverWL2 = max(cond(WL==2, 1, 0))
keep if EverWL2==1
codebook IDlse
    //&? 33,198 managers who have ever been WL2

use "${TempData}/0102_03HFMeasure.dta", clear 
keep IDlseMHR CA30
duplicates drop
summarize CA30
/* 
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
        CA30 |     33,198    .2618832     .439666          0          1
*/

use "${RawMNEData}/AllSnapshotWC.dta", clear 
keep IDlse YearMonth StandardJob SubFunc 
merge 1:1 IDlse YearMonth using "${TempData}/0102_03EverWL2WorkerPanel.dta", keep(match) nogenerate
codebook IDlse


sort IDlse YearMonth
bysort IDlse: generate occurrence = _N 
bysort IDlse: generate FirstSJ = StandardJob[1]
bysort IDlse: generate FirstSF = SubFunc[1]

generate SameSJ = (FirstSJ==StandardJob)
generate SameSF = (FirstSF==SubFunc)

sort IDlse YearMonth
bysort IDlse: egen Num_SameSJ = total(SameSJ)
bysort IDlse: egen Num_SameSF = total(SameSF)

generate NoChangeSJ = (occurrence == Num_SameSJ)
generate NoChangeSF = (occurrence == Num_SameSF)

keep IDlse NoChangeSJ NoChangeSF
duplicates drop
summarize NoChangeSJ NoChangeSF



use "${TempData}/FinalAnalysisSample.dta", clear
codebook IDlse // 29,470
codebook IDlseMHR if inrange(Rel_Time, -1, 0) // 14,637

generate Event_Year = year(dofm(Event_Time))
tabulate Event_Year if Rel_Time==0, sort

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


use "${TempData}/FinalAnalysisSample.dta", clear
keep IDlse YearMonth ONETDist ONETOccTitle Func StandardJob
sort IDlse YearMonth

bysort IDlse: egen ONET_YearMonth = min(cond(ONETDist>0 & ONETDist!=., YearMonth, .))
keep if YearMonth==ONET_YearMonth | YearMonth==ONET_YearMonth-1

bysort IDlse: egen ONETDist_ind = max(ONETDist)

gsort -ONETDist_ind IDlse YearMonth
