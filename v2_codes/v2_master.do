/* 
This is the master do file.

RA: WWZ 
Time: 2025-08-11
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 1. default setups
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

version 16

clear all
set more off
set maxvar 32767
set varabbrev off

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 2. global macros to store folder paths
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-? s-2-1. user-specific parent folder

if  "`c(username)'" == "virginiaminni" global user "/Users/virginiaminni/Dropbox/JMP_Managers"
if  "`c(username)'" == "virginia_m"    global user "C:/Users/virginia_m/Dropbox/JMP_Managers"
if  "`c(username)'" == "wang"         {
    global user "E:/__RA/JMP_Managers"
    global python_loc = "./python_env/python.exe"
} 

cd "${user}"

*-? s-2-2. codes-related folders

global Codes             "${user}/v2_codes"
global Analysis          "${Codes}/analysis"
global Utilities         "${Codes}/util"

*-? s-2-3. data-related folders

global Data              "${user}/data"
global RawMNEData        "${user}/data/a_raw_data/a_MNE_data"
global RawONETData       "${user}/data/a_raw_data/b_ONET_data"
global RawCntyData       "${user}/data/a_raw_data/c_country_data"
global TempData          "${user}/data/b_temp_data"

*-? s-2-4. output-related folders

global Results            "${user}/v2_output"
global EventStudyResults  "${Results}/a_event_study_results"
global DescriptiveResults "${Results}/b_descriptive_results"
global OtherResults       "${Results}/c_other_results"
global Round1Results      "${Results}/e_round1_referees"

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 3. libraries (user-written procedures) to be used 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? install all necessary packages to a local directory
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

/* do "${Utilities}/00InstallPackages.do" */

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? use libraries stored in the local stata_libraries folder
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

net set ado "${user}/stata_libraries"

tokenize `"$S_ADO"', parse(";")
while `"`1'"' != "" {
    if `"`1'"'!="BASE" capture adopath - `"`1'"'
    macro shift
}
adopath ++ "${user}/stata_libraries"

*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? using python stored in the local python_env environment
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
/* 
Notes: 
    (1) The python script files will be executed by the shell command in Stata. 
        (i) Therefore, it is necessary to specify the location of a properly specified python virtual environment.
        (ii) Make sure the virtual environment is installed in the ${user}/python_env folder.
        (iii) Make sure the virtual environment follows the specifications in the "environment.yml" file.
    (2) This can be easily achieved by running the following commands in e.g., windows powershell.
            cd /path/to/project
            conda env create --prefix ./python_env --file environment.yml
    (3) To test whether the virtual environment has been set up properly, run the following commands.
            cd /path/to/project
            conda activate ./python_env
            conda list pandas
            pip show pyfixest
    (4) The specific location of the python is stored in the global macro ${python_loc}.
        (i) In a Windows laptop, it could be 
            global python_loc = "./python_env/python.exe".
        (ii) In a Linux system, it could be 
            global python_loc = "/path/to/project/python_env/python".
*/

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 4. set figure scheme 
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

grstyle clear
grstyle init project_default, path("${user}/stata_libraries") replace
grstyle set plain, grid dotted
grstyle set size large: heading
grstyle set margin "0pt 0pt 0pt 10pt": heading
grstyle set size medlarge: axis_title

*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??
*?? step 5. replicate results in the paper
*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??*??

global if_erase_temp_file = 1
    //&? if it is set to 1, temporary auxiliary dta files produced in the data cleaning process will be erased


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-1. dataset construction
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

capture log close 
log using "${TempData}/20250825Log_DataCleaning.txt", replace text

do "${Codes}/clean/0101_01GenerateWorkersOutcomes.do"
do "${Codes}/clean/0101_02ONETRawScoreConstruction.do"
do "${Codes}/clean/0101_03ONETPercentileRankConstruction.do"
do "${Codes}/clean/0102_01UpdateVarAgeBand.do"
do "${Codes}/clean/0102_02GenerateVarAgeContinuous.do"
do "${Codes}/clean/0102_03GenerateAgeBasedHFMeasures.do"
do "${Codes}/clean/0102_04GenerateTenureBasedHFMeasure.do"
do "${Codes}/clean/0103_01IdentifyEventWorkers.do"
do "${Codes}/clean/0103_02GenerateEventDummies.do"
do "${Codes}/clean/0103_03GenerateOtherOutcomes.do"
do "${Codes}/clean/0104GenerateHeterogeneityIndicators.do"
do "${Codes}/clean/0105SalesProductivityDatasets.do"
do "${Codes}/clean/0106TeamLevelDataset.do"

