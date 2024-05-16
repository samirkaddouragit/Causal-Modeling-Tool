
=====================================================================
README
Causal Analysis Tool
Samir Kaddoura
=====================================================================

To run, open both server.R and ui.R and click "Run app" on either.

1) Set of guidelines to use the tool
	- Please make sure the inputted file is a csv file.
	- Please check that the treatment variable and outcome variable are different.
	- Please choose a continuous variable for outcome, and either a continuous or a binary variable for treatment.
	- Please check that neither the treatment nor the outcome variable are selected as control variables.
	- If running an IV regression, please check the IV is neither an outcome, a treatment, or a control variable.
	- Select at least two control variables if running a Causal Forest.

=================================================================================================================================================================================================================

2) Model understanding
	2a) General Causal Modeling Framework:
		- Select 3 categories of variables: 1 outcome, 1 treatment, 1 or many controls.
		- Outcome variable: The variable of which you wish to study the changes.
		- Treatment variable: The variable of which you wish to observe the effect on the outcome.
		- Controls: Variables that may also affect the outcome, but whose effect you are not interested in,

	Example: You wish to study the effect of drinking on mental health. 
	Your outcome will be mental health. 
	Your treatment will be drinking or not drinking.
	Your controls can be age, sex, socio-economic status, education level etc... (Variables that can be correlated with mental health, included in the model to isolate the effect of drinking.)

	2b) Regression Adjustment (RA):
		- Choose this model if you have a continuous treatment or a binary treatment.
		- A regression adjustment returns how much the treatment affects the outcome on average.
	
	2c) Matching:
		- Only available for binary treatment, but more robust than regression adjustment as it matches observations in both groups that are as similar as possible, to control for confounders.

	2d) Instrumental Variable (IV) Regression: 
		- Potential control variables can be omitted for many reasons: they could be simply forgotten, they could even be unquantifiable.
		- In this case, you'll want an IV.
		- Choosing a good IV can be difficult. You need to satisfy the following three conditions.
		- Exclusion: IV only related to outcome via treatment.
		- Independance: IV unrelated to omitted variables.
		- Relevance: IV correlated to treatment.
		- To help understand those relationships, we produce the directed Acylic Graph (DAG). The DAG shows the desired relationships between variables to produce a good IV.
	
	Example: You wish to study the effect of charter vs public schools on future earnings.
	- You believe that a student's inate ability is a factor however, but you can't quantify it.
	- Randomly assigning public or charter is an IV. 
	- Since it is random, it is unrelated to ability (Independance).
	- It determines which school you go to so it is related to the treatment (Relevance).
	- It only affects earnings via determining which school you go to (Exclusion).

	2e) Causal Forest:
		- Treatment effect is often not static, it moves as other variables move: that is the Conditional Average Treatment Effect (CATE).
		- The Causal Forest allows you to model the CATE.
		- It allows you to determine the range in which the treatment effect fluctuates, as well as which variables affect it and by how much.
	Example: You wish to study the effect of alcohol on mental health.
	- You believe alcohol to affect mental health differently for different individuals.
	- Individuals from a lower socio-economic background may suffer more as a result of alcohol.
	- This is captured in the CATE, which shows how a lower socio-economic background changes the effect of drinking on mental health.

=======================================================================================================================================================================================================================

3) Model Output interpretation

	3a) Regression Adjustment (RA):
		- Returns corresponding interpretation of Average Treatment Effect (ATE) as well as significance of ATE.
		- If the ATE is significant, returns a linear plot showing the marginal effect of treatment for continuous treatment.
		- If the ATE is significant, returns a boxplot showing the distribution of the dependent variable per group of the binary treatment.
		- No plot returned if ATE not significant.
	
	3b) Matching:
		- Only available for binary treatment. Will raise warning if continuous treatment chosen.
		- Takes a random sample of 10 000 observations if dataset too large.
		- Will return matching generated ATE, as well as significance.
		- Returns a boxplot showing the distribution of the dependent variable per group of the binary treatment.
	
	3c) Instrumental Variable (IV) Regression:
		- Returns Directed Acyclic Graph (DAG).
		- Returns if exclusion and independence are justified. If both are, confirms that the IV is potentially good. If either isn't, recommends choosing another IV.
		- Runs weak instrument test. Returns strength or weakness of IV accordingly.
		- Runs Wu-Hausman test. Confirms or denies endogeneity problem accordingly.
		- If no endogeneity problem, returns linear model treatment, otherwise, returns IV regression treatment.

	3d) Causal Forest:
		- Only available for binary treatment.
		- 80/20 Train/Test random split.
		- Trains Causal Forest and generates control importance on treatment.
		- Retains top 50% of most important variables.
		- Generates best linear projection of those important variables to obtain the effects of each control on the Conditional Average Treatment Effect (CATE).
		- If any condition is significant, returns the CATE, alongside its minimum, maximum, and average, a table of the conditions (controls that affect the CATE) and their estimates, and a plot of the importance of the top 50% of variables.
		- Otherwise, treatment effect not conditional, returns simple ATE.

