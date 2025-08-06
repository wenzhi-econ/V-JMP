*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. calculate the quarter estimates from the monthly regression
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/* 
This program stores quarterly coefficients for LtoL and LtoH event groups, separately.  
The only difference from "01CoefPrograms_LHminusLL.do" is that instead of storing the quarterly coefficient difference, I store the coefficients separately.
*/
/*  
*!! Months -3, -2, -1 are omitted in the regression, so that quarter -1 estimate is guaranteed to be zero. 
*!! Quarter 0 estimate is month 0 estimate. 
*!! Quarter +1 estimate is the average of months +1, +2, +3 estimates...
*/

capture program drop LHAndLL
program define LHAndLL, rclass 
syntax, event_prefix(string) [PRE_window_len(integer 36) POST_window_len(integer 84) outcome(varname numeric min=1 max=1)] 
/*
This program has one mandatory option, and three optional options.
The required option specifies the variable name used to measure "High-flyer" managers.
The second two options specify the pre- and post-event window length, with default values 36 and 84, respectively.
The last option specify the outcome variable, which will be used in generation of new variables to store the results.
*/
local test_pre_window_len  = mod(`pre_window_len', 3)
local test_post_window_len = mod(`post_window_len', 3)
if `test_pre_window_len'!=0 | `test_post_window_len'!=0 {
    display as result _n "Specified pre- and/or post-window lengths are not suitable for CP quarter aggregation."
    display as result _n "Program terminated."
    exit
}

/* 
I will take `pre_window_len'==36 and `post_window_len'==84 as an example and present corresponding local values in the comments.
*/
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 1. produce matrices to store the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
local number_of_pre_quarters  = trunc(`pre_window_len'/3) // 12 
local number_of_post_quarters = trunc(`post_window_len'/3) + 1 // 29
local total_quarters          = `number_of_pre_quarters' + `number_of_post_quarters' // 41

tempname coefficients_mat_LtoL lower_bound_mat_LtoL upper_bound_mat_LtoL quarter_index_mat_LtoL final_results_LtoL
tempname coefficients_mat_LtoH lower_bound_mat_LtoH upper_bound_mat_LtoH quarter_index_mat_LtoH final_results_LtoH

matrix `coefficients_mat_LtoL'  = J(`total_quarters', 1, .)
matrix `lower_bound_mat_LtoL'   = J(`total_quarters', 1, .)
matrix `upper_bound_mat_LtoL'   = J(`total_quarters', 1, .)
matrix `quarter_index_mat_LtoL' = J(`total_quarters', 1, .) 
matrix `coefficients_mat_LtoH'  = J(`total_quarters', 1, .)
matrix `lower_bound_mat_LtoH'   = J(`total_quarters', 1, .)
matrix `upper_bound_mat_LtoH'   = J(`total_quarters', 1, .)
matrix `quarter_index_mat_LtoH' = J(`total_quarters', 1, .) 
    // all of them are 41 by 1 matrix to store the results for plotting the coefficients

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. store those pre-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
forvalues left_month_index = `pre_window_len'(-3)4 { // 36, 33, 30, ..., 6
    local quarter_index = `number_of_pre_quarters' + 1 - (`left_month_index'/3) 
        // 36 corresponds to 1, 31 corresponds to 2, ..., 4 corresponds to 11
    
    local middle_month_index = `left_month_index' - 1 // 35, 32, 29, ..., 5
    local right_month_index  = `left_month_index' - 2 // 34, 31, 28, ..., 4

    lincom (`event_prefix'_LtoH_X_Pre`left_month_index' + `event_prefix'_LtoH_X_Pre`middle_month_index' + `event_prefix'_LtoH_X_Pre`right_month_index')/3, level(95)
        matrix `coefficients_mat_LtoH'[`quarter_index', 1]  = r(estimate)
        matrix `lower_bound_mat_LtoH'[`quarter_index', 1]   = r(lb)
        matrix `upper_bound_mat_LtoH'[`quarter_index', 1]   = r(ub)
        matrix `quarter_index_mat_LtoH'[`quarter_index', 1] = -(`left_month_index')/3  
            // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2

    lincom (`event_prefix'_LtoL_X_Pre`left_month_index' + `event_prefix'_LtoL_X_Pre`middle_month_index' + `event_prefix'_LtoL_X_Pre`right_month_index')/3, level(95)
        matrix `coefficients_mat_LtoL'[`quarter_index', 1]  = r(estimate)
        matrix `lower_bound_mat_LtoL'[`quarter_index', 1]   = r(lb)
        matrix `upper_bound_mat_LtoL'[`quarter_index', 1]   = r(ub)
        matrix `quarter_index_mat_LtoL'[`quarter_index', 1] = -(`left_month_index')/3  
            // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 3. store period -1 and period 0 coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
