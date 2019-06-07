function climateMatrix = climateSimulator(projectX,projectY,verbose,forceRecalcMatrix)
%function climateMatrix = climateSimulator(ProjectX,ProjectY,verbose,forceRecalcMatrix)
%
%%front-end function to develop the project site's simulated climate variables
%this function will work as follows
%1 - construct a virtual_ weather station climate record from the INIA db (years 2011-2017 <future updates to the code may allow to extend the source data as INIA collects more records>
%%Use Square Dist. interpolation to do so (Wei and McGuinees, 1973; referenced in hydrology manuals, such as Chow et al., 1988)
%
%The "verbose" input allows to show on screen every calculation step. input 1 if you want to do so. If no input, it assumes zero
%NEW: The forceRecalcMatrix forces the code to generate a new site's climate record from INIA DB regardless of the cached record being still useful.
%
%Updated Matching V2018-09-05:  Separate lvl2 climate interpolator from scrambler.
%                               New output will be the interpolated only if
%                               a previously executed cached climateMatrix
%                               won't serve (it has been solved for a
%                               different place)                               
%
% 2018 - MartiWorks

%% Preprocc. check if last-generated cached climate records matrix still works (we are in the same projectX and projectY, and the cached record is the same length!)
%(if that's the case, spare us interpolating a new climate record)
% note - if forceRecalcMatrix == 1 , ignore matrix recycling, and
% recalculate all the same!

load 'climateMatrixCached.mat'
%the mat file loaded here contains:
%   oldX, oldY = X,Y position of the last project site
%   oldClimateMatrix = cached climate record from previous execution

if oldX == projectX && oldY == projectY == ~forceRecalcMatrix
    %case: don't recalculate the climate matrix, pass on the cached one!
    if verbose 
        disp('climateSimulator:: using cached Level-2 site"s climate record')
        %this is the UPDATE 2018-09-05, recalculate the interpolated
        %climate record only if strictly necessary. (the interpolation
        %procedure takes a while)        
    end
    climateMatrix = oldClimateMatrix; 
else
    %ok, do a new matrix!. Proceed with the code below   
    if verbose && forceRecalcMatrix
        disp('climateSimulator:: order to recalculate site"s climate record received.')
    end     
    %% Part1 - Bring the INIA weather records    
    if verbose == 1
        disp('climateSimulator:: loading INIA Weather stations climate database')
    end    
    load './dataFiles/INIAClimate.mat'
    %this .mat file contains structures with the hourly weather data from 8 INIA stations
    %INIA_LE INIA_LB INIA_33 INIA_Tbo INIA_Dur INIA_Gle INIA_SG INIA_RO
    
    %% Part 2 - Create virtual station with distance square interpolation technique.  (Wei & McGuinness 1973)
    %Extract the interpolation factors
    xLB = INIA_LB(1).Location (1);
    yLB = INIA_LB(1).Location (2);
    distLB2 = (projectX - xLB)^2 + (projectY - yLB)^2 ;  %dist to Las Brujas
    
    xLE = INIA_LE(1).Location (1);
    yLE = INIA_LE(1).Location (2);
    distLE2 =  (projectX - xLE)^2 + (projectY - yLE)^2;  %dist to La Estanzuela
    
    xTbo = INIA_Tbo(1).Location (1);
    yTbo = INIA_Tbo(1).Location (2);
    distTbo2 = (projectX - xTbo)^2 +(projectY - yTbo)^2;  %dist to Tacuarembo
    
    xGle = INIA_Gle(1).Location (1);
    yGle = INIA_Gle(1).Location (2);
    distGle2 = (projectX - xGle)^2 +(projectY - yGle)^2;  %dist to Glencoe
    
    xDur = INIA_Dur(1).Location (1);
    yDur = INIA_Dur(1).Location (2);
    distDur2 = (projectX - xDur)^2 +(projectY - yDur)^2;  %dist to Durazno
    
    xRo = INIA_RO(1).Location (1);
    yRo = INIA_RO(1).Location (2);
    distRo2 =  (projectX - xRo)^2 + (projectY - yRo)^2;  %dist to Rocha
    
    xSg = INIA_SG(1).Location (1);
    ySg = INIA_SG(1).Location (2);
    distSG2 =  (projectX - xSg)^2 + (projectY - ySg)^2;  %dist to Salto Grande
    
    x33 = INIA_33(1).Location (1);
    y33 = INIA_33(1).Location (2);
    dist332 = (projectX - x33)^2 + (projectY - y33)^2;  %dist to Treinta y Tres
    
    %% Create the variables between 2010 and 2017
    %Define timestamp range
    %Use find function to locate the variables' values from each station for that timestamp
    %Q MEASURE against missing values
    %construct the vectors.
    
    if verbose
        disp('climateSimulator:: initialize virtual weather station variables. Simulating 2010-2018 period')
    end    
    timestamp = datenum(2010,1,1,0,0,0):1/24:datenum(2019,1,1,0,0,0);
    timestamp = timestamp';
    nle = length(timestamp);
    
    %the 5 climatic variables - initialize as 0, then I will fill the vectors
    temp = zeros(nle,1);               % interpolate point avg. temperatures [in deg. C]
    rain = zeros(nle,1);               % interpolate accum. rainfall     [in mm]
    wspd = zeros(nle,1);               % interpolate point wind speed    [in m/sec]
    srad = zeros(nle,1);               % interpolate accumulated sun radiation [in MJ/m2]  NEED TO CHECK MEPDG EICM GUIDE FOR USED UNITS...
    hum  = zeros(nle,1);               %interpolate point air humidity   [in %]    
    
    disp('climateSimulator:: calculating virtual weather station variables')
    
    %% Part 3 - And here I fill up the variables. Use interpolation
    for i = 1:nle
        if verbose && i/1000 == round(i/1000)
            fprintf('climateSimulator:: Completed %g percent  \n', 100*i/nle);  %for Verbose mode, I will print on screen calculation progress every 1000 steps
        end
        
        %%variables from LE
        position = find(INIA_LE(1).timestamp == timestamp(i));
        %Gotta check that posLE returned something (i.e. LE has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempLE = 0;
        rainLE = 0;
        wspdLE = 0;
        sradLE = 0;
        humLE =  0;
        binLE  = 0;   %This binLe term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_LE(1).temp(position))
                tempLE = INIA_LE(1).temp(position);
            end
            if ~isnan(INIA_LE(1).rain(position))
                rainLE = INIA_LE(1).rain(position);
            end
            if ~isnan(INIA_LE(1).wspd(position))
                wspdLE = INIA_LE(1).wspd(position);
            end
            if ~isnan(INIA_LE(1).srad(position))
                sradLE = INIA_LE(1).srad(position);
            end
            if ~isnan(INIA_LE(1).hum(position))
                humLE =  INIA_LE(1).hum(position);
            end
            if ~isnan(INIA_LE(1).temp(position)) && ~isnan(INIA_LE(1).rain(position)) && ~isnan(INIA_LE(1).wspd(position)) && ~isnan(INIA_LE(1).srad(position)) && ~isnan(INIA_LE(1).hum(position))
                binLE = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        
        %%variables from LB
        position = find(INIA_LB(1).timestamp == timestamp(i));
        %Gotta check that posLB returned something (i.e. LB has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempLB = 0;
        rainLB = 0;
        wspdLB = 0;
        sradLB = 0;
        humLB =  0;
        binLB  = 0;   %This binLB term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation       
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_LB(1).temp(position))
                tempLB = INIA_LB(1).temp(position);
            end
            if ~isnan(INIA_LB(1).rain(position))
                rainLB = INIA_LB(1).rain(position);
            end
            if ~isnan(INIA_LB(1).wspd(position))
                wspdLB = INIA_LB(1).wspd(position);
            end
            if ~isnan(INIA_LB(1).srad(position))
                sradLB = INIA_LB(1).srad(position);
            end
            if ~isnan(INIA_LB(1).hum(position))
                humLB =  INIA_LB(1).hum(position);
            end            
            if ~isnan(INIA_LB(1).temp(position)) && ~isnan(INIA_LB(1).rain(position)) && ~isnan(INIA_LB(1).wspd(position)) && ~isnan(INIA_LB(1).srad(position)) && ~isnan(INIA_LB(1).hum(position))
                binLB = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        
        %%variables from Dur
        position = find(INIA_Dur(1).timestamp == timestamp(i));
        %Gotta check that posDur returned something (i.e. Dur has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempDur = 0;
        rainDur = 0;
        wspdDur = 0;
        sradDur = 0;
        humDur =  0;
        binDur  = 0;   %This binDur term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_Dur(1).temp(position))
                tempDur = INIA_Dur(1).temp(position);
            end
            if ~isnan(INIA_Dur(1).rain(position))
                rainDur = INIA_Dur(1).rain(position);
            end
            if ~isnan(INIA_Dur(1).wspd(position))
                wspdDur = INIA_Dur(1).wspd(position);
            end
            if ~isnan(INIA_Dur(1).srad(position))
                sradDur = INIA_Dur(1).srad(position);
            end
            if ~isnan(INIA_Dur(1).hum(position))
                humDur =  INIA_Dur(1).hum(position);
            end
            if ~isnan(INIA_Dur(1).temp(position)) && ~isnan(INIA_Dur(1).rain(position)) && ~isnan(INIA_Dur(1).wspd(position)) && ~isnan(INIA_Dur(1).srad(position)) && ~isnan(INIA_Dur(1).hum(position))
                binDur = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        
        %%variables from Tbo
        position = find(INIA_Tbo(1).timestamp == timestamp(i));
        %Gotta check that posDur returned something (i.e. Dur has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempTbo = 0;
        rainTbo = 0;
        wspdTbo = 0;
        sradTbo = 0;
        humTbo =  0;
        binTbo  = 0;   %This binTbo term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_Tbo(1).temp(position))
                tempTbo = INIA_Tbo(1).temp(position);
            end
            if ~isnan(INIA_Tbo(1).rain(position))
                rainTbo = INIA_Tbo(1).rain(position);
            end
            if ~isnan(INIA_Tbo(1).wspd(position))
                wspdTbo = INIA_Tbo(1).wspd(position);
            end
            if ~isnan(INIA_Tbo(1).srad(position))
                sradTbo = INIA_Tbo(1).srad(position);
            end
            if ~isnan(INIA_Tbo(1).hum(position))
                humTbo =  INIA_Tbo(1).hum(position);
            end
            if ~isnan(INIA_Tbo(1).temp(position)) && ~isnan(INIA_Tbo(1).rain(position)) && ~isnan(INIA_Tbo(1).wspd(position)) && ~isnan(INIA_Tbo(1).srad(position)) && ~isnan(INIA_Tbo(1).hum(position))
                binTbo = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        
        %%variables from 33
        position = find(INIA_33(1).timestamp == timestamp(i));
        %Gotta check that pos33 returned something (i.e. 33 has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        temp33 = 0;
        rain33 = 0;
        wspd33 = 0;
        srad33 = 0;
        hum33 =  0;
        bin33  = 0;   %This bin33 term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_33(1).temp(position))
                temp33 = INIA_33(1).temp(position);
            end
            if ~isnan(INIA_33(1).rain(position))
                rain33 = INIA_33(1).rain(position);
            end
            if ~isnan(INIA_33(1).wspd(position))
                wspd33 = INIA_33(1).wspd(position);
            end
            if ~isnan(INIA_33(1).srad(position))
                srad33 = INIA_33(1).srad(position);
            end
            if ~isnan(INIA_33(1).hum(position))
                hum33 =  INIA_33(1).hum(position);
            end
            if ~isnan(INIA_33(1).temp(position)) && ~isnan(INIA_33(1).rain(position)) && ~isnan(INIA_33(1).wspd(position)) && ~isnan(INIA_33(1).srad(position)) && ~isnan(INIA_33(1).hum(position))
                bin33 = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        %%variables from Rocha
        position = find(INIA_RO(1).timestamp == timestamp(i));
        %Gotta check that posRo returned something (i.e. Ro has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempRo = 0;
        rainRo = 0;
        wspdRo = 0;
        sradRo = 0;
        humRo =  0;
        binRo  = 0;   %This binRo term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_RO(1).temp(position))
                tempRo = INIA_RO(1).temp(position);
            end
            if ~isnan(INIA_RO(1).rain(position))
                rainRo = INIA_RO(1).rain(position);
            end
            if ~isnan(INIA_RO(1).wspd(position))
                wspdRo = INIA_RO(1).wspd(position);
            end
            if ~isnan(INIA_RO(1).srad(position))
                sradRo = INIA_RO(1).srad(position);
            end
            if ~isnan(INIA_RO(1).hum(position))
                humRo =  INIA_RO(1).hum(position);
            end
            if ~isnan(INIA_RO(1).temp(position)) && ~isnan(INIA_RO(1).rain(position)) && ~isnan(INIA_RO(1).wspd(position)) && ~isnan(INIA_RO(1).srad(position)) && ~isnan(INIA_RO(1).hum(position))
                binRo = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        %%variables from Glencoe
        position = find(INIA_Gle(1).timestamp == timestamp(i));
        %Gotta check that posGle returned something (i.e. Gle has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempGle = 0;
        rainGle = 0;
        wspdGle = 0;
        sradGle = 0;
        humGle =  0;
        binGle  = 0;   %This binGle term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_Gle(1).temp(position))
                tempGle = INIA_Gle(1).temp(position);
            end
            if ~isnan(INIA_Gle(1).rain(position))
                rainGle = INIA_Gle(1).rain(position);
            end
            if ~isnan(INIA_Gle(1).wspd(position))
                wspdGle = INIA_Gle(1).wspd(position);
            end
            if ~isnan(INIA_Gle(1).srad(position))
                sradGle = INIA_Gle(1).srad(position);
            end
            if ~isnan(INIA_Gle(1).hum(position))
                humGle =  INIA_Gle(1).hum(position);
            end
            if ~isnan(INIA_Gle(1).temp(position)) && ~isnan(INIA_Gle(1).rain(position)) && ~isnan(INIA_Gle(1).wspd(position)) && ~isnan(INIA_Gle(1).srad(position)) && ~isnan(INIA_Gle(1).hum(position))
                binGle = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        %%variables from Salto Grande
        position = find(INIA_SG(1).timestamp == timestamp(i));
        %Gotta check that posSG returned something (i.e. SG has a non-NaN weather record for that timestamp)
        %(in the NaN cases, Matlab will output a NaN value in the design
        %weather variable)
        %Default value (either no record, or record which is NaN
        tempSG = 0;
        rainSG = 0;
        wspdSG = 0;
        sradSG = 0;
        humSG =  0;
        binSG  = 0;   %This binSG term is a binary (==1 only if there is actual record of the 5 climate variables), I will use it to kill unnecessary terms in the interpolation
        
        if ~isempty(position)   %if no record, all values set to 0,then the interp must ignore them when doing the sum.
            %case there is a record at that timestamp, bring in the values only if they are non-NaN
            if ~isnan(INIA_SG(1).temp(position))
                tempSG = INIA_SG(1).temp(position);
            end
            if ~isnan(INIA_SG(1).rain(position))
                rainSG = INIA_SG(1).rain(position);
            end
            if ~isnan(INIA_SG(1).wspd(position))
                wspdSG = INIA_SG(1).wspd(position);
            end
            if ~isnan(INIA_SG(1).srad(position))
                sradSG = INIA_SG(1).srad(position);
            end
            if ~isnan(INIA_SG(1).hum(position))
                humSG =  INIA_SG(1).hum(position);
            end
            if ~isnan(INIA_SG(1).temp(position)) && ~isnan(INIA_SG(1).rain(position)) && ~isnan(INIA_SG(1).wspd(position)) && ~isnan(INIA_SG(1).srad(position)) && ~isnan(INIA_SG(1).hum(position))
                binSG = 1;   %if there is a "valid" record for the 5 variables, utilize them (put the bin == 1)
            end
        end
        %%Now interpolate using inverse of reciprocal distance (Wei & Guinness, 1971?)
        %Those terms of the equation corresponding to no-Data or NaN-data will be cancelled out automatically (mult. by 0)
        temp(i) = (binLE*tempLE/distLE2 + binLB*tempLB/distLB2 + binDur*tempDur/distDur2 + bin33*temp33/dist332 + binRo*tempRo/distRo2 + binGle*tempGle/distGle2 + binTbo*tempTbo/distTbo2 + binSG*tempSG/distSG2)/ ...
            (binLE/distLE2 + binLB/distLB2 + binDur/distDur2 + bin33/dist332 + binRo/distRo2 + binGle/distGle2 + binTbo/distTbo2 + binSG/distSG2);
        rain(i) = (binLE*rainLE/distLE2 + binLB*rainLB/distLB2 + binDur*rainDur/distDur2 + bin33*rain33/dist332 + binRo*rainRo/distRo2 + binGle*rainGle/distGle2 + binTbo*rainTbo/distTbo2 + binSG*rainSG/distSG2)/ ...
            (binLE/distLE2 + binLB/distLB2 + binDur/distDur2 + bin33/dist332 + binRo/distRo2 + binGle/distGle2 + binTbo/distTbo2 + binSG/distSG2);
        wspd(i) = (binLE*wspdLE/distLE2 + binLB*wspdLB/distLB2 + binDur*wspdDur/distDur2 + bin33*wspd33/dist332 + binRo*wspdRo/distRo2 + binGle*wspdGle/distGle2 + binTbo*wspdTbo/distTbo2 + binSG*wspdSG/distSG2)/ ...
            (binLE/distLE2 + binLB/distLB2 + binDur/distDur2 + bin33/dist332 + binRo/distRo2 + binGle/distGle2 + binTbo/distTbo2 + binSG/distSG2);
        srad(i) = (binLE*sradLE/distLE2 + binLB*sradLB/distLB2 + binDur*sradDur/distDur2 + bin33*srad33/dist332 + binRo*sradRo/distRo2 + binGle*sradGle/distGle2 + binTbo*sradTbo/distTbo2 + binSG*sradSG/distSG2)/ ...
            (binLE/distLE2 + binLB/distLB2 + binDur/distDur2 + bin33/dist332 + binRo/distRo2 + binGle/distGle2 + binTbo/distTbo2 + binSG/distSG2);
        hum(i)  = (binLE*humLE/distLE2  + binLB*humLB/distLB2  + binDur*humDur/distDur2  + bin33*hum33/dist332  + binRo*humRo/distRo2  + binGle*humGle/distGle2  + binTbo*humTbo/distTbo2  + binSG*humSG/distSG2 )/ ...
            (binLE/distLE2 + binLB/distLB2 + binDur/distDur2 + bin33/dist332 + binRo/distRo2 + binGle/distGle2 + binTbo/distTbo2 + binSG/distSG2);
    end
    %% Part 4
    %Output the climateMatrix of interpolated weather records
    if verbose
        disp('climateSimulator:: Exporting simulated climate variables')
    end
    %%export as output...
    climateMatrix = [timestamp temp hum wspd rain srad];
    %UPDATE 2018-09-05 - Store the newly generated climateMatrix in Cache
    oldY = projectY;
    oldX = projectX;
    oldClimateMatrix = climateMatrix;
    save './dataFiles/climateMAtrixCached.mat' oldX oldY oldClimateMatrix
    
end %close the if loop in ln30


end   %%endFunction

