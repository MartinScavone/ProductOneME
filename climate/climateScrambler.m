function climateMatrix = climateScrambler(climateRecord,climateRandomSeed,designLife,dateOpenToTraffic,verbose)
%function climateMatrix = climateScrambler(climateRecord,climateRandomSeed,designLife,dateOpenToTraffic,verbose)
%
%%front-end function to develop the project site's simulated climate variables from interpolated INIA records or Level-1 climate record.
%
%%This function will work as follows
%1 - construct a virtual_ weather station climate record from the INIA db (years 2011-2017 <future updates to the code may allow to extend the source data as INIA collects more records>
%%Use Square Dist. interpolation to do so (bring ref from paper from the 70s)
%2 - simulate future climate:
  %a) create a random vector with the length of design life,
  %b) convert these random numbers to integer years, spanning between 2011 and 2017 (last year of INIA Data)
  %c) construct simulated climate using the interpolated weather station, scrambling the variables follwoing the random vector.
%
%The "verbose" input allows to show on screen every calculation step. input 1 if you want to do so. If no input, it assumes zero
%
%Matching V2018-09-05:  Separate lvl2 climate interpolator from scrambler.
%                       Add randomSeed integer for repeatability of climate
%                       scrambles
%
%2018 - MartiWorks

%% Preprocessing - unpack the climateRecord matrix
timestamp = climateRecord(:,1);
temp = climateRecord(:,2);
hum  = climateRecord(:,3);
wspd = climateRecord(:,4);
rain = climateRecord(:,5);
srad = climateRecord(:,6);

%Scramble random number vector and obtain randomly chosen years.
if verbose == 1   
    disp('climateScrambler:: shuffling random years for climate simulation')
end
load './dataFiles/climateRandomSeed.mat';   %file created! contains last used random Seed, last generated randomSeedMatrix, and first/last years in that randomSeedMatrix
%
%variables in climateRandomSeed:
    % lastRandomSeed - matrix with 50 rows and colums equal to last used
    % design life +1
    % lastUsedYear - vector with last used initial and end years
    % lastRandomSeed - last Used random seed (if I ever need it...)

%So, here's the logic for the scrambler.
%1 - given the randomSeed and the pavement's design life
%   IF design life + 1 = columns in randomSeed matrix, AND first & last
%   years match what previously used 
        % recycle the matrix for current run 
  % ELSE (either column mismatch or years mismatch)
  %     recalculate the matrix; and store in the climateRandomSeed.mat file
        %use an auxiliary function for that!

lastYear = datevec(timestamp(end-1));
lastYear = lastYear(1);  %%Using DateVec function (compatibility issue with Matlab -year function only runs on integers-
firstYear =  datevec(timestamp(1));
firstYear = firstYear(1);

%First, check if I can use the cached randomSeed Matrix
[~,bb] = size(randomSeedMatrix);   %aa should be 50 -fixed by programming; replaced by ~ to ignore it (thanks Matlab!)
if bb == designLife+1 && firstYear == lastUsedYear(1) && lastYear == lastUsedYear(2)
    %recycle matrix, do nothing new
else
    %create a new randomSeedMatrix
    lastUsedYear = [firstYear lastYear];
    lastRandomSeed = climateRandomSeed;
    randomSeedMatrix = random('unif',firstYear,lastYear,[50,designLife+1]);   %OCTAVE USERS - INSTALL STATISTICS PACKAGE TO USE RANDOM FUNCTION!!
    %randomSeedMatrix is a vector with the length of designLife which has the available climate years selected randomly
    %But thing is I have to round up the years to perform the climate simulation [I cannot simulate year 2013.4445
    %Other detail: length of the random vector is designLife + 1, I've done this on purpose cause the pavement project may not start on jan. 1st.,
    %so, in order to wrap all the design period with the simulated climate
    randomSeedMatrix = round(randomSeedMatrix);
    save './dataFiles/climateRandomSeed.mat' lastUsedYear lastRandomSeed randomSeedMatrix
end

%% 2 - now that I have a valid (recycled or new) randomSeedMatrix, 
%collect the row of random years with the randomSeed

randomYears = randomSeedMatrix(climateRandomSeed,:);

if verbose == 1
    disp('climateSimulator:: randomYears vector ready, constructing simulated climate')
end
%%Define final simulated weather variables 
%%1-locate the positions on the simulated weather station where each randomly picked year occurs - store in "position"
auxYear = datevec(timestamp);
auxYear = auxYear(:,1);  %get the "year" column from all the simulated timestamps

%first element in randomYears
position = find(auxYear == randomYears(1));
yearOpToTraffic = datevec(dateOpenToTraffic);
yearOpToTraffic = yearOpToTraffic(1);
designYear = yearOpToTraffic*ones(length(position),1);   

%remaining elements
for k = 2:length(randomYears)
    aux = find(auxYear == randomYears(k));
    if isempty(aux)
        %small workaround when aux comes empty (a year-wide void in the
        %weather data, may occur when using non-continuous level-1 weather
        %data
        if k<length(randomYears)
         aux = find(auxYear == randomYears(k+1));
        else
         aux = find(auxYear == randomYears(k-1));
        end
    end
    
    position = [position; aux];   %output of "find" function is a column vector!
    designYear = [designYear; (designYear(1)+k-1)*ones(length(aux),1)];
end
clear aux;   %don't need it any longer.

%% 3 - construct the simulated weather variables
timestamp = timestamp(position);   %timestamp vector with the same length as the variables. Need to change year only - will use designYear to do so-)
%correct timestamp to design years;
auxTimestamp = datevec(timestamp);
timestamp = datenum(designYear(:),auxTimestamp(:,2),auxTimestamp(:,3),auxTimestamp(:,4),0,0);  %this is the timestamp vector with all the dates but the year (it starts in the design year)

temp = temp(position);
rain = rain(position);
wspd = wspd(position); 
srad = srad(position);
hum  =  hum(position);   %THESE VARIABLES HAVE COMPLETE YEARS ACCORDING TO THE YEAR SCRAMBLER!

%%3- Remove those timestamps that are from before the dateOpenToTraffic
datesToRemove = find(timestamp<dateOpenToTraffic);  %all the positions herein are dates that happen before the date the pave. is open to traffic. Remove them!
dtrLast = datesToRemove(end);  %this is the last position to remove. Redefine the export variables as var = var(dtrL+1:end)

timestamp = timestamp(dtrLast+1:end);
temp = temp(dtrLast+1:end);
rain = rain(dtrLast+1:end);
wspd = wspd(dtrLast+1:end);
srad = srad(dtrLast+1:end);
hum  =  hum(dtrLast+1:end);

if verbose == 1
    disp('climateSimulator:: Exporting simulated climate variables')
end
%%export as output...
climateMatrix = [timestamp temp hum wspd rain srad];
%Send also randomYears vector as output? or not nec.?

end   %%endFunction

