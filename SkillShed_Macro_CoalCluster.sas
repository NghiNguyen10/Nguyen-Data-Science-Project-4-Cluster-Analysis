libname onet "C:\OHIO UNIVERSITY PROJECTS\Skillshed\Onet"; run; /*You need to change the path to match where you want to your data folder*/
libname oews "C:\OHIO UNIVERSITY PROJECTS\Skillshed\OEWS"; run; 

/*Import raw data*/
/*Onet Knowledge*/
proc import datafile="C:\OHIO UNIVERSITY PROJECTS\Skillshed\Onet_Knowledge.csv" /*You need to change the path to match where you store your data*/
    dbms=csv replace
    out=onet.knowlegde;
    guessingrows=200; /* if omitted, the default is 20 */
run;

/*Onet Job Zones*/
proc import datafile="C:\OHIO UNIVERSITY PROJECTS\Skillshed\Onet_jobzones.csv" /*You need to change the path to match where you store your data*/
    dbms=csv replace
    out=onet.Jobzone;
    guessingrows=200; /* if omitted, the default is 20 */
run;

/*Onet Work Activities*/
proc import datafile="C:\OHIO UNIVERSITY PROJECTS\Skillshed\Onet_WorkActivities.csv" /*You need to change the path to match where you store your data*/
    dbms=csv replace
    out=onet.activity;
    guessingrows=200; /* if omitted, the default is 20 */
run;

/*Onet Work Context*/
proc import datafile="C:\OHIO UNIVERSITY PROJECTS\Skillshed\Onet_workcontext.csv" /*You need to change the path to match where you store your data*/
    dbms=csv replace
    out=onet.Context;
    guessingrows=200; /* if omitted, the default is 20 */
run;

/*Onet Skills*/
proc import datafile="C:\OHIO UNIVERSITY PROJECTS\Skillshed\Onet_skills.csv" /*You need to change the path to match where you store your data*/
    dbms=csv replace
    out=onet.Skills;
    guessingrows=200; /* if omitted, the default is 20 */
run;

/**************************************************************************************************************************************************************/
/*CLEANING RAW DATA*/
/*1. Clean Knowledge file*/
data onet.knowledge2;
set onet.Knowlegde;
if scale_name ne "Level" then delete;
keep SOC_code Title Element_Id element_name scale_name data_value;
run;

/*transpose knowledge file from long to wide*/
proc sort data = onet.knowledge2; by Soc_code Title; run;
Proc transpose data=Onet.knowledge2 out= onet.knowledge_wide; by Soc_code Title; id element_name; run;


/*2. Clean Job Zones file*/
data onet.jobzone2;
set onet.jobzone;
keep SOC_code Title Job_zone;
run;


/*3. Clean Work Activity file*/
data onet.Activity2;
set onet.Activity;
if scale_name ne "Level" then delete;
keep SOC_code Title Element_Id element_name scale_name data_value;
run;

/*transpose Work Activity from long to wide*/
proc sort data = onet.activity2; by Soc_code Title; run;
Proc transpose data=Onet.activity2 out= onet.Activity_wide; by Soc_code Title; id element_name; run;


/*4. Clean Work Context file*/
data onet.Context2;
set onet.Context;
if scale_name ne "Context" then delete;
keep SOC_code Title Element_Id element_name scale_name data_value;
run;

/*transpose Work Context file from long to wide*/
proc sort data = onet.Context2; by Soc_code Title; run;
Proc transpose data=Onet.Context2 out= onet.Context_wide; by Soc_code Title; id element_name; run;

/*5. Clean Skills file*/
data onet.Skills2;
set onet.skills;
if scale_name ne "Level" then delete;
keep SOC_code Title Element_Id element_name scale_name data_value;
run;

/*transpose Work Context file from long to wide*/
proc sort data = onet.skills2; by Soc_code Title; run;
Proc transpose data=Onet.skills2 out= onet.skills_wide; by Soc_code Title; id element_name; run;


/*COMBINE 4 ONET FILES INTO ONE*/
Data onet.SkillShed;
Merge Onet.Knowledge_wide(in=a) Onet.Activity_wide Onet.Context_wide Onet.Jobzone2;
by soc_code;
if a;
drop _name_;
run;
/*At this step, we have the large ONET matrix for all occupations*/

