%%%% - - - - - PRODUCT ONE - - - - %%%%
%%%% - M.E. Pavement Design tool - %%%%
%%%% - - - MAIN ROUTINE CODE - - - %%%%
%
% Version 1.0 30th... pre-Release          - 2019-09-16 
% Version 0.5 Many changes everywhere!     - 2019-05-20
% Version 0.3 MR Routine added             - 2019-01-22
% Version 0.2 Win-Friendly/Octave-Friendly - 2018-10-19
%%
%% ------INITIALIZATION------------
%
clear variables
clc
%%
disp('Starting PRODUCT-ONE M.E PAVEMENT DESIGN TOOL')
%%CODE INTEGRITY CHECK
%%Run a subscript to check if we have the necessary input files, addpaths
%%and (octave only) install I/O package should it not be there
%%<<integrityCheck.m is located in the program's main folder!>>
run integrityCheck.m;
%%%<< the isThisOctave boolean variable is to be used to check if you are
%%%on Matlab or GNU-Octave>>
%
%Ask the user the name of the XLS/XLSX file to read the inputs from.        
dataImport = input('Specify the name of the XLS/XLSX file to read the inputs from (between single quot. marks)...  ');
%
%% ------SETTINGS READ-------------
%--Read the config. settings--- 
%%(should the code run silently/verbose; should the code provide output--

disp('starting design problem data import')
if isThisOctave
    run mainDataImportOCT.m
else
    run mainDataImportXLS.m
end

%% --------DATA IMPORT-------------
%--Bring all the needed imports from the spreadsheets--
%
%1 - Project location
%2 - Trial pav. structure and subgrade
%3 - Site climate
%%>>MOVED TO mainDataImport script
%4 - Traffic
%Bring the matrix of all axes passes.
%A) import the traffic count from dataImport
if runVerbose
    disp('importing traffic and weight data')
end
if isThisOctave  %running Octave - use the odsRead importer for traffic
    run trafficDataImporterOCT.m
else  %running Matlab - use the xlsRead importer for traffic
    run trafficDataImporterXLS.m    
end
disp('Input data imported successfully')

run 'axlesWeights.m';  %script with the vectors having the load ranges for each type of axle  << located in /trafficProcessing folder>>

%% --Initialize Materials' Properties
if paveLevelInput == 1
  %read from an auxiliary file the many inputs   --> auxiliary script to do the import.
  
  %%<<the materialsParametersLvlX.m scritps are in /materials folder>>
  run 'materialsParametersLvl1.m'
elseif paveLevelInput ==2
  run 'materialsParametersLvl2.m' 
elseif paveLevelInput ==3
  run 'materialsParametersLvl3.m'
else
  error('Illegal level of input for pavement materials. Stopping Execution!')
end

%% ------
disp('Program ready to run')
disp('simulation timestep = 12h')   %%UPDATE JUN 18/2018 - - PAVEMENT PERFORMANCE SIMULATION WILL RUN ON A 12-h cycle (FIXED AT 6AM-6PM)
fprintf('Project"s design life is %g years\n', designLife)

%% -----INPUT PRE-PROCESSING 01 - GENERATION OF SIMULATED CLIMATE TIMESERIES-----
%- RUN THE climateSimulator.m FILE TO GENERATE THE SITE'S VIRTUAL WEATHER STATION

if climateLevel1
  %This is the case I have climate records from the very site of the pavement project
  %Create the script (use the simulator and remove the interpolation code)
  if runVerbose 
      disp('Simulation will use local climate input [level 1]')  
  end
  %%<climateLoadLocalXXX arelocated in /dataImporting/ folder
  if isThisOctave
      climateData = climateLoadLocalOCT(dataImport,runVerbose);   
  else
      climateData = climateLoadLocalXLS(dataImport,runVerbose);  
  end 
else
  %This is the case I don't have local records, I rely on INIA DB.
  if runVerbose
      disp('Simulation will use INIA Data for climate inputs [level 2]')
  end
  %%<climateSimulator is located in /climate/ folder
  climateData = climateSimulator(locX,locY,runVerbose,climateLvl2ForceRecalc);
end

%UPDATE 2018-09-05 - - now that I have the raw climate data, use the climate scrambler to mix ehter Lvl1 and LVl2 site's climate.
%%<<the ClimateScrambler script is in /climate folder>
climateData = climateScrambler(climateData,climateRandomSeed,designLife,startTimeStamp,runVerbose); 

