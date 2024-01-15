clear
set more off 
set matsize 800
cap log close

*The working directory will be the following 
cd "C:\Users\gigi\Documents\ThinkPad_Backup_2024\Applied Economics MS\ECON 644 - Empirical Analysis II\Term Project"

log using project_results.log, replace

use "original files\originals\konda_data_for_analysis.dta", clear

*First: edit dataset so you have only include those who have responded;
sum
*N=2,175
keep if non_response==0
sum 
return list
*N=1,909

qui tab education, missing gen(education_)
qui tab ethnicity, missing gen(ethnicity_)
qui tab survey_taker_id, missing gen(survey_taker_id_)
qui tab marital_status, missing gen(marital_status_)

global contr="month_* province_n_* i.education female i.survey_taker_id"
global se "cluster modate"	
global slvl "starlevels(* 0.10 ** 0.05 *** 0.01)"

**In order to create a treatment group, we need to create a binary variable that distringuishes between treated and non-treated group. 
*In this case, controldummy=1 if individuals are born after 1955, so they are past the threshold age=65 so the government policy takes affects. controldummy=0 if individuals are born before 1955. 
gen controldummy = 0 
replace controldummy = 1 if before1955 == 0 
label var controldummy "=1 if control group, born before cutoff"


****************SUMMARY STATISTICS*************************
****************TABLE 1: DATASET SUMMARY STATISTICS

label var age "Age"
label var before1955 "Born before December 1955"
label var illiterate "Illiterate"
label var highschool "Completed Highschool"
label var female "Female"
label var married "Married"
label var widowed_separated "Widowed or separated"
label var hh_size "Household size"
label var pre_covid_hhsize "Pre-COVID household size"

label var outside_week "Number of days outside last week"
label var under_curfew "Subject to imposed curfew "
label var lim_social_interaction "Limited social interaction"

label var total_employment "Paid or unpaid employed"
label var job_to_return "Has a job but could not attend last week"
label var money_as_usual "Has money for usual needs"
label var money_distressed "Worried about spending money"

asdoc sum age before1955 illiterate highschool female married widowed_separate hh_size pre_covid_hhsize outside_week under_curfew lim_social_interaction total_employment job_to_return money_as_usual money_distressed, label noobs 


****************TABLE 2: LIST OF SRQ-20 QUESTIONS: SUMMARY STATISTICS

label var head_ache "1. Have you often had headaches?"
label var mal_appetite "2. Has your appetite been poor?"
label var sleeplessness "3. Have you slept badly?"
label var scared "4. Have you been easily frightened?"
label var shaking "5. Have you had shaking hands?"
label var nervous "6. Have you felt nervous, tense, or worried?"
label var indigestion "7. Has your digestion been poor?"
label var unfocused "8. Have you had trouble in thinking clearly?"
label var unhappy "9. Have you felt unhappy?"
label var weepy "10. Have you cried more often than usual?"
label var unwillingness "11. Have you found it difficult to enjoy your daily activities?"
label var undecisiveness "12. Have you found it difficult to make decisions?"
label var disrupted "13. Has your daily work suffered?"
label var useless "14. Have you been unable to play a useful part in life?"
label var uninterest "15. Have you lost interest in things?"
label var worthless "16. Have you felt that you are a worthless person?"
label var suicidal "17. Has the thought of ending your life been on your mind?"
label var usually_tired "18. Have you felt tired all the time?"
label var stomach_discomfort "19. Have you had uncomfortable feelings in your stomach?"
label var quickly_tired "20. Have you gotten tired easily?"

asdoc sum head_ache mal_appetite sleeplessness scared shaking nervous indigestion unfocused unhappy weepy unwillingness undecisiveness disrupted useless uninterest worthless suicidal usually_tired stomach_discomfort quickly_tired, label


*************************************************************



****************MENTAL DISTRESS INDICES*************************
*global x xi xii= creates a macro named "x" that contains "xi" and "xii". 
*use in a command tell Stata to replace $x with the contents of the global macro

*Mental distress index: Includes responses to all 20 questions
global mdindex "mal_appetite sleeplessness scared nervous unfocused unhappy weepy unwillingness undecisiveness disrupted useless uninterest worthless suicidal usually_tired quickly_tired head_ache shaking indigestion stomach_discomfort"
sum $mdindex

