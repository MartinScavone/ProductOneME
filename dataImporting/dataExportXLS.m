% PRODUCT-ONE PAVEMENT DESIGN TOOL
%%---------------------------------
%%master exporter script to export select simulation results to a spreadsheet
%%Matlab-only imports - uses XLSREAD function on file with name:  finalName"saveDataName.xlsx" file (defined from the main script)

if runVerbose; disp('Spreadsheet Export:: Exporting simulated climate variables'); end
%% ---Export simulated climate---
%Target sheet: climate
auxDate = datevec(longTimestamp);

finalRowToExport = 9+length(longTimestamp)-1;    						%%%I'll program all outputs to go from row 9 downward
rangeToExport    = strcat('a9:d',string(finalRowToExport)) ;
export = xlswrite(char(finalName),{saveDataName},'climate','g2');             %export a tag with the name of the simulation run and date of completion
export = xlswrite(char(finalName),{datestr(now,23)},'climate','g3');          
export = xlswrite(char(finalName),auxDate(:,1:4),'climate',char(rangeToExport));   %export timeStamp

rangeToExport    = strcat('e9:e',string(finalRowToExport)); 
export = xlswrite(char(finalName),airTemp,'climate',char(rangeToExport));  %export temperature

rangeToExport    = strcat('f9:f',string(finalRowToExport));
export = xlswrite(char(finalName),humidity,'climate',char(rangeToExport));  %export humidity

rangeToExport    = strcat('g9:g',string(finalRowToExport));
export = xlswrite(char(finalName),windSpd,'climate',char(rangeToExport));  %export wind speed

rangeToExport    = strcat('h9:h',string(finalRowToExport));
export = xlswrite(char(finalName),rainFall,'climate',char(rangeToExport));  %export rainfall

rangeToExport    = strcat('i9:i',string(finalRowToExport));
export = xlswrite(char(finalName),sunRad,'climate',char(rangeToExport));  %export solar radiation

%% ---Export predicted traffic
if runVerbose; disp('Spreadsheet Export:: Exporting traffic prediction results'); end
%%%sheet = traffic
%%use 'simpleTrafficReport': column 1==years. Columns 2:6 - AADT cars, buses, trucks lt,md,hv

%%export AADT per category - - maybe this one can pass through from the dataInput sheet...   I'll think about it
finalRowToExport = 9+length(designAADT(1,:))-1;    						%%%I'll program all outputs to go from row 9 downward
rangeToExport    = strcat('b9:b',string(finalRowToExport)) ;
export = xlswrite(char(finalName),designAADT(1,:)','traffic',char(rangeToExport));  %export years...

rangeToExport    = strcat('d9:z',string(finalRowToExport)) ;
export = xlswrite(char(finalName),(designAADT(2:end,:))','traffic',char(rangeToExport));  %export ADT by category

rangeToExport    = strcat('ab9:af',string(finalRowToExport)) ;
export = xlswrite(char(finalName),simpleTrafficReport','traffic',char(rangeToExport));  %export simplified cat. counts


%% ---Export simulated HMA layers temperature
if runVerbose; disp('Spreadsheet Export:: Exporting HMA temperature simulation results'); end
%%%sheet HMA Layers Temperature

finalRowToExport = 9+length(airTemp)-1;    						        %%%I'll program all outputs to go from row 9 downward   						
if length(airTemp)>65500
   disp('Spreadsheet Export:: WARNING! Extremely long series to be exported, older XLS versions may truncate the data!') 
end
rangeToExport    = strcat('a9:d',string(finalRowToExport)) ;            %%%I'll program all outputs to go from row 9 downward
export = xlswrite(char(finalName),auxDate(:,1:4),'HMA Layers Temperature',char(rangeToExport));  %export short timestamp
clear auxDate;   %%i won't need the long timeSeries any longer

rangeToExport    = strcat('e9:e',string(finalRowToExport)) ;
export = xlswrite(char(finalName),airTemp,'HMA Layers Temperature',char(rangeToExport));  %export air temperature

rangeToExport    = strcat('f9:i',string(finalRowToExport)) ;
export = xlswrite(char(finalName),asphLyrTemp,'HMA Layers Temperature',char(rangeToExport));  %export surface and HMA layers temperature.


if runVerbose; disp('Spreadsheet Export:: Exporting Infiltration & Runoff module results'); end
%% ---Export results from the infiltration analysis
%%%sheet Infiltration Runoff

auxDate = datevec(shortTimestamp);

finalRowToExport = 9+termination-1;    						%%%I'll program all outputs to go from row 9 downward
rangeToExport    = strcat('a9:d',string(finalRowToExport)) ;
export = xlswrite(char(finalName),auxDate(:,1:4),'Infiltration Runoff',char(rangeToExport));  %export short timestamp

rangeToExport    = strcat('e9:e',string(finalRowToExport)) ;
export = xlswrite(char(finalName),shortRainfall,'Infiltration Runoff',char(rangeToExport));  %export short Rainfall

rangeToExport    = strcat('f9:f',string(finalRowToExport)) ;
export = xlswrite(char(finalName),surfaceInfiltration,'Infiltration Runoff',char(rangeToExport));  %export infiltration through surface

rangeToExport    = strcat('g9:g',string(finalRowToExport));   
export = xlswrite(char(finalName),surfaceRunoff,'Infiltration Runoff',char(rangeToExport));   %export surface runoff

rangeToExport    = strcat('i9:m',string(finalRowToExport));   
export = xlswrite(char(finalName),layersMoisture,'Infiltration Runoff',char(rangeToExport));   %export moisture content by vol

rangeToExport    = strcat('o9:s',string(finalRowToExport));   
export = xlswrite(char(finalName),MR,'Infiltration Runoff',char(rangeToExport));   %export resilient modulus

%% ---Export results from distress prediction
if runVerbose; disp('Spreadsheet Export:: Exporting Predicted Distresses'); end
%%%sheet Distress Prediction
% 
finalRowToExport = 9+termination-1;    						%%%I'll program all outputs to go from row 9 downward
rangeToExport    = strcat('a9:d',string(finalRowToExport)) ;
export = xlswrite(char(finalName),auxDate(:,1:4),'Infiltration Runoff',char(rangeToExport));  %export short timestamp

rangeToExport    = strcat('e9:e',string(finalRowToExport)); 
export = xlswrite(char(finalName),rutDepth(:,end),'Distress Prediction',char(rangeToExport));  %export rut depth

rangeToExport    = strcat('f9:f',string(finalRowToExport)); 
export = xlswrite(char(finalName),topDownCrack(:,1),'Distress Prediction',char(rangeToExport));  %export long cracking

rangeToExport    = strcat('g9:g',string(finalRowToExport)) ;
export = xlswrite(char(finalName),alligatorCrack(:,1),'Distress Prediction',char(rangeToExport));  %export alligator cracking

rangeToExport    = strcat('j9:j',string(finalRowToExport)) ;
export = xlswrite(char(finalName),IRI,'Distress Prediction',char(rangeToExport));  %export IRI

rangeToExport    = strcat('k9:k',string(finalRowToExport)) ;
export = xlswrite(char(finalName),PSI,'Distress Prediction',char(rangeToExport));  %export PSI

