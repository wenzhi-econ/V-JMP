/* 
This do file plots the average lateral move rates across subfunctions in 2019.

RA: WWZ 
Time: 2025-08-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. aggregate subfunctions based on their sizes 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

use "${TempData}/FinalFullSample.dta", clear 

keep IDlse Year YearMonth TransferSJ TransferSJV SubFunc Func
keep if Year==2019

tab SubFunc, sort
/* 
Top 11:
    Customer Management (13)
    Make (37) = Supply Chain
    Marketing Category (39)
    Finance Business Partnering (22)
    Logistics (35)
    Planning (50)
    Product Development (53)
    CD Excellence (4) = Consumer Relations
    Customer and Account Management (14)
    Procurement (52)
    Engineering (17)
*/

label list SubFunc

generate SubFunc_13 = (SubFunc==13) if !missing(SubFunc)
generate SubFunc_37 = (SubFunc==37) if !missing(SubFunc)
generate SubFunc_39 = (SubFunc==39) if !missing(SubFunc)
generate SubFunc_22 = (SubFunc==22) if !missing(SubFunc)
generate SubFunc_35 = (SubFunc==35) if !missing(SubFunc)
generate SubFunc_50 = (SubFunc==50) if !missing(SubFunc)
generate SubFunc_53 = (SubFunc==53) if !missing(SubFunc)
generate SubFunc_4  = (SubFunc==4) if !missing(SubFunc)
generate SubFunc_14 = (SubFunc==14) if !missing(SubFunc)
generate SubFunc_52 = (SubFunc==52) if !missing(SubFunc)
generate SubFunc_17 = (SubFunc==17) if !missing(SubFunc)
generate SubFunc_O  = 1 if !missing(SubFunc)
replace  SubFunc_O  = 0 if (SubFunc_13==1 | SubFunc_37==1 | SubFunc_39==1 | SubFunc_22==1 | SubFunc_35==1 | SubFunc_50==1 | SubFunc_53==1 | SubFunc_4==1 | SubFunc_14==1 | SubFunc_52==1 | SubFunc_17==1)

generate SubFuncAgg = . 
replace  SubFuncAgg = 1  if SubFunc_4==1
replace  SubFuncAgg = 2  if SubFunc_14==1
replace  SubFuncAgg = 3  if SubFunc_13==1
replace  SubFuncAgg = 4  if SubFunc_17==1
replace  SubFuncAgg = 5  if SubFunc_22==1
replace  SubFuncAgg = 6  if SubFunc_35==1
replace  SubFuncAgg = 7  if SubFunc_39==1
replace  SubFuncAgg = 8  if SubFunc_50==1
replace  SubFuncAgg = 9  if SubFunc_52==1
replace  SubFuncAgg = 10 if SubFunc_53==1
replace  SubFuncAgg = 11 if SubFunc_37==1
replace  SubFuncAgg = 12 if SubFunc_O ==1

label define SubFuncAgg ///
    1  "Consumer Relations" ///
    2  "Customer and Account Management" ///
    3  "Customer Management" ///
    4  "Engineering" ///
    5  "Finance Business Partnering" ///
    6  "Logistics" ///
    7  "Marketing Category" ///
    8  "Planning" ///
    9  "Procurement" ///
    10 "Product Development" ///
    11 "Supply chain" ///
    12 "Others"
label values SubFuncAgg SubFuncAgg

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. plotting subfunction-level average SJVertSG rates
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

generate Month = month(dofm(YearMonth))
collapse (mean) ShareSJ=TransferSJ ShareSJV=TransferSJV, by(Month SubFuncAgg)

graph twoway ///
    (connected ShareSJV Month if SubFuncAgg==1) ///
    (connected ShareSJV Month if SubFuncAgg==2) ///
    (connected ShareSJV Month if SubFuncAgg==3) ///
    (connected ShareSJV Month if SubFuncAgg==4) ///
    (connected ShareSJV Month if SubFuncAgg==5) ///
    (connected ShareSJV Month if SubFuncAgg==6) ///
    (connected ShareSJV Month if SubFuncAgg==7) ///
    (connected ShareSJV Month if SubFuncAgg==8) ///
    (connected ShareSJV Month if SubFuncAgg==9) ///
    (connected ShareSJV Month if SubFuncAgg==10) ///
    (connected ShareSJV Month if SubFuncAgg==11) ///
    (connected ShareSJV Month if SubFuncAgg==12) ///
    , xlabel(1(1)12) xtitle("Calendar month") ///
    ylabel(0(0.005)0.02) ytitle("Share") /// // title("Share of employees doing lateral moves across months") ///
    legend(label(1 "Customer Relations") label(2 "Customer and Account Management") label(3 "Customer Management") label(4 "Engineering") label(5 "Finance Business Partnering") label(6 "Logistics") label(7 "Marketing Category") label(8 "Planning") label(9 "Procurement") label(10 "Product Development") label(11 "Supply chain") label(12 "Others") ring(1) position(6) rows(4) size(small))
graph export "${Round1Results}/ShareAcrossMonthsBySubFunc_SJV_2019_Top11.pdf", replace as(pdf)