log close


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-2. less computationally intensive programs
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Figure I
do "${Analysis}/b_descriptive_results/DescFig0301_WLAgainstTenureDist.do"
do "${Analysis}/b_descriptive_results/DescFig0302_AgeAtPromDist.do"

*!! Figure II, panel (c) and (d); Figure VII, panel (c) and (d)
do "${Analysis}/c_other_results/MainFig0101_ExitOutcomes_InvolAndVol.do"

*!! Figure IV 
do "${Analysis}/c_other_results/MainFig0201_SkillTransferHeatmap_LtoLvsLtoH.do"
shell "${python_loc}" "${Analysis}/c_other_results/MainFig0202_OccTaskTransitionHeatMap.py"

*!! Table I 
do "${Analysis}/b_descriptive_results/DescTab0101_SummaryStatistics_ObsSize.do"

*!! Table II
do "${Analysis}/b_descriptive_results/DescTab0102_SummaryStatistics_WholeSample.do"

*!! Table III
do "${Analysis}/b_descriptive_results/DescTab0201_MngrCharacteristics_HvsL.do"

*!! Table IV
do "${Analysis}/b_descriptive_results/DescTab0301_TimeUseMngrHvsL.do"

*!! Table V
do "${Analysis}/c_other_results/MechTab0101_ActiveLearningAndFlexibleProject.do"

*!! Appendix Figure A.3
do "${Analysis}/b_descriptive_results/DescFig0401_AgeAndTenure_AgainstYearProfiles_ByWL.do"

*!! Appendix Figure A.5
do "${Analysis}/b_descriptive_results/DescFig0201_ShareMoversAcrossSubFuncs.do"

*!! Appendix Figure A.6
do "${Analysis}/b_descriptive_results/DescFig0501_PayRelatedVarsCorrelation.do"

*!! Appendix Figure A.12
shell "${python_loc}" "${Analysis}/b_descriptive_results/DescFig0101_SkillsDescriptionLDA.py"
do "${Analysis}/b_descriptive_results/DescFig0102_SkillsComparison.do"

*!! Appendix Table B.1
do "${Analysis}/a_event_studies/EndogMobChecks01_toH_FromPre24toPre1.do"

*!! Appendix Table B.2
do "${Analysis}/a_event_studies/EndogMobChecks02_toHVStoL_Pre24toPre1.do"

*!! Appendix Table B.3
do "${Analysis}/c_other_results/Corr0101_HFIsNotAnLaggingIndicator_FactoryLevel.do"

*!! Appendix Table B.4
do "${Analysis}/c_other_results/Corr0102_HFIsNotALaggingIndicator_CountryFuncLevel.do"

*!! Appendix Table B.5
do "${Analysis}/c_other_results/MechTab0201_Network_WorkInfo.do"
do "${Analysis}/c_other_results/MechTab0202_ColleagueInfo.do"
do "${Analysis}/c_other_results/MechTab0203_Network_Regressions.do"

*!! Appendix Table B.6
do "${Analysis}/c_other_results/MechTab0301_JobCreation_LtoHvsLtoL.do"

*!! Supplementary Materials Table S.2
do "${Analysis}/c_other_results/SurveyOutcomes0101_ResponseDiff.do"

*!! Supplementary Materials Table S.3 and S.4
do "${Analysis}/c_other_results/SurveyOutcomes0102_CorrWithHFStatus.do"


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-3. self-written programs (for event studies)
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

