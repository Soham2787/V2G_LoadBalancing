DATE OF SIMULATION: 2nd November 2024

This file contains instructions for executing the MATLAB simulation files created for the Course Project titled "Development of V2G communication and control system" for the course "EN 663: Electric Vehicle Grid Integration".

The simulation was conducted on MATLAB (Version 9.14.0.2674353 (R2023a) Update 7) on AMD Ryzen 9 5900X laptop with 8 cores and base speed of 3.30 Hz. The simulation should take about 1 minute to execute.

A] The simulation is conducted for:
	1) Maharashtra Summer 2023
		filename: MahaSummerSIM.m
	2) Delhi Summer 2023
		filename: DelhiSummerSIM.m
	3) Maharashtra Winter 2023
		filename: MahaWinterSIM.m
	4) Delhi Winter 2023
		filename: DelhiWinterSIM.m

B] Plots: 
	PLOT 1: A load plot, showing:
		1) Load Forecast (sourced from NITI Aayog's India Climate and Energy Dashboard)
		2) Balanced Load curve (result of the simulation)
		3) Total EV charging power (result of the simulation)
		4) Total EV discharging power (result of the simulation)
		5) Net EV power (result of the simulation)

	PLOT 2: Plot showing the power delivered by a charger to EV (positive) / delivered to grid (negative) 
						&
		The SOC as seen by the charge point
		for the entire period of one month over the simulation


C] How to run the simulations:
	1. Open the required simulation file from section A
	2. Run the file using 'F5'
	3. You will see two windows open, one with Plot 1, one with Plot 2.
	4. You can get new plots for PLOT 2, showing them for each charger (there are 100,000 chargers in the simulation). Press 'Ctrl + Enter' in Section 'Plot for one charger Power and 	   	SOC of EV connected to it' starting from line 353 of the code, to get these.
	5. In some cases you can get the SOC not reaching 80 %, this would be explained in the presentation. Please note, since there are 100,000 chargers it will require you to do 'Ctrl + 	   	Enter' in Section titled 'Plot for one charger Power and SOC of EV connected to it' (starting from line 353 of the code) a few times to see the actual result.
	6. To change assumed parameters:
		Number of EVs			: n 			[line 20]
		Range of Maximum powers		: P_max_UL 		[line 46], 	P_max_LL 	[line 47]
		Battery Capacity		: E_Ul 			[line 78],	 E_LL 		[line79]
		Power steps			: step_nos_charge 	[line 140], step_nos_discharge 	[line 141]
		Data				: inputData		[line 111]
	7. To change Data, save the data with first column titled 'time' containing time in format 'dd-MMM hha', and second column titled 'Hourly Demand Met (in MW)'. Save this as a '.csv' 	   	file in the same folder as the executing code. You can source this data from the EXCEL file named 'Yearly Demand Profile'. Input the name of the file in 		the inputData variable as a string.
		
		 
	