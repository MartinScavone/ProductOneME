function asphLyrTemp = HMALayersTemperature(timestamp,airTemp,humidity,windSpd,sunRad,ACPlacementTemp,ACPaveDepth,asphAbsorvipity,asphEmissivity,asphThermalConductivity,verbose)
%function asphLyrTemp = HMALayersTemperature(timestamp,airTemp,humidity,windSpd,sunRad,ACPlacementTemp,ACPaveDepth,asphAbsorvipity,asphEmissivity,asphThermalConductivity,verbose)
%% -- PAVEMENT TEMPERATURE PROFILE MODULE FOR FLEXIBLE PAVEMENTS
%Calculate instant temperature profile throughout structure
%Use equations from the 1993 paper and LTPP Bells Equations to calculate temperature profile through the HMA layers.
%Update 2018-06-20: Converted to function format from previous version of code
%(doesn't need to run along design process, the HMA layers temperature can be predicted before running the simulation)
%
%INPUT: timestamp: vector with time reference (1 unit is 1 day)
      % airTemp:  air temperature (deg. Celsius)
      % humidity: relative air humidity (perc.)
      % windSpd:  wind speed (m/sec)
      % sunRad:   net solar radiation (Watt/m2)
      % ACPlacementtemp: Temperature at which the last HMA layer has been placed (deg. C)
      % ACPaveDepth: vector containing the thickness of each HMA layer (cm)
      % asphAbsorvipity: thermal absorvipity of the HMA layers (level 3 - single default value)
      % asphEmissivity:  thermal emissivity of the HMA layers  (level 3 - single default value)
      % asphThermalConductivity: thermal conductivity of the HMA layers (level 3 - single default value)
      %verbose: boolean variable: 1 = report each calculation step on screen / 0 = run silently
%
%OUTPUT: asphLyrTemp = Matrix containing column of [HMA surf. temperature, avg temp in lyr1 ..... avg temp in lyr n]

%% 1 - Initialize variables for the loop
%First let's set up the terms of the equation to solve (after the 1993 paper)
if verbose 
   disp('    HMA temperature calculation:: initializing');    
end
n = length(timestamp);
sigmaStephBoltz = 5.68E-8;  %Stephan-Boltzmann constant [5.68 x 10-8 W/m2K4]
asphLyrTemp = zeros(n,length(ACPaveDepth)+1);            %Initialize asphLyr Temp [matrix of size timestamp by number of HMA Layers]
depthTemp = 0.01*ACPaveDepth(1);                         %depth of the uppermost HMA layer (select value from the imput matrix) -- CONVERT FROM cm TO m
tempPrevDay = temperaturePreviousDay(timestamp,airTemp); %aux. function to give me the previous day temperature (needed to calculate AC temperature at time k)
currentHour = datevec(timestamp);                        %extract the hours of the timestamp vector
currentHour = currentHour(:,4);

zTemp = [0;cumsum(ACPaveDepth)];                         %column vector with depth -accumulated thickness- of each AC boundary and surface [in centimeters]

%these vectors have values used in the equations within the loop. Since
%they don't change as the loop progresses I can pull them out.

qs = asphAbsorvipity.*sunRad;  %short-wave incoming radiation at any time
pVapor = vaporPressure(airTemp,humidity);  %calculate actual vapor pressure [mmHg] from imput data 
emissivityAir = 0.77 -0.28 .* 10.^(-0.074*pVapor);
qa = emissivityAir.*sigmaStephBoltz.*((airTemp+273.15).^4);   %long-wave radiation from atmosphere

%% - 2 Launch the loop: calculate temperature throughout the structure at time k
for k = 1:n
    if verbose && round(k/1000) == (k/1000)
           fprintf(' \t HMA temperature completed %g percent \n',k/n*100);    
    end
    %1.1 - Solve Ts with a Newton-Raphson method. Launch from Ts = Td(t-1)
    %Tolerance: deviate 3% from 0
    tol = 0.03;
    isTsSolved = 0;    
    if k == 1
%         tempN = 0.5*( ACPlacementTemp +airTemp(k));     %temp in the surface at try N
%         tempD = ACPlacementTemp;                        %temp at a depth D in the pavement (D is depthTemp = depth of top-most layer, see above in #1)
          tempN = 1.5*airTemp(1);
          tempD = 0.7*airTemp(1);
    else
        tempN = 0.5*( asphLyrTemp(k-1,1) + airTemp(k));
        tempD = asphLyrTemp(k-1,2);                      %default value for tempD = temp of previous hour inside layer 1 (avg estimated value for whole layer)
    end
    while isTsSolved ==0
        hsTn = 698.24*(0.00144*(mean([tempN+273.15,airTemp(k)+273.15]))^0.3*windSpd(k)^0.7 + 0.00097*abs(tempN-airTemp(k))^0.3); 
        %%Tweaked over the original Equation (Vehrencamp 1953; appears in NCHRP 1-37A as eqn. 2.3.27)  <Use of abs of difference in the non-linear term to prevent it from going to complex world...>
        fTn = qs(k) + qa(k) - asphEmissivity*sigmaStephBoltz*(tempN+273.15)^4 - ...
            (-1)*asphThermalConductivity*(1/depthTemp)*(tempD - tempN) + (-1)*hsTn*(tempN-airTemp(k));      
        fPrimaTn = -4*asphEmissivity*sigmaStephBoltz*(tempN+273.15)^3 - asphThermalConductivity*(1/depthTemp) + ...
            (-1)*hsTn*1 + (-1)*(tempN-airTemp(k))*698.24*(0.00144*0.3*(mean([tempN+273.15,airTemp(k)+273.15]))^-0.3*0.5*windSpd(k)^0.7 + 0.00097*0.3*abs(tempN-airTemp(k))^(-0.3));
        %Now do the check, if abs(fTn) <0.03, tempN is my root; if not, replace value
        %THIS LINE IS NOT ANY LONGER NEEDED - - - - fprintf('Estimated AC temperature is %g \n',fTn)
        if abs(fTn)<tol            
            isTsSolved =1;
        else
            tempN = tempN - fTn/fPrimaTn;   %update value of tempN
        end    
    end
    asphLyrTemp(k,1) = tempN;
    
    %% 3 - Solve downward to the end of the asphalt layers.
    %%Use the LTPP BELLS EQUATION (ref: HFWA RD 98-085).
    %%I will calculate temperature on the boundary of each HMa layer and will average values 
    %%Store them in asphLyrTemp(k, 2:end)
    
    ACTempAux = zeros(length(zTemp),1);   %in this auxiliary variable I will store the temperatures at the surface and at the bottom of each layer at timestamp k
    ACTempAux(1) = tempN;
    for j = 2:length(zTemp)
      %Now I apply the Bells equation throughout the AC layers. ZTEMP MUST BE CONVERTED FROM CM TO MM TO BE PROPERLY USED IN THE BELLS EQUATION!!! 
      ACTempAux(j) = 2.78+0.912*airTemp(k) + (log10(10*zTemp(j))-1.25)*(-0.428*airTemp(k) + 0.553*tempPrevDay(k) + 2.63*sin18(currentHour(k),15.5)) ...
      +( 0.027*airTemp(k)*sin18(currentHour(k),13.5));
    end

    %%2.2 - Average the boundary values to get the asphLyrTemp row
    ACAvgTempAux = zeros(length(zTemp)-1,1);
    for j = 1:length(ACAvgTempAux)
      ACAvgTempAux(j) = mean([ACTempAux(j),ACTempAux(j+1)]);  %solve mean temeprature for layers 1:down 
    end
    %2.3 - replace aux in the asphLyrTemp matrix
    asphLyrTemp(k,2:end) = ACAvgTempAux;

end  %END FOR-loop for AC surface temp

end %% -- END OF MODULE.