*Nonsomatic symptoms: Includes responses that cover nonsomatic symtoms of distress
global nonsomindex "mal_appetite sleeplessness scared nervous unfocused unhappy weepy unwillingness undecisiveness disrupted useless uninterest worthless suicidal usually_tired quickly_tired"
sum $nonsomindex

*Somatic symptoms: Includes responses that cover somatic symptoms of distress
global somindex "head_ache shaking indigestion stomach_discomfort"
sum $somindex

*Religiousity index: Includes responses on how religious respondents are
global religionndex "religious daily_pray practice_the_book virus_god_sent"
sum $religionndex

/* generate indices for main sample. NOTE - the egen function
weightave2 function comes from _gweightave2.ado - the .ado file will
be read into stata when it's in the working directory of the do file
that calls it. however - it is better practice to put it in your
personal ado path - which is ~/ado/personal. this function was sent
from Bilal Siddiqi to Sam Asher, based on Anderson (2008): Multiple
Inference and Gender Differences in the Effects of Early Intervention:
A Reevaluation of the Abecedarian, Perry Preschool, and Early Training
Projects. */

***Average of the z-scores of the 20 mental health indicators:
egen z_depression = weightave2($mdindex), normby(controldummy)
label var z_depression "Mental distress index"

egen z_nonsomatic = weightave2($nonsomindex), normby(controldummy)
label var z_nonsomatic "Nonsomatic symptoms of distress index"

egen z_somatic= weightave2($somindex), normby(controldummy)
label var z_somatic "Somatic symptoms of distress index"

egen z_religion = weightave2($religionndex), normby(controldummy)

egen sum_srq20= rowtotal($mdindex)
label var sum_srq20 "Sum of yes answers in SRQ-20"

sum controldummy z_depression z_nonsomatic z_somatic z_religion sum_srq

****Create a for loop each variable:
foreach x in $mdindex{
replace z_depression = . if `x' == .
}

foreach x in $nonsomindex{
replace z_nonsomatic = . if `x' == .
}

foreach x in $somindex{
replace z_somatic = . if `x' == .
}

foreach x in $religionndex{
replace z_religion = . if `x' == .
}