%Break climateData by columns (all the needed variables):: climateMatrix = [timestamp temp hum wspd rain srad];
longTimestamp = climateData(:,1); %temporal calculation step = 1 hour (calculated in the climateSimulator)
shortTimestamp = shortTimestamp(longTimestamp);  %auxiliary function that will create a "short" timestamp vector (giving a value every day at 6AM and 6PM -start of daytime and nighttime)
airTemp = climateData(:,2);
humidity = climateData(:,3);
windSpd = climateData(:,4);
rainFall = climateData(:,5);
sunRad = climateData(:,6);
clear climateData;
%% -----INPUT PRE-PROCESSING 02 - CALCULATE HMA TEMPERATURE FROM CLIMATE DATA   
%Update 2018-06-20 - move the HMA temperature calculations here, adapt the
%prev. generated code to give output in hourly and 1/2-day wide time-series

if runVerbose
    disp('Climate/Materials data processing: Calculating temperature in HMA Layers')
end
%%<<HMALayersTemperature are in the /materials folder
asphLyrTemp = HMALayersTemperature(longTimestamp,airTemp,humidity,windSpd,sunRad,ACPlacementTemp,ACPaveDepth,asphAbsorvipity,asphEmissivity,asphThermalConductivity,runVerbose);   %Calculate hourly temperature in AC layers
%%<<avgDown is in the program's root folder
shortAsphLyrTemp = avgDown(asphLyrTemp,longTimestamp,shortTimestamp);

%% -----INPUT PRE-PROCESSING 02 - CALCULATE GRANULAR BASES SWCC AND DARCY PERMEABILITY FUNCTIONS
%%Update 2018-10-05 - Adopt the SWCC equation in the MEPDG (Xi et al, 1994)
%%and use it to get the material's hydraulic conductivity at any degree of
%%moisture (as in Fredlund et al, 1994).

if runVerbose
    disp('Climate/Materials data processing: Calculating SWCC and k_unSat for granular materials')
end
%%<< the kUnsatSWCC script is in the /materials folder
%%note: granSWCCParameters is defined in the "materialsParametersLvlXX.m" script
granularKSWCC = kUnsatSWCC(granSWCCParameters,runVerbose);


%% -----INPUT PRE-PREOCESSING 03 - IMPORT TRAFFIC DATA AND CONSTRUCT THE 1/2-DAY-LONG TRAFFIC SIMULATION.
% UPDATE 2018-06-20::  Use the shortTimetamp vector - as defined at the pre-processing 02 routines
%%<<these scripts are in the /trafficProcessing folder.

[designTraffic,designAADT] = trafficSimulator(shortTimestamp,AADTbaseYear,AADTGrowthRate,AADTMonthlyDistr,AADTDailyDistr,AADTHourlyDistr);
%output of this sub-routine: vectors having hourly passes of each type of each vehicle category.

[axlesSingleLight, axlesSingle6, axlesSingle105, axlesTandem18, axlesTandem10, axlesTandem14, axlesTridem] = trafficToAxes(designTraffic,trafficLoadPerc,trafficAxleLoad);
%output of this second sub-routine: axles by weight category (0.5-ton sensitivensess) per hour
%column vectors, the number of rows is the length of the timeStamp vector


