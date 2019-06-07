function [climateRecord] = climateLoadLocalOCT(srcSpreadsheet,verbose)
%function [climateRecord] = climateLoadLocalOCT(srcSpreadsheet,verbose)
%   this function will load a Level 1 climate record from the source OpenDoccument spreadsheet srcSpreadsheet
%

if verbose
    disp('Climate records import starting....')
end
%1 - ask for cheking the spreadsheet name is ok
checkFilename = input(sprintf('Please confirm the name of the spreadsheet to import from... (1 = yes, currently %s) .....',srcSpreadsheet));
if ~checkFilename
    srcSpreadsheet = input('Please give <between single brackets> the name of the spreedsheet...');    
end

%2 ask for the sheet name  (default is "climate"
defaultSheetname = 'climate';
checkSheet = input(sprintf('Please confirm the name of the spreadsheet to import from... (1 = yes, currently %s).....',defaultSheetname));
if ~checkSheet
     defaultSheetname= input('Please give <between single brackets> the name of the sheet to read from...');    
end

%3 ask for range to import!
importRange = input('Please type in the range to import from (between single brackets)... ');

%4 import with odsRead!
%%update, as of v4.2, better use xlsread (odsread no longer handles excel files)

auxClimateRecord = xlsread(srcSpreadsheet,defaultSheetname,importRange);
[a,b] = size(auxClimateRecord);
climateRecord = zeros(a,6);

%5 Create the timestamp vector with columns 1--4
climateRecord(:,1) = datenum(auxClimateRecord(:,3),auxClimateRecord(:,1),auxClimateRecord(:,2),auxClimateRecord(:,4),0,0);
climateRecord(:,2:6) = auxClimateRecord(:,5:b);

end