/*INPUT OCCUPATIONS OF INTEREST*/
/*Input the list of SOC codes for Growing occupations (Or new Emerging occupations)*/
/*Each SOC_Code needs to be entered manually in a pair of qoutation marks. For example: '25-2011.00' */
Data Onet.Grow_List;
input SOC_Code $ 13.;
cards ;
'25-2011.00'
'29-2052.00'
'31-1131.00'
'31-2021.00'
'31-9091.00'
'33-9032.00'
;
run;

/*Input the list of SOC codes for Declining occupations*/
/*Each SOC_Code needs to be entered manually in a pair of qoutation marks. For example: '25-2011.00' */
Data Onet.Decline_List;
input SOC_Code $ 13.;
cards ;
'23-2093.00'
'27-1026.00'
'43-3011.00'
'43-3031.00'
'43-3051.00'
'43-3061.00'
'43-4071.00'
'43-4151.00'
'43-4161.00'
'43-5032.00'
'43-6011.00'
'43-6014.00'
'43-9021.00'
'43-9061.00'
;
run;

/*********************************************************************************************************************/
/*SKILLSHED ANALYSIS*/
/*Create a list of growing occupations from inputs*/
proc sql noprint;
select distinct(SOC_Code) into :Grow_list separated by ","
from Onet.Grow_List;
quit;
%put &Grow_List;

/*Count the number of growing occupations*/
Proc sql noprint; select count(Soc_code) into :numgrow from Onet.Grow_List run;
%put &numgrow;

/*Create a list of declining occupations from inputs*/
proc sql noprint;
select distinct(SOC_Code) into :Decline_list separated by ","
from Onet.Decline_List;
quit;
%put &Decline_List;


/*Create a sub ONET dataset which contains only growing and declining occupations*/
Data ONET.OCC_List;
set ONET.Skillshed;
if SOC_code in (&Grow_list) or SOC_code in (&Decline_List);
if SOC_code in (&Decline_List) then Grow="N"; else Grow="Y";
run;

proc sort data=ONET.OCC_List; by grow title; run;

/*Calculate the Euclidian distances between growing and declining occupations*/
proc distance data=onet.OCC_List out=onet.Result method=euclid;
var interval (Administration_and_Management--job_zone);
id Title;
run;

/*Result*/
/*Grow*/
data onet.Final_results;
set onet.Result nobs=obscount;
if _n_ > (obscount-&numgrow);
run;

/*Print out SKILLSHED Results*/
proc print data=onet.final_results;run;

/***********************************************************************************************************************************/
/*GET WAGE TABLE*/
/*Import OEWS data*/
proc import datafile="C:\OHIO UNIVERSITY PROJECTS\Skillshed\OEWS\OH_oews_21.csv" /*You need to change the path to match where you store your data*/
    dbms=csv replace
    out=oews.OH_oews;
    guessingrows=250; /* if omitted, the default is 20 */
run;

Data oews.OH_oews;
set oews.OH_oews;
keep soc_code title A_Median;
run;

/*Get the wage table for Growing and Declining Occupations*/
Data oews.Wage;
set oews.OH_oews;
if SOC_code in (&Grow_list) or SOC_code in (&Decline_List);
if SOC_code in (&Decline_List) then Grow="N"; else Grow="Y";
Wage=A_Median/1000;
Drop A_Median;
run;

Proc sort data=oews.Wage; by grow title; run;

/*Print out WAGE TABLE*/
proc print data=oews.Wage;run;



/***************************************************************************************************************************************************/
/***************************************************************************************************************************************************/
/***************************************************************************************************************************************************/
/*CLUSTERED ANALYSIS*/
/*Create main ONET data for Cluster Analysis*/
Data onet.Cluster_Analysis_Main;
Merge Onet.Knowledge_wide(in=a) /*Onet.Activity_wide onet.context_wide*/ Onet.skills_wide;
by soc_code;
if a;
drop _name_;
run;