%% -----PREPARE THE VARIABLES FOR THE SIMULATION-----
%APPROACH: ALL THE CLIMATE CALCULATIONS WILL BE "DETERMINISTIC" USING THE SIMULATED climateData
%This will deviate from original EICM framework (in which rainfall and infiltration to subbase was probability-based
%And I will also use actual sunRadiation instead of the equations in RD-90-033

termination = length(shortTimestamp);

%INITIALIZE VARIABLES - Climate and granulars' hydraulic proprieties
surfaceRunoff = zeros(termination,1);           %record how much rainfall may not enter the pavement and keep running.
surfaceInfiltration = zeros(termination,1);     %record how much rainfall may enter the pavement and infiltrate downward (these 3 variables will evolve over time as cracking increases, can't calculate them now)
layersMoisture = zeros(termination,paveLayersNumber-ACLayersNumber+1);  %%moisture content on each layer PLUS THE SUBGRADE! (percent)
lateralRunoff = layersMoisture;                 %record how much water escapes through the layers as sideways flow (m3/m2)
layersMoisture(1,:) = granHumidity(:,1)';       %initialize values in layersMoisture
shortRainfall = zeros(termination,1);           %I will store the accum. rainfall in short-timestamp format. Used at the end for plotting

%INITIALIZE VARIABLES - Stress-strain modeling // HMA Layers dynamic modulus E*
%%Note: E* for each axle category is a 3-d array, each layer represents a timestamp
if runVerbose
   disp('Pavement materials preprocessing: Calculating HMA Dynamic Modulus') 
end
%:0 Get the speed of each axle type
axlesSpeed = axleSpeedFromVehicleSpeed(AADTSpeed); %this little function will convert the speed input by vehicle cat to the speed of each axle type (averaging the speeds of all vehicles that have each axle type)

%define this auxiliary point in granMR to prevent matlab from crashing when running
auxLGMR = length(granMR);

%1: Load freq, radius of load, and HMA E* for light single axles
aSingleLight = wheelFootprint(axlesSingleLWeights,2,30);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aSingleLight)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadSL, freqOfLoadSL] = HMALoadFrequency(ACPaveDepth,AADTSpeed(1),aSingleLight,EdynAux,granMR(auxLGMR));   
   %%Update 2019-02-17. Correct bug in HMALoadFrequency -> needs a preliminary value of HMA's E* and subgrade MR to compute the effective length of load
EDynSingleLight= HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadSL,paveLevelInput,runVerbose);   %Create additional function to calculate E* for the light axles
HMAPoissonSingleLight = HMAPoisson(EDynSingleLight,paveLevelInput,runVerbose);

%2: Load freq, radius of load, and HMA E* for 6ton single axles
aSingle6 = wheelFootprint(axlesSingle6Weights,2,80);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aSingle6)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadS6, freqOfLoadS6] = HMALoadFrequency(ACPaveDepth,AADTSpeed(2),aSingle6,EdynAux,granMR(auxLGMR));
EDynSingle6= HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadS6,paveLevelInput,runVerbose);  %Create additional function to calculate E* for the 6-ton single axles
HMAPoissonSingle6 = HMAPoisson(EDynSingle6,paveLevelInput,runVerbose);

%3: Load freq, radius of load, and HMA E* for 10.5ton single axles
aSingle105 = wheelFootprint(axlesSingle10Weights,4,90);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aSingle105)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadS105, freqOfLoadS105] = HMALoadFrequency(ACPaveDepth,AADTSpeed(3),aSingle105,EdynAux,granMR(auxLGMR));
EDynSingle105= HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadS105,paveLevelInput,runVerbose);   %Create additional function to calculate E* for the 10.5-ton single axles
HMAPoissonSingle105 = HMAPoisson(EDynSingle105,paveLevelInput,runVerbose);

%4: Load freq, radius of load, and HMA E* for 18ton tandem axles
aTandem18 = wheelFootprint(axlesTandemWeights,8,90);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aTandem18)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadT18, freqOfLoadT18] = HMALoadFrequency(ACPaveDepth,AADTSpeed(4),aTandem18,EdynAux,granMR(auxLGMR));
EDynTandem18= HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadT18,paveLevelInput,runVerbose);   %Create additional function to calculate E* for the 18-ton tandem axles
HMAPoissonTandem18= HMAPoisson(EDynTandem18,paveLevelInput,runVerbose);

%5: Load freq, radius of load, and HMA E* for 14ton NH tandem axles
aTandem14 = wheelFootprint(axlesTandem14Weights,6,90);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aTandem14)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadT14, freqOfLoadT14] = HMALoadFrequency(ACPaveDepth,AADTSpeed(6),aTandem14,EdynAux,granMR(auxLGMR));
EDynTandem14=  HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadT14,paveLevelInput,runVerbose); %Create additional function to calculate E* for the 14-ton tandem NH axles
HMAPoissonTandem14= HMAPoisson(EDynTandem14,paveLevelInput,runVerbose);

%6: Load freq, radius of load, and HMA E* for 10ton SW tandem axles
aTandem10 = wheelFootprint(axlesTandem10Weights,4,80);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aTandem10)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadT10, freqOfLoadT10] = HMALoadFrequency(ACPaveDepth,AADTSpeed(5),aTandem10,EdynAux,granMR(auxLGMR));
EDynTandem10=  HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadT10,paveLevelInput,runVerbose); %Create additional function to calculate E* for the 10-ton tandem axles
HMAPoissonTandem10= HMAPoisson(EDynTandem10,paveLevelInput,runVerbose);

