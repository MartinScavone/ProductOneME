%%%% - PRODUCT-1 - M.E. Pavement Design tool - %%%%
%%% CLIMATE EFFECTS MODULE for flexible pavements%%%
%
% Version 0.3 2019-01-25 - - bug-fixed all throughout
% Version 0.2 2018-10-22 - - added layers moisture module.
% Version 0.1 2018-06-20
%
%%THIS SCRIPT IS MEANT TO RUN AS WITHIN THE PAVEMENT DISTRESS SIMULATION PROGRAMMED IN THE MAIN CODE
%%EACH INSTANCE OF THIS SCRIPT OCCURS AT "timeStamp = k"
%
%%NOTE: A MAJOR HYPOTHESIS FOR THIS DESIGN TOOL: NO FREEZING OCCURS THROUGHOUT THE PAVEMENT STRUCTURE. 
%%FROST HEAVE PHENOMENA SUCH AS THOSE MODELED WITH %%THE CRREL "FROST" PROGRAM (1986?) WILL BE DISREGARDED.
%
%units for all values = m3/12h/m2 or m3/m2!  (for volume calculations, assuming 1m x 1m cell)

%% -- RAINFALL-INFILTRATION-BASE DRAINAGE MODULE
%Calculate entering rainfall, evaluate how much infiltrates, calculate infiltration through base and subbase, and down to subgrade
%Use equations from the I-D model, deterministic version. Calculate infiltration rate to pavement  
%analysis cell of 1m x 1m (1mm of rain equals 0.001m3 of entering water)
infRate_HMA = 0.1*0.305^2;     %unit infiltration rate (m3/h) per meter of cracks - HMA pavements. Source FHWA RD 90-033, eqn 21  [LATER ON I ACCUMULATE TO INF_RATE X 12H]
%infRate_PCC = 0.03*0.305^2;   %unit infiltration rate (m3/h) per meter of cracks - PCC pavements. Source FHWA RD 90-033

