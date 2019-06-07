% PRODUCT-1 PAVEMENT DESIGN TOOL
%%---------------------------------
%%master importer script to import traffic data
%%Matlab-only imports - uses xlsread function on "dataImport" file (defined
%%from the main script


%% ---PROBLEM SETTINGS READ ------
runVerbose = xlsread(dataImport,'info','b10:b11');        %boolean variable, if = 1, run in verbose mode, detailing every calc. step
%exportToPDF = runVerbose(2);                         %boolean variable. if = 1, make pdf files with the many graphs to use. Use exportPDF (dependency:: GhostScript). Disabled in this first release of Product-One
runVerbose = runVerbose(1);
createFigures = xlsread(dataImport,'info','b14:b18');  
[~,saveDataName,~] = xlsread(dataImport,'info','b21'); %name of the output files  (code will produce a .mat file with the calculation results and pdf files with graphs and many reports)
saveDataName = char(saveDataName); %name of the output files  
%(code will produce a .mat file with the calculation results and a XLS spreadsheet with graphs and many reports)
%OCTAVE ONLY: octave doesn't have the "string" function to convert cell-text to character strings. Use char instead.


%% ---PROBLEM DATA IMPORT----

%1 - Project location
if runVerbose
    disp('dataImport:: importing general info')
end
Loc = xlsread(dataImport,'info','e10:e11');
locX = Loc(1);
locY = Loc(2);
clear Loc;
startDate = xlsread(dataImport,'info','h10:h12');
startTimeStamp = datenum(startDate(1), startDate(2), startDate(3),18,0,0); %fixed to start at daytime (it may save problems when computing design 1/2 day traffic)
designLife = xlsread(dataImport,'info','h16');

%2 - Trial pav. structure and subgrade
if runVerbose
    disp('dataImport:: importing pavement trial structure info')
end
getPaveSummary = xlsread(dataImport,'pavStructure','m10:m14');
paveCrossSlope = xlsread(dataImport,'pavStructure','d13');
%paveType = getPaveSummary(1);       %%Boolean variable 1 = flexible, 2 = concrete
paveChipSeal = getPaveSummary(1);   %%Boolean variable 1 = chip seal surface, 0 = strong HMA or granular pavement (concrete by default will make 0) 
paveLayersNumber = getPaveSummary(2);
ACLayersNumber = getPaveSummary(3);
%2.1 - Locate depth of asph layers and total depth of pavement
totalDepth = getPaveSummary(4);
ACtotalDepth = getPaveSummary(5);
clear getPaveSummary;

paveStructure = xlsread(dataImport,'pavStructure','g10:j15');  %%Read a matrix loaded with the needed info about the pavement structure and the subgrade!
paveLevelInput = paveStructure(1,end);  %will read the Input level of the uppermost layer (will tell if using default values or local ones)
paveID = paveStructure(:,1);            %Get the ID of each material used (so that I can get its material properties from 
paveDepths = paveStructure(:,3);
ACPaveDepth  = paveStructure(1:ACLayersNumber,3);  %this column will contain the depth of each AC layer (needed in temperature profile)
clear paveStructure

%3 - Site climate
climateInputs = xlsread(dataImport,'info','m11:m13');  %boolean variable. if = 1, use local climate and don't construct simulation from INIA 
climateRandomSeed = climateInputs(3);
climateLvl2ForceRecalc = climateInputs(2);
climateLevel1 = climateInputs(1);  %boolean variable. if = 1, use local climate and don't construct simulation from INIA 
clear climateInputs

%NOTE: climate info for a Level 1 input (local from project's site) will be imported by the climateLoadLocal function

%5 - Read the user's settings on distress thresholds---
%Adopt distresses from NCHRP 1-37A
readDistresses = xlsread(dataImport,'info','r9:r10');
maxRutDepth = readDistresses(1);
maxIRI = readDistresses(2);
maxCracking = xlsread(dataImport,'info','r13:r16');   %cracking entered as transvsersal/longitudinal/alligator/reflective.
clear readDistresses;
initialDistress = xlsread(dataImport,'info','w9:w10');
initialIRI = initialDistress(2);
initialRutDepth = initialDistress(1);
clear initialDistress