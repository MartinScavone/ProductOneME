function [monthlyRainStd,avgAnnualRain,tempFI] = IRIclimateSiteFactor(timestamp,rain,temperature)
% function [monthlyRainStd,avgAnnualRain,tempFI] = IRIclimateSiteFactor(timestamp,rain,temperature)
%
%Ancillary function to the IRI calculation module. It computes the
%climate-based terms of the Site-Factor equation from the project's site
%simulated climate records.
%
%INPUT
%timestamp - time vector of the climate variables [in Matlab's timestamp format - 1 hour long!]
%rain      - rainfall record [mm]
%temperature-air temperature record [degC]
%
%OUTPUT
% monthlyRainStd - standard deviation of the monthly total rainfall [mm]
% avgAnnualRain  - average annual rain for the entire input period [mm]
% tempFI         - average annual freezing index (max avg daily temp - min avg daily temp) [deg C]
%
%V0.0 2019-03-04

timeMatrix = datevec(timestamp);
yearStart = timeMatrix(1,1);
yearEnd   = timeMatrix(end,1);

%% 1 - compute the avg yearly rain
if yearEnd>yearStart
    auxYears = yearStart:1:yearEnd;
else
    auxYears = yearStart;  %just-in-case if statement, case I'm runnign a 1-yr design.
end
annRain  = zeros(length(auxYears),1);

if length(auxYears) ==1
    annRain   = sum(rain)*365*24/length(timestamp);  %if I'm modeling a single-year design, the annRain is just the sum of the rain entries
    %this ratio multiplier here will extrapolate teh average annual rain to a 365-day year (case I'm modelling less than 1 year)
    avgAnnualRain = annRain; 
else
    %start accumulating rain for all the years. Add the trick for the 1-yr
    %case (to extrapolate the annual rain in the cases of timestamps
    %starting half-way through a year)
    yearNo     = 1;
    auxDayCounter = 1;
    annRain(yearNo) = rain(1);
    auxYearID = auxYears(1);
    for j = 2:length(timestamp)
        dateTime = timeMatrix(j);
        if j<length(timestamp)
            if auxYearID == dateTime(1)   %the year of the date of the j-th record in timestamp matches the year I'm summing up
                annRain(yearNo) = annRain(yearNo) + rain(j);
                auxDayCounter = auxDayCounter+1;
            else
                annRain(yearNo) = annRain(yearNo)*365*24/auxDayCounter;
                %change year / reset variables
                yearNo = yearNo+1;
                auxDayCounter   = 1;
                annRain(yearNo) = rain(j);
            end
        else
            %termination [CASE J == last] - pull out results
            annRain(yearNo) = annRain(yearNo)*365*24/auxDayCounter;
        end                   
    end
    avgAnnualRain = mean(annRain);
end

%% 2 - compute monthly rainfall records
%I'm lazy and will copy the loop above and modify accordingly (I don't feel
%like merging all the searches together)
%
monthStart = timeMatrix(1,2);
monthEnd   = timeMatrix(end,2) + 12*(yearEnd-yearStart);
auxMonths = monthStart:1:monthEnd;

monRain  = zeros(length(auxMonths),1);

%%ASSUMING MORE THAN 1 MONTH IS BEING MODELED HERE!

%start accumulating rain for all the years. Add the trick for the 1-yr
%case (to extrapolate the annual rain in the cases of timestamps
%starting half-way through a year)
monthNo     = 1;
auxDayCounter = 1;
monRain(monthNo) = rain(1);
auxMonID = auxMonths(1);
for j = 2:length(timestamp)
    dateTime = timeMatrix(j,:);
    if j<length(timestamp)
        if auxMonID == dateTime(2)+12*(dateTime(1)-yearStart)   %the month of the date of the j-th record in timestamp matches the year I'm summing up
            monRain(monthNo) = monRain(monthNo) + rain(j);
            auxDayCounter = auxDayCounter+1;
        else
            monRain(monthNo) = monRain(monthNo)*30*24/auxDayCounter;
            %change month / reset variables
            monthNo = monthNo+1;
            auxMonID = auxMonths(monthNo);
            auxDayCounter   = 1;
            monRain(monthNo) = rain(j);
        end
    else
        %termination [CASE J == last] - pull out results
        monRain(monthNo) = monRain(monthNo)*30*24/auxDayCounter;
    end                   
end
monthlyRainStd = std(monRain);

%% 3 - do the freezing index calculations.
%a) compute maximum and minimum temp for every day
%b) get the avg daily temp as (0.5* [max+min])
%c) and then for each year FI(year) = max(avgTemp)-min(avg(Temp)

%%important note: when I have truncated years (simulation started on a date
%%other than Jan 1 and ended other than dec 31), the Avg FI would not be
%%exact (the truncated years would not give appropriate FI values)

dayStart = floor(timestamp(1));
dayEnd   = floor(timestamp(end));
auxDays  = dayStart:1:dayEnd;

tmaxDay = temperature(1);
tminDay = temperature(1);
tavgDay  = zeros(length(auxDays),1);
tavgDay(1) = mean([tmaxDay,tminDay]);

dayNo      = 1;
auxDayID   = dayStart;

%part A) get the min, max, avg temperature for each day  

for j = 2:length(timestamp)
%     dateTime = timeMatrix(j);
    if j<length(timestamp)
        if auxDayID == floor(timestamp(j))
            tmaxDay = max([tmaxDay;temperature(j)]);
            tminDay = min([tminDay;temperature(j)]);
        else
            tavgDay(dayNo) = (tmaxDay+tminDay)/2;
            %change year / reset variables
            dayNo = dayNo+1;
            auxDayID = auxDays(dayNo);
            tmaxDay = temperature(j);
            tminDay = temperature(j);
        end
    else
        %termination [CASE J == last] - pull out results
        tavgDay(dayNo) = (tmaxDay+tminDay)/2;
    end                   
end

% part B) get the FI for each year

yearRange = datevec(auxDays);
yearRange = yearRange(:,1);   %%vector with all the year values in yearRange
%should pair with  - - auxYears

annualFI = zeros(length(auxYears),1);

for i = 1:length(annualFI)
    rangeToSearch = find(yearRange ==auxYears(i));
    maxTavg = max(tavgDay(rangeToSearch));
    minTavg = min(tavgDay(rangeToSearch));
    annualFI(i) = maxTavg - minTavg;
end

tempFI = mean(annualFI);

end %endfunction