%Sum the length of all cracks at time k-1 (to calculate how much water will infiltrate
%ASSUMPTION: alligator cracking are as cells 0.10mx0.10m; reflective cracks are cells 3.6x4.5m  (typical PCC slab size in Uruguayan roads)
if k ==1
    totalCracks = 0;   %%CORRECT THIS LINE WITH THE "AS-BUILT" DISTRESS RATES!
else
    totalCracks = 0.001*topDownCrack(k-1,1)+alligatorCrack(k-1,1)*(4*0.1);%+0.001*transvCrack(k-1)+reflectiveCrack(k-1)*2*(4.5+3.6)*(1/(4.5*3.6));   %this is the total length of all cracks in the pavement / proportionally distributed over sq. m. of pave.
end

%UPDATE 2018-06-20 - LOCATE THE RAINFALL intake from the period past and
%analyze it (compare individual hourly rain rates to inf. rate and deduct
%infiltration and runoff)
%for k == 1 (start of code), rainfallIntake = zeros(12,1)  - let's assume it wasn't raining when the last HMA layer was placed.
%k follows shortTimestamp!!!
whereInTime = find(longTimestamp == shortTimestamp(k));
if k ==1
    %%accumulate last 12h of rainfall!  in m3/m2/12h
    intervalRainfall = 0.001*12/k*sum(rainFall(1:whereInTime));  %in here i'm summing up less rainfall than 12h, I'm just extrapolating by multiplying by 12/k
else    
    intervalRainfall = 0.001*sum(rainFall(whereInTime-11:whereInTime));     %accumulated rain in the last 12 hours, converted to m3/12h  
end

%deduct the infiltration rate to intervalRainfall
intervalInfiltration = min([intervalRainfall,totalCracks*infRate_HMA*12]);%infiltration is over a 12-hour period!!!! 
surfaceRunoff(k) = intervalRainfall - intervalInfiltration;             %the water that doesn't infiltrate must leave   [m3/m2/12h]  [I'll convert it to mm/12h later on <ln. 123>

surfaceInfiltration(k) = 1000*intervalInfiltration;                     %store interval infiltration in mm/12h
shortRainfall(k) = 1000*intervalRainfall;                               %store the accumulated rainfall. [mm/12h]


%% -- CALCULATE HUMIDITY AT BASE/SUBBASE LAYERS
%%Update 2019-01-25 - Calculate the kUnsat with the "initial time moisture content
                    % Use lower layer's kUnsat to calculate downward runoff
                    % limit downward runoff also to the available void  space between saturation and current moisture in the lower layer
                    
%%UPDATE 2018-06-20 - THIS SCRIPT WILL RUN IN THE 1/2-DAY-LONG SIMULATION, 
                    % get the amount of water that entered througout the period from --->> "intervalInfiltration"  <<--
%%UPDATE 2-18-10-19 - get the hydraulic conductivity from moisture content

deltaTime = 3600*12;                                                    %time interval to sum the escaping runoff that entered the pavement
numLayersForMoisture = 1+paveLayersNumber-ACLayersNumber;               %layers for moisture analysis are the granular layers + subgrade!
layersMoistureThickness = paveDepths(end-numLayersForMoisture+1:end)/100; %get the thicknesses of the non-HMA layers and convert to meters
layersSaturation = 0.01*granHumidity(:,3).*layersMoistureThickness;          %saturation vol. content of the gran. layers (m3/m2).
                                                        %Compare against humidity at any moment.  [remember that granHumidity(:,3) comes in PERCENTAGE VOLUME]
                                                
% get previous-time moisture over each layer at the subgrade
if k == 1 
    previousHumidity = granHumidity(:,1);                                         %%initial water content [percentage]. Defined in the materialsParametersLvlXX script 
    previousHumidity = (1/100).*previousHumidity.*layersMoistureThickness.*1.*1;  %m3/m2
    %IN PERCENT! MUST CONVERT TO VOLUME (MULTIPLY PER SIZE OF LAYER!, IN
    %THE CASE OF SUBGRADE, REDUCE TO ANALYZING A 3m-thick zone.
    %(MAY NEED TO JUSTIFY THIS CHOICE FROM THE STRESS-STRAIN MODEL (HOW DEEP DO THE STRESSES GO...)     
else
    previousHumidity = layersMoisture(k-1,:)';
    %row vector cointaining the calculated humidity values for time = k-1 for all the non-HMA layers AND THE SUBGRADE! in percent volume!
    %%Bug correction 2019-01-25:: transpose that row vector to column to avoid issues when converting to m3/m2 (matlab doesn't go entry by entry)
    previousHumidity = (1/100).*previousHumidity.*layersMoistureThickness;  %convert it to m3/m2
end

%get each material's kUnsat fusing the "previousHumidity IN PERCENTAGE VOLUME! 
kValue = zeros(numLayersForMoisture,1);                 %store each material's unsat hidr. conductivity here.
for j = 1:numLayersForMoisture
%BUG CORRECTED 2019-01-24:: THIS INTERP1 WAS USING PREVIOUSHUMIDITY IN M3/M2, IT SHOULD USE PERCENT VOLUME CONTENT!
    %kValue = interp1(granularKSWCC(:,2,j),granularKSWCC(:,3,j),previousHumidity(j));    %get the layer's hydraulic conductivity from SWCC calculations done in preprocessing [COMES IN M/SEC]!!!!
    %REPAIR IT WITH A SMALL IF SENTENCE NO NOT UNDO THE previousHumidity unit conversion above
    % and solve now the 
    if k ==1
        kValue(j) = interp1(granularKSWCC(:,2,j),granularKSWCC(:,3,j),granHumidity(j,1));       %get the layer's hydraulic conductivity from SWCC calculations done in preprocessing. Enter in % volume, output in M/SEC]!!!!
    else
        kValue(j) = interp1(granularKSWCC(:,2,j),granularKSWCC(:,3,j),layersMoisture(k-1,j)');  %get the layer's hydraulic conductivity from SWCC calculations done in preprocessing. Enter in % volume, output in M/SEC]!!!!
    end
    %%end of correction
end

%let's solve separately for each layer one by one, open a For loop
downwardRunoff = intervalInfiltration;                  %start this variable (i will replace it as I calculate over each cell

% start the water flow balance / GO LAYER BY LAYER
for j = 1:numLayersForMoisture
     
    moistureLyrJaux = previousHumidity(j);                  %get the volume of water in layer j at time k (per sq. m of area) [from previousHumidity vector]
    %assuming isotropic material kValue is the same for flow in any direction
    lateralRunoff(k,j) = min([deltaTime*kValue(j)*layersMoistureThickness(j)*paveCrossSlope/100,moistureLyrJaux+downwardRunoff]);  
    %lateral runoff layer j = kValue * thickness Lyr j * Pavement SX (absolute)* delta Time. NO GREATER THAN CURRENT MOISTURE + INPUT.  %VALUE CALCULATED HEREIN IS IN MR/M2/12H
    moistureLyrJaux = moistureLyrJaux - lateralRunoff(k,j);
    if j<numLayersForMoisture
        downwardRunoffAux = min([deltaTime*kValue(j+1),moistureLyrJaux,layersSaturation(j+1)-previousHumidity(j+1)]);      
    else
        downwardRunoffAux = min([deltaTime*kValue(j),moistureLyrJaux]);            
    end
    moistureLyrJaux = moistureLyrJaux - downwardRunoffAux;
    %%%%following simplification in Davidson et al (1969)/ low flow phenomena.NO GREATER THAN CURRENT MOISTURE (after pulling lateral flow
    %%BUG CORRECTION 2019-1-24 (above), add also resetriction to downward flow not be greater than the capacity to saturation of the underlying layer.
    %%BUG CORRECTION 2019-1-25        , correct downward runoff to make it dependant on the lower layer's kUnsat (more restrictive than upper layer // lower layer is comparatively impervious
    
    %Save the final moisture in layer j, and pass on the downward Runoff to the next layer...
    currentHumidity = min([moistureLyrJaux,layersSaturation(j)]);            %in volume,. layer j  %%%LIMIT IT TO BE NO GREATER THAN SATURATION HUMIDITY!!!!!
    %>>>>>>>>>>>>>> surfaceRunoff(k) = surfaceRunoff(k) + max(moistureLyrJaux,layersSaturation(j)) - currentHumidity;  %any additional water that can neither flow downwards nor sideways nor be retained must go as surface Runoff.
    downwardRunoff = downwardRunoffAux;
   layersMoisture(k,j) = currentHumidity/(layersMoistureThickness(j)*1*1)*100;  %store the volumetric moisture in layer j in percent volume content   
    
end
%Store surfaceRunoff in mm/12h (to compare with rainfall and infiltration)
surfaceRunoff(k) = 1000*surfaceRunoff(k);

%% -- PAVEMENT TEMPERATURE PROFILE MODULE FOR FLEXIBLE PAVEMENTS
%Calculate instant temperature profile throughout structure
%Use equations from the 1993 paper and LTPP to calculate temperature profile through the Apsh layers.

%%UPDATE 2018-06-20 - THIS MODULE HAS BEEN REMOVED FROM THE SCRIPT AND PUT
%%AS A FUNCTION IN THE PRE-PROCESSING (DOESN'T NEED TO RUN ALONG WITH THE DESIGN SIMULATION)

  
%% -- SUB-GRADE WATER TABLE MODULE
%%Update 2018-06-20 - THIS MODULE WILL NOT BE IMPLEMENTED
%%SIMPLIFICATION: SUB-GRADE WILL HAVE A SINGLE-VALUE RESILIENT MODULUS
%%(CORRESPONDING TO NORMAL CONDITIONS) - LEVEL-3 ACCORDING TO NCHRP 1-37?. 
%%UNDERLYING ASSUMPTION: URUGUAYAN ROADS'SUBGRADES ARE EITHER ALWAYS SOAKED OR ALWAYS "DRY"
%%- THAT IS, RISE OF THE WATER TABLE MAY NOT MODIFY THE STRENGTH OF THE PORTION OF SUBGRADE THAT RECEIVES LOADS.

%% --END OF SCRIPT
