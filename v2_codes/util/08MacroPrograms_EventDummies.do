/* 
This program construct "event * relative period" dummies used in the event study regressions, and store these regressors in a macro.
    (1) The program needs input parameters: event_prefix, max_pre_period, lto_max_post, hto_max_post.
    (2) The resulting new variables have the following naming patterns: (take `event_prefix' as an example event_prefix)
        (a) For normal "event * relative period" dummies, e.g. `event_prefix'_LtoL_X_Pre12 `event_prefix'_LtoL_X_Pre1 `event_prefix'_LtoH_X_Post0 `event_prefix'_HtoH_X_Post12
        (b) For binned dummies, e.g. `event_prefix'_LtoL_X_Pre_Before36 `event_prefix'_LtoH_X_Post_After84
    (3) Due to the choice of the omitted groups, the interaction terms between relative month indicators -1, -2, -3 and event group indicators are not in the resulting global macro storing regressors.
    (4) The resulting global macro is called "four_events_dummies".

RA: WWZ 
Time: 2025-05-23
*/

capture program drop GenerateEventDummies
program define GenerateEventDummies

syntax, event_prefix(string) [MAX_pre_period(integer 24) lto_max_post(integer 84) hto_max_post(integer 60)]

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 1. construct "event * relative period" dummies 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture drop `event_prefix'_Rel_Time 
generate `event_prefix'_Rel_Time = Rel_Time

*!! event group: LtoL
generate byte `event_prefix'_LtoL_X_Pre_Before`max_pre_period' = `event_prefix'_LtoL * (`event_prefix'_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte `event_prefix'_LtoL_X_Pre`time' = `event_prefix'_LtoL * (`event_prefix'_Rel_Time == -`time')
}
forvalues time = 0/`lto_max_post' {
    generate byte `event_prefix'_LtoL_X_Post`time' = `event_prefix'_LtoL * (`event_prefix'_Rel_Time == `time')
}
generate byte `event_prefix'_LtoL_X_Post_After`lto_max_post' = `event_prefix'_LtoL * (`event_prefix'_Rel_Time > `lto_max_post')

*!! event group: LtoH
generate byte `event_prefix'_LtoH_X_Pre_Before`max_pre_period' = `event_prefix'_LtoH * (`event_prefix'_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte `event_prefix'_LtoH_X_Pre`time' = `event_prefix'_LtoH * (`event_prefix'_Rel_Time == -`time')
}
forvalues time = 0/`lto_max_post' {
    generate byte `event_prefix'_LtoH_X_Post`time' = `event_prefix'_LtoH * (`event_prefix'_Rel_Time == `time')
}
generate byte `event_prefix'_LtoH_X_Post_After`lto_max_post' = `event_prefix'_LtoH * (`event_prefix'_Rel_Time > `lto_max_post')

*!! event group: HtoH 
generate byte `event_prefix'_HtoH_X_Pre_Before`max_pre_period' = `event_prefix'_HtoH * (`event_prefix'_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte `event_prefix'_HtoH_X_Pre`time' = `event_prefix'_HtoH * (`event_prefix'_Rel_Time == -`time')
}
forvalues time = 0/`hto_max_post' {
    generate byte `event_prefix'_HtoH_X_Post`time' = `event_prefix'_HtoH * (`event_prefix'_Rel_Time == `time')
}
generate byte `event_prefix'_HtoH_X_Post_After`hto_max_post' = `event_prefix'_HtoH * (`event_prefix'_Rel_Time > `hto_max_post')

*!! event group: HtoL 
generate byte `event_prefix'_HtoL_X_Pre_Before`max_pre_period' = `event_prefix'_HtoL * (`event_prefix'_Rel_Time < -`max_pre_period')
forvalues time = 1/`max_pre_period' {
    generate byte `event_prefix'_HtoL_X_Pre`time' = `event_prefix'_HtoL * (`event_prefix'_Rel_Time == -`time')
}
forvalues time = 0/`hto_max_post' {
    generate byte `event_prefix'_HtoL_X_Post`time' = `event_prefix'_HtoL * (`event_prefix'_Rel_Time == `time')
}
generate byte `event_prefix'_HtoL_X_Post_After`hto_max_post' = `event_prefix'_HtoL * (`event_prefix'_Rel_Time > `hto_max_post')

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? step 2. global macros used in regressions 
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

macro drop `event_prefix'_LtoL_X_Pre 
macro drop `event_prefix'_LtoL_X_Post 
macro drop `event_prefix'_LtoH_X_Pre 
macro drop `event_prefix'_LtoH_X_Post 
macro drop `event_prefix'_HtoH_X_Pre 
macro drop `event_prefix'_HtoH_X_Post 
macro drop `event_prefix'_HtoL_X_Pre 
macro drop `event_prefix'_HtoL_X_Post
macro drop four_events_dummies

foreach event in `event_prefix'_LtoL `event_prefix'_LtoH {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in `event_prefix'_LtoL `event_prefix'_LtoH {
    forvalues time = 0/`lto_max_post' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`lto_max_post'
}
foreach event in `event_prefix'_HtoH `event_prefix'_HtoL {
    global `event'_X_Pre `event'_X_Pre_Before`max_pre_period'
    forvalues time = `max_pre_period'(-1)4 {
        global `event'_X_Pre ${`event'_X_Pre} `event'_X_Pre`time'
    }
}
foreach event in `event_prefix'_HtoH `event_prefix'_HtoL {
    forvalues time = 0/`hto_max_post' {
        global `event'_X_Post ${`event'_X_Post} `event'_X_Post`time'
    }
    global `event'_X_Post ${`event'_X_Post} `event'_X_Post_After`hto_max_post'
}

global four_events_dummies ///
    ${`event_prefix'_LtoL_X_Pre} ${`event_prefix'_LtoL_X_Post} ///
    ${`event_prefix'_LtoH_X_Pre} ${`event_prefix'_LtoH_X_Post} ///
    ${`event_prefix'_HtoH_X_Pre} ${`event_prefix'_HtoH_X_Post} ///
    ${`event_prefix'_HtoL_X_Pre} ${`event_prefix'_HtoL_X_Post}

end