/*Input list of Occupations of interest*/
DATA Onet.occ_list_cluster;
input Soc_Code $ 13.;
cards;
'11-1011.00'
'11-1021.00'
'11-3013.00'
'11-3031.00'
'11-3051.00'
'11-3061.00'
'11-3121.00'
'11-9021.00'
'11-9041.00'
'11-9199.00'
'13-1041.00'
'13-1071.00'
'13-1082.00'
'13-1151.00'
'13-1199.00'
'13-2011.00'
'15-1299.00'
'17-1022.00'
'17-2071.00'
'17-2081.00'
'17-2112.00'
'17-2151.00'
'17-3029.00'
'17-3031.00'
'19-2042.00'
'19-5011.00'
'19-5012.00'
'33-9032.00'
'37-2011.00'
'43-1011.00'
'43-3031.00'
'43-3051.00'
'43-3061.00'
'43-5032.00'
'43-5071.00'
'43-5111.00'
'43-6014.00'
'43-9061.00'
'45-2093.00'
'47-1011.00'
'47-2073.00'
'47-2111.00'
'47-4061.00'
'47-5022.00'
'47-5023.00'
'47-5032.00'
'47-5041.00'
'47-5043.00'
'47-5044.00'
'47-5049.00'
'47-5081.00'
'47-5099.00'
'49-1011.00'
'49-3031.00'
'49-3042.00'
'49-9041.00'
'49-9043.00'
'49-9071.00'
'49-9098.00'
'49-9099.00'
'51-1011.00'
'51-4121.00'
'51-8099.00'
'51-9012.00'
'51-9021.00'
'51-9061.00'
'51-9198.00'
'51-9199.00'
'53-1047.00'
'53-3032.00'
'53-3033.00'
'53-7011.00'
'53-7051.00'
'53-7062.00'
'53-7065.00'
'53-7072.00'
'53-7121.00'
;
run;

/*Creat List of Occupations From Imput*/
proc sql noprint;
select distinct(SOC_Code) into :Clust_List separated by ","
from Onet.Occ_list_cluster;
quit;
%put &Clust_List;

/*Extract Occupations of Interest From Skillshed ONET Data*/
Data Sample; 
set onet.Cluster_Analysis_Main;
if Soc_code in (&Clust_List);
run;

/*WARD's method Cluster based on Knowledge and Skills*/
proc cluster data=SAMPLE method=ward ccc pseudo print=20 out=tree
plots=den(height=rsq);
var Administration_and_Management--Management_of_Personnel_Resource;
id Soc_code;
run;

/*Choose the ideal number of clusters and export the results (NEW)*/
proc tree data=Tree out=New nclusters=4 noprint;
height _rsq_;
id Soc_code;
run;

/*Match occupations in the clusters back into Shillshed file or later analysis*/
proc sort data=new; by soc_code;run;
proc sort data=sample; by soc_code;run;

data analysis;
merge new(in=a) sample;
by soc_code;
if a;
run;

/*
/*Sort the analysis file by cluster*/
/*proc sort data=analysis; by cluster;run;*/

/*Analyze the mean difference in skill and knowledge between clusters*/
/*
proc means data=analysis noprint; output out=avg;
var Administration_and_Management--job_zone;
 class cluster;
run;

data avg;
set avg;
if _stat_= "MEAN";
run;
*/

proc factor data=analysis method=PRINCIPAL n=2 score out=analysis2;
var Administration_and_Management--Management_of_Personnel_Resource;
ods output StdScoreCoef=Coef; 
run;

data graphic;
set analysis2;
n=_n_;
f11=.; f21=.;
if cluster =1 then f11=factor1;
if cluster =1 then f21=factor2;

f12=.; f22=.;
if cluster =2 then f12=factor1;
if cluster =2 then f22=factor2;

f13=.; f23=.;
if cluster =3 then f13=factor1;
if cluster =3 then f23=factor2;

f14=.; f24=.;
if cluster =4 then f14=factor1;
if cluster =4 then f24=factor2;
run;


proc sgplot data=graphic;
title "Coal Mining Clusters";
   scatter x=factor1 y=Factor2/ datalabel=n group=cluster markerattrs=(symbol=CircleFilled);
   ellipse x=f11 y=F21/outline fill transparency=0.8;
   ellipse x=f12 y=F22/outline fill transparency=0.8;
   ellipse x=f13 y=F23/outline fill transparency=0.8;
   ellipse x=f14 y=F24/outline fill transparency=0.8;
run;