do "${Utilities}/01CoefPrograms_LHminusLL.do" 
do "${Utilities}/02CoefPrograms_HLminusHH.do"
do "${Utilities}/03CoefPrograms_Dual_TestingforAsymmetries.do"
do "${Utilities}/04CoefPrograms_LHminusLL_OnlyPost.do" 
do "${Utilities}/05CoefPrograms_HLminusHH_OnlyPost.do"
do "${Utilities}/06CoefPrograms_Dual_TestingforAsymmetries_OnlyPost.do"
do "${Utilities}/07CoefPrograms_CohortDynamics.do"
do "${Utilities}/08MacroPrograms_EventDummies.do"
do "${Utilities}/09CoefPrograms_LHAndLL.do"
do "${Utilities}/10CoefPrograms_MonthlyCoef.do"
do "${Utilities}/11CoefPrograms_MonthlyCoef_90Confidence.do"


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-4. computationally intensive programs
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

*!! Figure II, panel (a) and (b); Figure VII, panel (a) and (b); Figure VIII
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type1_Baseline.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type1_Baseline.do"

*!! Figure III
do "${Analysis}/a_event_studies/ES03_SJVertSGC_Decomp_PeriodAndQuarterCoefs.do"

*!! Figure V
do "${Analysis}/a_event_studies/ES04_PayOutcomes.do"
do "${Analysis}/a_event_studies/ES05_PromWLC_YearlyCoefs.do"

*!! Figure VI
do "${Analysis}/a_event_studies/ES06_ProductivityStd_Pre6Post42_MonthlyCoefs.do"

*!! Table VI 
do "${Analysis}/a_event_studies/HetTab_FourMainOutcomes.do"

*!! Appendix Figure A.7
do "${Analysis}/a_event_studies/ES07_PrSJVertSG.do"
do "${Analysis}/a_event_studies/ES09_ONETDistC.do"

*!! Appendix Figure A.8
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type3_TenureBasedMeasure.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type3_TenureBasedMeasure.do"

*!! Appendix Figure A.9
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type2_OtherAgeBasedMeasures.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type2_OtherAgeBasedMeasures.do"

*!! Appendix Figure A.10
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type5_CohortDynamics1_LtoHvsLtoL.do"
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type5_CohortDynamics2_HtoLvsHtoH.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type5_CohortDynamics1_LtoHvsLtoL.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type5_CohortDynamics2_HtoLvsHtoH.do"

*!! Appendix Figure A.11
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type4_NewHires.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type4_NewHires.do"
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Type6_Poisson.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Type6_Poisson.do"

*!! Appendix Figure A.13
do "${Analysis}/a_event_studies/ES08_TeamLevel_CVPay_YearlyCoefs.do"

*!! Supplementary Materials Figure S.1
do "${Analysis}/a_event_studies/ES01_SJVertSGC_Typez_Placebo.do"
do "${Analysis}/a_event_studies/ES02_SGRawC_Typez_Placebo.do"


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-5. statistics cited in the paper
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

do "${Analysis}/c_other_results/StatInPaper01_Numbers.do"
do "${Analysis}/c_other_results/StatInPaper02_Magnitudes.do"
do "${Analysis}/c_other_results/StatInPaper03_PayEffectsMagnitudes.do"
shell "${python_loc}" "${Analysis}/b_descriptive_results/StatInPaper03_PayEffectsMagnitude_TenureEquivalent.py"
do "${Analysis}/c_other_results/StatInPaper04_Mediation.do"
do "${Analysis}/c_other_results/StatInPaper05_CostBenefitAnalysis.do"


*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?
*-? s-5-6. transform all gph files to pdf files
*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?*-?

local folder_path "${EventStudyResults}"
local gph_files : dir "`folder_path'" files "*.gph", respectcase

foreach file in `gph_files' {
    display "----------------------------------------------------------------------------"
	display "----------------------------------------------------------------------------"
    display "Processing file: `file'"

    local base_name = substr("`file'", 1, strrpos("`file'", ".") - 1)

    graph use "`folder_path'/`file'"
    graph export "`folder_path'/`base_name'.pdf", as(pdf) replace

    display "Done with file: `file'"
    display "----------------------------------------------------------------------------"
    display "----------------------------------------------------------------------------"
}