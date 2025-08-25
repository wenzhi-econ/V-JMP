*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 1. LtoH - LtoL
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/*  
*&& Program 1 evaluates the effects of gaining a FT manager.
*&& First, I will calculates \beta_{LtoH,s} - \beta_{LtoL,s}, and then reports the monthly coefficients. 
*!! Month -1 is omitted in the regression. 

Proposed changes:
	Proposed Changes:
	Since this is monthly, the checks to see if the given months are divisible by 3 is not necessary. 
	I deleted these.
	
	Changed line 213 (`event_prefix'_HtoH_X_Post0 - `event_prefix'_HtoL_X_Post0), level(90) 
	should be 
	(`event_prefix'_HtoL_X_Post0 - `event_prefix'_HtoH_X_Post0), level(90)
*/

capture program drop LH_minus_LL_Months_90
program define LH_minus_LL_Months_90, rclass 

    syntax, event_prefix(string) [PRE_window_len(integer 6) POST_window_len(integer 36) outcome(varname numeric min=1 max=1)] 
    /*
    This program has one mandatory option, and three optional options.
    The required option specifies the variable name used to measure "High-flyer" managers.
    The second two options specify the pre- and post-event window length, with default values 36 and 84, respectively.
    The last option specify the outcome variable, which will be used in generation of new variables to store the results.
    */

    /* 
    I will take `pre_window_len'==6 and `post_window_len'==36 as an example and present corresponding local values in the comments.
    */
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. produce matrices to store the results 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    local number_of_pre_months  = `pre_window_len' // 6 
    local number_of_post_months = `post_window_len' + 1 // 37
    local total_months          = `number_of_pre_months' + `number_of_post_months' // 43

    tempname coefficients_mat lower_bound_mat upper_bound_mat month_index_mat final_results

    matrix `coefficients_mat'  = J(`total_months', 1, .)
    matrix `lower_bound_mat'   = J(`total_months', 1, .)
    matrix `upper_bound_mat'   = J(`total_months', 1, .)
    matrix `month_index_mat'   = J(`total_months', 1, .) 
        // all of them are 43 by 1 matrix to store the results for plotting the coefficients

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. store those pre-event coefficients 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    forvalues month_index = `pre_window_len'(-1)2 { // 6, 5, 4, ..., 2

        local matrix_index = `pre_window_len' + 1 - `month_index'
            // 6 corresponds to 1, 5 corresponds to 2, ..., 2 corresponds to 5

        lincom (`event_prefix'_LtoH_X_Pre`month_index' - `event_prefix'_LtoL_X_Pre`month_index'), level(90)
        
        matrix `coefficients_mat'[`matrix_index', 1]  = r(estimate)
        matrix `lower_bound_mat'[`matrix_index', 1]   = r(lb)
        matrix `upper_bound_mat'[`matrix_index', 1]   = r(ub)
        matrix `month_index_mat'[`matrix_index', 1]   = -(`month_index')
            // 6 corresponds to -6, 5 corresponds to -5, ..., 2 corresponds to -2
    }

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. store period -1 and period 0 coefficients 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    matrix `coefficients_mat'[`number_of_pre_months', 1]  = 0
    matrix `lower_bound_mat'[`number_of_pre_months', 1]   = 0
    matrix `upper_bound_mat'[`number_of_pre_months', 1]   = 0
    matrix `month_index_mat'[`number_of_pre_months', 1]   = -1 


    lincom ///
        (`event_prefix'_LtoH_X_Post0 - `event_prefix'_LtoL_X_Post0), level(90)
    matrix `coefficients_mat'[`number_of_pre_months' + 1, 1]  = r(estimate)
    matrix `lower_bound_mat'[`number_of_pre_months' + 1, 1]   = r(lb)
    matrix `upper_bound_mat'[`number_of_pre_months' + 1, 1]   = r(ub)
    matrix `month_index_mat'[`number_of_pre_months' + 1, 1]   = 0 

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. store the post-event coefficients 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    forvalues month_index = 1(1)`post_window_len' { // 1, 2, 3, ..., 36

        local matrix_index = `month_index' + `number_of_pre_months' + 1
            // 1 corresponds to 8, 2 corresponds to 9, ..., 36 corresponds to 43

        lincom (`event_prefix'_LtoH_X_Post`month_index' - `event_prefix'_LtoL_X_Post`month_index'), level(90)
        
        matrix `coefficients_mat'[`matrix_index', 1]  = r(estimate)
        matrix `lower_bound_mat'[`matrix_index', 1]   = r(lb)
        matrix `upper_bound_mat'[`matrix_index', 1]   = r(ub)
        matrix `month_index_mat'[`matrix_index', 1]   = `month_index'
            // 8 corresponds to 1, 9 corresponds to 2, ..., 43 corresponds to 36 
    }

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 5. store key summary statistics
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    /* This step is not necessary for this program. */

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 6. save the results 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    matrix `final_results' = `month_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
        // a 43 by 4 matrix

    matrix colnames `final_results' = month_`outcome'_gains coeff_`outcome'_gains lb_`outcome'_gains ub_`outcome'_gains

    capture drop month_`outcome'_gains coeff_`outcome'_gains lb_`outcome'_gains ub_`outcome'_gains
    svmat `final_results', names(col)

    return matrix coefmatrix = `final_results'

end 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 2. calculate p-values for the pre-trend
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
/* 
*&& This program calculates the p-value for the following estimator: \sum_{s<0} {\beta_{LtoH,s} - \beta_{LtoL,s}}
*!! In this way, the returned scalar is the p-value for joint pre-event dummies. 
*/

capture program drop pretrend_LH_minus_LL_Month
program def pretrend_LH_minus_LL_Month, rclass

    syntax , event_prefix(string) [PRE_window_len(integer 36)]

    local jointL "`event_prefix'_LtoH_X_Pre_Before`pre_window_len' - `event_prefix'_LtoL_X_Pre_Before`pre_window_len'" 

    forval t = `pre_window_len'(-1)2 {
        local jointL "`jointL' + `event_prefix'_LtoH_X_Pre`t' - `event_prefix'_LtoL_X_Pre`t'"
    }

    lincom `jointL'

    return scalar pretrend = r(p)

end 

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? program 3. HtoL - HtoH
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*?
/*  
*&& Program 3 evaluates the effects of losing a FT manager.
*&& First, I will calculates \beta_{LtoH,s} - \beta_{LtoL,s}, and then reports the monthly coefficients. 
*!! Month -1 is omitted in the regression. 
*/

capture program drop HL_minus_HH_Month_90
program define HL_minus_HH_Month_90, rclass 

    syntax, event_prefix(string) [PRE_window_len(integer 6) POST_window_len(integer 36) outcome(varname numeric min=1 max=1)] 
    /*
    This program has one mandatory option, and three optional options.
    The required option specifies the variable name used to measure "High-flyer" managers.
    The second two options specify the pre- and post-event window length, with default values 36 and 84, respectively.
    The last option specify the outcome variable, which will be used in generation of new variables to store the results.
    */

    /* 
    I will take `pre_window_len'==6 and `post_window_len'==36 as an example and present corresponding local values in the comments.
    */
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 1. produce matrices to store the results 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    local number_of_pre_months  = `pre_window_len' // 6 
    local number_of_post_months = `post_window_len' + 1 // 37
    local total_months          = `number_of_pre_months' + `number_of_post_months' // 43

    tempname coefficients_mat lower_bound_mat upper_bound_mat month_index_mat final_results

    matrix `coefficients_mat'  = J(`total_months', 1, .)
    matrix `lower_bound_mat'   = J(`total_months', 1, .)
    matrix `upper_bound_mat'   = J(`total_months', 1, .)
    matrix `month_index_mat'   = J(`total_months', 1, .) 
        // all of them are 43 by 1 matrix to store the results for plotting the coefficients

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 2. store those pre-event coefficients 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    forvalues month_index = `pre_window_len'(-1)2 { // 6, 5, 4, ..., 2

        local matrix_index = `pre_window_len' + 1 - `month_index'
            // 6 corresponds to 1, 5 corresponds to 2, ..., 2 corresponds to 5

        lincom (`event_prefix'_HtoL_X_Pre`month_index' - `event_prefix'_HtoH_X_Pre`month_index'), level(90)
        
        matrix `coefficients_mat'[`matrix_index', 1]  = r(estimate)
        matrix `lower_bound_mat'[`matrix_index', 1]   = r(lb)
        matrix `upper_bound_mat'[`matrix_index', 1]   = r(ub)
        matrix `month_index_mat'[`matrix_index', 1]   = -(`month_index')
            // 6 corresponds to -6, 5 corresponds to -5, ..., 2 corresponds to -2
    }

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 3. store period -1 and period 0 coefficients 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    matrix `coefficients_mat'[`number_of_pre_months', 1]  = 0
    matrix `lower_bound_mat'[`number_of_pre_months', 1]   = 0
    matrix `upper_bound_mat'[`number_of_pre_months', 1]   = 0
    matrix `month_index_mat'[`number_of_pre_months', 1]   = -1 


    lincom ///
        (`event_prefix'_HtoL_X_Post0 - `event_prefix'_HtoH_X_Post0), level(90)
    matrix `coefficients_mat'[`number_of_pre_months' + 1, 1]  = r(estimate)
    matrix `lower_bound_mat'[`number_of_pre_months' + 1, 1]   = r(lb)
    matrix `upper_bound_mat'[`number_of_pre_months' + 1, 1]   = r(ub)
    matrix `month_index_mat'[`number_of_pre_months' + 1, 1]   = 0 

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 4. store the post-event coefficients 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    forvalues month_index = 1(1)`post_window_len' { // 1, 2, 3, ..., 36

        local matrix_index = `month_index' + `number_of_pre_months' + 1
            // 1 corresponds to 8, 2 corresponds to 9, ..., 36 corresponds to 43

        lincom (`event_prefix'_HtoL_X_Post`month_index' - `event_prefix'_HtoH_X_Post`month_index'), level(90)
        
        matrix `coefficients_mat'[`matrix_index', 1]  = r(estimate)
        matrix `lower_bound_mat'[`matrix_index', 1]   = r(lb)
        matrix `upper_bound_mat'[`matrix_index', 1]   = r(ub)
        matrix `month_index_mat'[`matrix_index', 1]   = `month_index'
            // 8 corresponds to 1, 9 corresponds to 2, ..., 43 corresponds to 36 
    }

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 5. store key summary statistics
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    /* This step is not necessary for this program. */

    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
    *-? step 6. save the results 
    *-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

    matrix `final_results' = `month_index_mat', `coefficients_mat', `lower_bound_mat', `upper_bound_mat'
        // a 43 by 4 matrix

    matrix colnames `final_results' = month_`outcome'_loss coeff_`outcome'_loss lb_`outcome'_loss ub_`outcome'_loss

    capture drop month_`outcome'_loss coeff_`outcome'_loss lb_`outcome'_loss ub_`outcome'_loss
    svmat `final_results', names(col)

    return matrix coefmatrix = `final_results'

end 
