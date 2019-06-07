%% PRODUCT-ONE PAVEMENT DESIGN TOOL
%%---------------------------------
%%master importer script to import traffic data
%%OCTAVE 4.0+-only imports - uses XLSREAD function on "dataImport" file (defined
%%from the main script
%
%V2 2019-02-22: RESPONDS TO MODIFIED DATAIMPORT SPREADSHEET.
%The dataImport spreadsheet now contains a selection of distr. factors for
%level2 or level3 design; the importer will read an automatically-populated
%table based on the user's Level of Input and functional classification
%Only need to distinguish level1 from level 2/3

%%this was originally a part from the main code, but i move it aside Because
% a) it was using too many lines in the main code
% b) i need a parallel code for Octave


AADTbaseYear = xlsread(dataImport,'trafficCountInput','g19:g41');
AADTGrowthRate = xlsread(dataImport,'trafficCountInput','e19:e41');
AADTSpeed = xlsread(dataImport,'trafficCountInput','i19:i41');
AADTLevelOfInput = xlsread(dataImport,'trafficCountInput','m10:m11');

if AADTLevelOfInput(1) == 1  %inputs for Level 1
    AADTMonthlyDistr = xlsread(dataImport,'trafficCountInput','c49:n71');
    AADTDailyDistr   = xlsread(dataImport,'trafficCountInput','t49:z71');
    AADTHourlyDistr  = xlsread(dataImport,'trafficCountInput','bf49:bh71');     %update jun 20th, 2018 - Use daytime/nighttime traffic distribution now.
else %inputs for Level 2 // 3 AUTOMATICALLY SELECTED IN THE SPREADSHEET!
    AADTMonthlyDistr = xlsread(dataImport,'trafficCountInput','c79:n101');
    AADTDailyDistr   = xlsread(dataImport,'trafficCountInput','t79:z101');
    AADTHourlyDistr  = xlsread(dataImport,'trafficCountInput','bf79:bh101');
end

%B) import weight record per category
if AADTLevelOfInput(1) == 1  %inputs for Level 1    
    trafficAxleLoad = xlsread(dataImport,'trafficLoadInput','g13:s104');
    trafficLoadPerc = xlsread(dataImport,'trafficLoadInput','e13:e105');
elseif AADTLevelOfInput(1) == 2  %inputs for Level 2
    trafficAxleLoad = xlsread(dataImport,'trafficLoadInput','g113:s204');    
    trafficLoadPerc = xlsread(dataImport,'trafficLoadInput','e113:e204');    
elseif AADTLevelOfInput(1) == 3   %inputs for Level 3 
    trafficAxleLoad = xlsread(dataImport,'trafficLoadInput','g213:s304');    
    trafficLoadPerc = xlsread(dataImport,'trafficLoadInput','e213:e304');    
end