%7: Load freq, radius of load, and HMA E* for 25ton tridem axles
aTridem = wheelFootprint(axlesTridemWeights,12,90);
EdynAux = HMAModulus(shortAsphLyrTemp(6,:),HMAparameters,10^3.*ones(ACLayersNumber,length(aTridem)),paveLevelInput,0);   %%auxiliary E* calcuation, needed to get a reference E* value to compute the frequency of load with the Odemark's approach.
[timeOfLoadTri, freqOfLoadTri] = HMALoadFrequency(ACPaveDepth,AADTSpeed(7),aTridem,EdynAux,granMR(auxLGMR));
EDynTridem   = HMAModulus(shortAsphLyrTemp,HMAparameters,freqOfLoadTri,paveLevelInput,runVerbose);  %Create additional function to calculate E* for the 22-ton tridem axles
HMAPoissonTridem= HMAPoisson(EDynTridem,paveLevelInput,runVerbose);

%INITIALIZE VARIABLES - MR FOR THE GRANULAR LAYERS
MR = zeros(termination,1+paveLayersNumber-ACLayersNumber);  %prepare matrix for the actual MR values. Each col. is the MR(t) for each granular layer PLUS the sub-grade.

%INITIALIZE VARIABLES - distress
rutDepth=zeros(termination,1+length(paveDepths));           % for each layer, and all summed up! metric Units [m]
alligatorCrack = zeros(termination,ACLayersNumber);   % units: percentage of lane area
 topDownCrack = zeros(termination,1);     % units: m/km  [MEPDG's are ft/mile]  V-2019-09-16 PRE-RELEASE:: DISABLE TOP-DN CRACKING [keep a vector of zeros not to modify the IRI function] (MEPDG'S MODEL IS NOT WORKING PROPERLY, NEEDS FURTHER INVESTIGATION)
% reflectiveCrack = zeros(termination,1);  % units: percentage of lane area
% transvCrack = zeros(termination,1);      % units: m/km - DISREGARDED AS THESE ARE DUE TO COLD WEATHER AND WOULD'NT OCCUR IN A WARM CLIMATE (SHOWN BY CALIENDO, 2012))

IRI = zeros(termination,1);                                 % Metric Units [m/km]
PSI = zeros(termination,1);              % units: adim. - - TBUsed for comparison against AASHTO '93

