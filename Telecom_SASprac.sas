libname telecom "/folders/myshortcuts/MySAS";


/* import datafile - CSV engine */
proc import datafile="/folders/myshortcuts/MySAS/telecomm.csv"
	dbms=csv
	out=telecom.sasprac
	replace;
run;

/* Change all "No ... service" in dataset to "No" response for formatting */
/* Find a more elegant way to change both strings in the same line  */
data i_sasprac;
	set telecom.sasprac;
	array vars [*] _character_;
   	do i = 1 to dim(vars);
     	vars[i] = tranwrd(vars[i], 'No internet service', 'No');
     	vars[i] = tranwrd(vars[i], 'No phone service', 'No');
   	end;
   	drop i;
run;


proc format; 
	value $ bin 'No' = 0
			    'Yes' = 1
			    other = .;
				 
	value $ gender 'Male' = 0
				   'Female' = 1
				   other=.;
				 
	value $ internet 'No' = 0
				     'DSL' = 1
				     'Fiber optic' = 2
				      other=.;
	
	value $ contract 'Month-to-month' = 0
				    'One year' = 1
				    'Two year' = 2
				    other = .;
	
	value $ pay 'Bank transfer (automatic)' = 1
			    'Credit card (automatic)' = 2
			    'Electronic check' = 3
			    'Mailed check' = 4
			   other = .;
run;

title "Review of Variable Categories";
proc freq data=telecom.sasprac;
	tables streamingmovies multiplelines internetservice contract paymentMethod;
run;
title;

/* Find better way to list out all variables - maybe an array/macro */
/* outputting a table for missing data to confirm the number of missing values for later imputation */
data work.coded_telecom work.tele_missing;
	set work.i_sasprac;
	format contract $contract. 
		   internetservice $internet.
		   gender $gender. 
		   PaymentMethod $pay.
		   partner dependents phoneservice multiplelines OnlineSecurity OnlineBackup DeviceProtection
		   techSupport streamingTV streamingMovies paperlessBilling Churn $bin.;
		   output work.coded_telecom;
	if totalcharges eq . then output work.tele_missing;	  
run;

/* Verify the coded formats are correct */
title "Verify Variable Coding";
proc freq data=work.coded_telecom;
	tables contract internetservice gender PaymentMethod partner dependents 
		   phoneservice multiplelines OnlineSecurity OnlineBackup DeviceProtection
		   techSupport streamingTV streamingMovies paperlessBilling Churn;
run;
title;

title "Means Comparison - Pre Hot Deck Imputation";
proc means data=telecom.sasprac;
	var totalcharges;
run;

title;

/* Hot deck imputation method */
proc surveyimpute data=work.coded_telecom method=hotdeck(selection=srswor) seed=503 ndonors=1;
var totalCharges;
cells Gender Dependents SeniorCitizen PhoneService InternetService;
output out=work.tele_impute;
run;

title "Means Comparison - Post Hot Deck Imputation";
/* For comparison with data prior to imputation method */
proc means data=work.tele_impute;
	var totalCharges;
run;

title;