foreach x in $mdindex{
replace sum_srq = . if `x' == .
}


****************FIGURES:
***********Heatplot for Mental Distress Index on Various Factors
corr z_depression before1955 female psych_support lim_social_interaction chronic_disease poor_overall_health married outside_week gov_support_d 
matrix C= r(C)
heatplot C, values(format(%9.3f)) colors(hcl, intensity(.6)) legend(off) aspectratio(1) lower nodiagonal

**********RD Plot for Married
rdplot married dif, c(0) msize(tiny) graph_options(xlabel(-44(22)44)) p(5) ci(95) shade binselect(qsmvpr)
graph save "Graph" "C:\Users\gigi\Documents\ThinkPad_Backup_2024\Applied Economics MS\ECON 644 - Empirical Analysis II\Term Project\replication\tablesfigures\Panel_Married.gph"


**********RD Plot for Days Outside
rdplot outside_week dif, c(0) msize(tiny) graph_options(xlabel(-44(22)44)) title("Days outside last week") xtitle("") ytitle("Born before December 1955 (in months)")  p(5) ci(95) shade binselect(qsmvpr)
graph save "Graph" "C:\Users\gigi\Documents\ThinkPad_Backup_2024\Applied Economics MS\ECON 644 - Empirical Analysis II\Term Project\replication\tablesfigures\Panel_Days outside.gph"

**********RD Plot for under curfew
rdplot under_curfew dif, c(0) msize(tiny) graph_options(xlabel(-44(22)44)) title("Under curfew") xtitle("") ytitle("Born before December 1955 (in months)")  p(5) ci(95) shade binselect(qsmvpr)
graph save "Graph" "C:\Users\gigi\Documents\ThinkPad_Backup_2024\Applied Economics MS\ECON 644 - Empirical Analysis II\Term Project\replication\tablesfigures\Panel_Under curfew.gph"

**********RD Plot for Mental distress index
rdplot z_depression dif, c(0) msize(tiny) graph_options(xlabel(-44(22)44)) title("Mental distress index") xtitle("") ytitle("Born before December 1955 (in months)")  p(5) ci(95) shade binselect(qsmvpr)
graph save "Graph" "C:\Users\gigi\Documents\ThinkPad_Backup_2024\Applied Economics MS\ECON 644 - Empirical Analysis II\Term Project\replication\tablesfigures\Panel_Mental distress.gph"



*********************4. Main Regressions
**Mental Distress Index
eststo clear
eststo: reg z_depression before1955 if inrange(dif, -17, 17)
*pval= .007
eststo: reg z_depression before1955 if inrange(dif, -30, 30)
*pval= .014
eststo: reg z_depression before1955 if inrange(dif, -45, 45)
*pval= .000
eststo: reg z_depression before1955 if inrange(dif, -60, 60)
*pval= .000
estadd scalar outcome_mean = r(mean)
esttab using table4_1.rtf, stats(N outcome_mean, fmt(%9.0g %9.2f))  nonumbers 

**Somatic symptoms
eststo clear
eststo: reg z_somatic before1955 if inrange(dif, -17, 17)
eststo: reg z_somatic before1955 if inrange(dif, -30, 30)
eststo: reg z_somatic before1955 if inrange(dif, -45, 45)
eststo: reg z_somatic before1955 if inrange(dif, -60, 60)
estadd scalar outcome_mean = r(mean)
esttab using table4_2.rtf, stats(N outcome_mean, fmt(%9.0g %9.2f))  nonumbers 

**Non-somatic symptoms
eststo clear
eststo: reg z_nonsomatic before1955 if inrange(dif, -17, 17)
eststo: reg z_nonsomatic before1955 if inrange(dif, -30, 30)
eststo: reg z_nonsomatic before1955 if inrange(dif, -45, 45)
eststo: reg z_nonsomatic before1955 if inrange(dif, -60, 60)
estadd scalar outcome_mean = r(mean)
esttab using table4_3.rtf, stats(N outcome_mean, fmt(%9.0g %9.2f))  nonumbers 

**SRQ-20 Yes'
eststo clear
eststo: reg sum_srq20 before1955 if inrange(dif, -17, 17)
eststo: reg sum_srq20 before1955 if inrange(dif, -30, 30)
eststo: reg sum_srq20 before1955 if inrange(dif, -45, 45)
eststo: reg sum_srq20 before1955 if inrange(dif, -60, 60)
estadd scalar outcome_mean = r(mean)
esttab using table4_4.rtf, stats(N outcome_mean, fmt(%9.0g %9.2f))  nonumbers 

sum sum_srq20 if inrange(dif, -17, 17)	
sum sum_srq20 if inrange(dif, -30, 30)	
sum sum_srq20 if inrange(dif, -45, 45)	
sum sum_srq20 if inrange(dif, -60, 60)	


****************5. Additional Regressions
**********RD Plot 
gen single_= 1-married

gen single_under_curfew= single_*under_curfew
gen single_female_curfew= female*single_under_curfew

rdplot single_female_curfew z_depression, c(0) msize(tiny) graph_options(xlabel(-2.5(1)2.5)) title("Mental distress index") xtitle("") ytitle("Born before December 1955 (in months)")  p(5) ci(95) shade binselect(qsmvpr)
graph save "Graph" "C:\Users\gigi\Documents\ThinkPad_Backup_2024\Applied Economics MS\ECON 644 - Empirical Analysis II\Term Project\replication\tablesfigures\Panel_Exp.gph"


eststo clear
eststo: reg z_depression single_under_curfew female under_curfew poor_overall_health lim_social_interaction conflict sum_srq20 single_ if inrange(dif, -45, 45)

eststo: reg z_depression single_female_curfew female under_curfew poor_overall_health lim_social_interaction conflict sum_srq20 single_ if inrange(dif, -45, 45)

esttab using table4_6.rtf, stats(N outcome_mean, fmt(%9.0g %9.2f))  nonumbers 


asdoc reg z_depression single_female_curfew female under_curfew poor_overall_health lim_social_interaction conflict sum_srq20 single_ if inrange(dif, -45, 45), label

test single_female_curfew+female+under_curfew=0



log close