matrix `coefficients_mat_LtoH'[`number_of_pre_quarters', 1]  = 0
matrix `lower_bound_mat_LtoH'[`number_of_pre_quarters', 1]   = 0
matrix `upper_bound_mat_LtoH'[`number_of_pre_quarters', 1]   = 0
matrix `quarter_index_mat_LtoH'[`number_of_pre_quarters', 1] = -1 
matrix `coefficients_mat_LtoL'[`number_of_pre_quarters', 1]  = 0
matrix `lower_bound_mat_LtoL'[`number_of_pre_quarters', 1]   = 0
matrix `upper_bound_mat_LtoL'[`number_of_pre_quarters', 1]   = 0
matrix `quarter_index_mat_LtoL'[`number_of_pre_quarters', 1] = -1 

lincom (`event_prefix'_LtoH_X_Post0), level(95)
    matrix `coefficients_mat_LtoH'[`number_of_pre_quarters' + 1, 1]  = r(estimate)
    matrix `lower_bound_mat_LtoH'[`number_of_pre_quarters' + 1, 1]   = r(lb)
    matrix `upper_bound_mat_LtoH'[`number_of_pre_quarters' + 1, 1]   = r(ub)
    matrix `quarter_index_mat_LtoH'[`number_of_pre_quarters' + 1, 1] = 0 

lincom (`event_prefix'_LtoL_X_Post0), level(95)
    matrix `coefficients_mat_LtoL'[`number_of_pre_quarters' + 1, 1]  = r(estimate)
    matrix `lower_bound_mat_LtoL'[`number_of_pre_quarters' + 1, 1]   = r(lb)
    matrix `upper_bound_mat_LtoL'[`number_of_pre_quarters' + 1, 1]   = r(ub)
    matrix `quarter_index_mat_LtoL'[`number_of_pre_quarters' + 1, 1] = 0 

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 4. store the post-event coefficients 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
* reset these macros to avoid contamination from the pre-event coefficients
local right_month_index  = 0 
local middle_month_index = 0 
local left_month_index   = 0

forvalues right_month_index = 3(3)`post_window_len' { 
    local quarter_index = (`right_month_index')/3 + `number_of_pre_quarters' + 1
        // 3 corresponds to 14, 6 corresponds to 15, ..., 84 corresponds to 41
    
    local middle_month_index = `right_month_index' - 1 // 2, 5, 8, ..., 83
    local left_month_index   = `right_month_index' - 2 // 1, 4, 7, ..., 82 

    lincom (`event_prefix'_LtoH_X_Post`right_month_index' + `event_prefix'_LtoH_X_Post`middle_month_index' + `event_prefix'_LtoH_X_Post`left_month_index')/3, level(95)
        matrix `coefficients_mat_LtoH'[`quarter_index', 1]  = r(estimate)
        matrix `lower_bound_mat_LtoH'[`quarter_index', 1]   = r(lb)
        matrix `upper_bound_mat_LtoH'[`quarter_index', 1]   = r(ub)
        matrix `quarter_index_mat_LtoH'[`quarter_index', 1] = (`right_month_index')/3 
            // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2

    lincom (`event_prefix'_LtoL_X_Post`right_month_index' + `event_prefix'_LtoL_X_Post`middle_month_index' + `event_prefix'_LtoL_X_Post`left_month_index')/3, level(95)
        matrix `coefficients_mat_LtoL'[`quarter_index', 1]  = r(estimate)
        matrix `lower_bound_mat_LtoL'[`quarter_index', 1]   = r(lb)
        matrix `upper_bound_mat_LtoL'[`quarter_index', 1]   = r(ub)
        matrix `quarter_index_mat_LtoL'[`quarter_index', 1] = (`right_month_index')/3 
            // 36 corresponds to -12, 33 corresponds to -11, ..., 6 corresponds to -2
}

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 5. store key summary statistics
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* This step is unnecessary for this program. */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 6. save the results 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

matrix `final_results_LtoH' = `quarter_index_mat_LtoH', `coefficients_mat_LtoH', `lower_bound_mat_LtoH', `upper_bound_mat_LtoH' // a 41 by 4 matrix
matrix `final_results_LtoL' = `quarter_index_mat_LtoL', `coefficients_mat_LtoL', `lower_bound_mat_LtoL', `upper_bound_mat_LtoL' // a 41 by 4 matrix

matrix colnames `final_results_LtoH' = quarter_`outcome'_LtoH coeff_`outcome'_LtoH lb_`outcome'_LtoH ub_`outcome'_LtoH
matrix colnames `final_results_LtoL' = quarter_`outcome'_LtoL coeff_`outcome'_LtoL lb_`outcome'_LtoL ub_`outcome'_LtoL

capture drop quarter_`outcome'_LtoH coeff_`outcome'_LtoH lb_`outcome'_LtoH ub_`outcome'_LtoH
capture drop quarter_`outcome'_LtoL coeff_`outcome'_LtoL lb_`outcome'_LtoL ub_`outcome'_LtoL

svmat `final_results_LtoH', names(col)
svmat `final_results_LtoL', names(col)

return matrix coefmatrix_LtoH = `final_results_LtoH'
return matrix coefmatrix_LtoL = `final_results_LtoL'

end 