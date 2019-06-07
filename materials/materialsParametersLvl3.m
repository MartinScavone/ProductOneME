%%  - M.E. Pavement Design tool - %%%%
%%% PAVEMENT PROPERTIES IMPORTER  %%%
%
% Version 0.0 - 2018-06-26
%materials Parameters for Level 2 - Uy Literature default values
%Note: This script uses the variables in the MainCode environment, and so will drop variables there
%% - Retrieve materials' props. library
if runVerbose
    disp('importing materials" properties from library')
end
HMALibrary = xlsread(dataImport,'materialsCatalog','b9:l33');
% granularLibrary = xlsread(dataImport,'materialsCatalog','b37:l65');
% CTBLibrary
% subBaseLibrary


%% -ASPHALT CONCRETE MATERIALS' PROPERTIES

asphAbsorvipity = 0.93;             %Source 1993 paper
asphEmissivity = 0.93;              %Source 1993 paper
asphThermalConductivity = 1.0811;    %Source NCHRP 1-37 A pg 2.3.13 (average value, converted to Watt/[meter Celsius]

ACPlacementTemp = 140;               %Temperature at which the surface Hot/Warm Mix Asphalt layer is placed [deg. C] (used in initial temperature calculations)

asphCrackInfiltrationRate = 0.10;

%%parameters to calculate dynamic modulus E*
%prepare a matrix called "HMAparameters" containing the following 
%Percentage passing #200 mesh sieve / Volume of air voids / Volume of bitumen / Penetration at 25C

%Retrieve imported library of materials from "dataimport" source and then pick for the project's HMA layers (use HMAID variable, as defined in the Main code)
HMA_ID = paveID(find(paveID<100));  %all layer IDs lower than 100 are HMA layers.

%(column %vectors for each HMA layer, pick columns 5, 7, 8, and 9 from the HMALibrary)
%Use ismember instead of find to locate elements with multiple criteria. Trick from: https://www.mathworks.com/matlabcentral/answers/32781-find-multiple-elements-in-an-array
%OVERRIDE: Trick above doesn't work when the multiple criteria has 2+ entries with the same value. Using a slower for loop instead.
HMARowsToPick = zeros(length(HMA_ID),1);
for k = 1:length(HMA_ID)
    HMARowsToPick(k) = find(HMALibrary(:,1) == HMA_ID(k));
end
HMAP200 = HMALibrary(HMARowsToPick,5);
HMAVa   = HMALibrary(HMARowsToPick,7);
HMAVb   = HMALibrary(HMARowsToPick,8);
HMAP25c = HMALibrary(HMARowsToPick,9);
HMAparameters = [HMAP200 HMAVa HMAVb HMAP25c];

clear HMARowsToPick HMAP200 HMAVa HMAVb HMAP25c HMA_ID
clear HMALibrary

%% -GRANULAR MATERIALS AND SOILS' PROPERTIES
% Make up a table with the variables i need (or read it from an Excel file)
% - -Hydraulic conductivity
% - - resilient modulus (default parameters for the MRvs stress curve)
%