%% -----RUN THE PAVEMENT SIMULATION-------------
for k = 1:termination
  currentTime = datevec(shortTimestamp(k));
  currentYear = currentTime(1);
  currentMonth = currentTime(2);
  currentDay = currentTime(3);
  currentHour = currentTime(4);   
  if runVerbose
  %Report date being analyzed. Octave's DateNum and DateVec functions jump 1 unit each day!
    fprintf('Analyzing pavement condition on date %g - %g - %g at %g :00  -- %g percent completed. \n', currentYear, currentMonth, currentDay, currentHour, k*100/termination)
  end
  
  %%firstly - run climateModule at time i
  %<<climateModule located in /climate folder 
  run 'climateModule.m';   
  
  %CALCULATE THE MATERIALS MR AT TIME k
  %use auxiliary "calculateMR" function  - - Stored in /materials folder
  MR(k,:) = calculateMR(gran_ID,layersMoisture(k,:)',granMR,granHumidity(:,2),granHumidity(:,1));
  %function MRactual = calculateMR(materialID,moistureContent,MRSat,OptMistureSaturationLevel,OptMoisture in % vol)
  %note: layersMoisture is defined here, updated in the "climateModule.m" %script
  %      and granMR, gran_ID, and granHumidity (opt. moisture content and matching saturation) are defined in "materialsParametersLvlX.m script
  % I also need to transpose the actual humidity values to prevent the function from mismatching dimensions
  
  %% Compute stress and strains for each type of load application.
  %%Program a MLE front-end that will run the routines to calculate stresses and strains for
  %%each type of axle (single/tandem/tridem) at time k and store the results to be passed on to the distress module
   
  % MLEFrontEnd scrtipt is in elasticLinearAnalysis folder
  run 'MLEFrontEnd.m'  
  
  
   %% Calculate distress increase
  if runVerbose
  %Report date being analyzed. Octave's DateNum and DateVec functions jump 1 unit each day!
    fprintf(' \t Computing distress increase on date %g - %g - %g at %g :00 \n', currentYear, currentMonth, currentDay, currentHour)
  end
  
  %Call the front-end calculator. It will compute all the distresses of interest, IRI, and PSI at shortTimestamp t(k)
  run 'rutDepthCalcFrontEnd.m';
  run 'alligatorCalcFrontEnd.m';
    
  %%update v2019-04-04: Some rut-depth values hit the CMPLX plane at times.
  %force a Re(rutDepth)
  rutDepth(k,:) = real(rutDepth(k,:));
  
  run 'IRIPSICalcFrontEnd.m';%% IRI and PSI calculator need the k-th value of all the distresses done, thus it must be called last!

end   %%end to time-dependent pavement performance Simulation!

%% -------CREATE FIGURES--------
%recall the "createFigures" config. variable
%value 1 = figures for climate
%value 2 = figures for traffic
%value 3 = figures for materials' properties
%value 4 = distress generation
%value 5 = reserved for future use
%%< the figure-creation tools are in the /plottingTools folder>

if createFigures(1) >0
    plotted15 = plotClimateVariables(longTimestamp,airTemp,humidity,windSpd,sunRad,rainFall);
end
    %figures 21
if createFigures(2)>0
    [plotted21,simpleTrafficReport] = plotTrafficData(shortTimestamp,designAADT(2:end,:));  %%added correection cause 1st row of designAADT is the year timestamp!
end
if createFigures(3)>0
    %figure 31, 32--
    plotted31 = plotHMATemperature(longTimestamp,airTemp,asphLyrTemp);
    plotted3233 = plotSoilHydraulics(shortTimestamp, shortRainfall,layersMoisture,surfaceInfiltration, surfaceRunoff);
    plotted34 = plotMR(shortTimestamp,MR);
end
if createFigures(4)>0   
     plotted4142 = plotRutDepth(shortTimestamp,rutDepth);
%    plotted4344 =
%    plotAlligator(shortTimestamp,alligatorCrack,topDownCrack);
%    %V2019-09-16: disabled topDown cracking export!
     plotted4344 = plotAlligator(shortTimestamp,alligatorCrack);    
     plotted45 = plotIRIPSI(shortTimestamp,IRI,PSI);
end
% if createFigures(5)>0
%     %plotted = plot whatever else
% end

%check if any plot didn't take place
plotCheck = plotted15*plotted31*plotted3233*plotted34*plotted4142*plotted4344*plotted45;
if runVerbose
    if plotCheck == 0
        disp('Uh-oh:: at least one of the plots did not generate')
        failyPlot = [plotted15 plotted31 plotted3233 plotted34 plotted4142 plotted4344 plotted45];
        auxPlotList = [string('figure 1-5'), string('Figure 31'), string('Figure 32-33'), string('Figure 34') string('Figure 4142') string('Figure4344') string('Figure45')];
        fprintf('The plots in %s did not generate properly \n',auxPlotList(failyPlot==0));
    
    else
        disp('All plots generated OK')
    end
end


%% ----NUMERICAL DATA EXPORT TO SPREADSHEETS----
%first bring the spreadsheet template to the working folder and rename it
%with the name given by the user

finalName = strcat(saveDataName,'.xlsx');
copyfile('./dataImporting/dataExportTemplate.xlsx',char(finalName))   %%<< debugged, 2019-02-05

%Program these modules
if isThisOctave
    run dataExportOCT.m
else
    run dataExportXLS.m
end


%% -------DATA EXPORT TO PDF OUTPUTS------------

%%----------AS OF FEB 22ND 2019, NOT INCLUDING PDF OUTPUT IN THIS RELEASE!--------
%check the variable exportToPDF
%use the saveDataName name for the names of the output files

%syntax is >> export_fig FILENAME -pdf -append

%% ---CODE CLOSE-UP - CLEAN THE VARIABLES THAT AREN'T WORTHWHILE FROM THE WORKSPACE---
doTheCleanup = input('Perform Workspace cleanup (remove unnecessary variables)? - - 1 means "Yes"........');
if doTheCleanup
    run workspaceCleanup.m
end

%update V2019-05-20: move save numerical output to the very end (after the workspace cleanup)
disp('Pavement Simulation completed!')
fprintf('Saving numerical outputs to %s .mat \n',saveDataName)
finalName = sprintf('%s.mat',saveDataName);
save(finalName); 

disp('----------All completed!-----------')