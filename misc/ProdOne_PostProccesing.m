%%PRODUCT-ONE M-E DESIGN TOOL
%% FRONT-END SCRIPT TO REVIEW NUMERICAL RESULTS
%
%This script is rather simple, it will create a struct array with a sub-set
%of all the output data from a Prod-One run.
%The user specifies what he/she wants on the list below


%%code begins
clc
disp('Product-One M-E output review script.....')

%%%TO ADDD
%DO A CHECK FOR THE VARIABLES OF THE PROD-ONE WORKSPACE
%IF NONE, ASK THE USER TO OPEN A MAT FILE WITH A RUN RESULT!
%%%

%%create blank struct
outputBaseProps = struct('point',[],'date',[],'pavThicknesses',[],'asphaltE',[],'asphaltv',[],'granMR',[],'granv',[]);
outputStressStrain = struct('point',[],'date',[],'stressX',[],'strainX',[],'stressY',[],'strainY',[],'stressZ',[],'strainZ',[],'strainH',[],'strainPlastic',[]);
outputDistressValues = struct('point',[],'date',[],'alligatorDamage',[],'topDownDamage',[],'rutDepthIncr',[],'rutDepthTotal',[],'IRI',[],'PSI',[]);

outputPoints = input('specify for what timestamps would you like outputs (vector format if multiple)....');
outputPoints = outputPoints(:);   %parse the outputPoints to a column just in case.
n = length(outputPoints);
outputDate = datevec(shortTimestamp(outputPoints));

%fill up the structures as needed
for i = 1:n
   outputBaseProps(i).point = outputPoints(i); 
   outputStressStrain(i).point = outputPoints(i);
   outputDistressValues(i).point = outputPoints(i);
   
   outputBaseProps(i).date = outputDate(i,:); 
   outputStressStrain(i).date = outputPoints(i,:);
   outputDistressValues(i).date = outputPoints(i,:);
    
   outputBaseProps(i).pavThicknesses = paveDepths; 
   outputBaseProps(i).pavThicknesses = paveDepths; 
end