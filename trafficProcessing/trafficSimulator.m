function [designTraffic,designAADT] = trafficSimulator(timestamp,AADTBaseYear,AADTGrowthRate,AADTMonthlyDistr,AADTDailyDistr,AADTHourlyDistr)
% [designTraffic,designAADT] = trafficSimulator(timeStamp,AADTBaseYear,AADTGrowthRate,AADTMonthlyDistr,AADTDatilyDistr,AADTHourlyDistr);
%Auxiliary function to calculate the total number of vehicles over the pavement's design period
% OUTPUT: 
%  designTraffic::  Matrix sized [timestamp x number of vehicle categories]%  with the 12-hourly traffic per category   
%  designAADT   ::  Matrix sized (1+number of vehicle cats x design years)  with the yearly AADTs
%
%update 2019-03-19:
%   Changelog:: Corrected AADT asignation for each timestamp (was only bringing AADT for cars, and not for all vehicle categories)
%update 2019-03-15: Corrected an error in the extrapolation (it was
%applying the growth rate from the current year traffic to get next year's at a power, when it should be linear...)
%update 2018-06-20: The designTraffic will be nighttime/daytime portions of
%traffic per category instead of hourly vehicle flow  (this code itself should not change)

%% 1 - initialize output
numVehicleCats = length(AADTBaseYear);
n = length(timestamp);

designTraffic = zeros(n,numVehicleCats);
initialYear = datevec(timestamp(1));
lastYear = datevec(timestamp(end));

%% 2 - apply the yearly increase rate to AADT to obtain future traffic volumes
%store in auxiliary variable...

auxTime = initialYear:1:lastYear;
nAT = length(auxTime);

auxAADT = zeros(numVehicleCats,nAT);
auxAADT(:,1) = AADTBaseYear;
%auxAADT is storing the increased traffic (use along auxTime)
for k = 2:nAT
    auxAADT(:,k) = auxAADT(:,k-1).*((1+AADTGrowthRate));%.^(k-1));
end
%consider transposing auxAADT so that it ends up being each column the AADT
%for each vehicle category. - not do, I need TPDA's in column format
%IN CURRENT FORMAT, auxAADT is rows = vehicle categories; columns = years;

%% 3 - Now scan timestamp vector to get hourly trafffic per category - iteration done over time

for k = 1 :n
    auxDate = datevec(timestamp(k));   %auxDate is year / mo / day / hour / min / 
    locateTPDA = find(auxTime == auxDate(1));  %locate which year I am using     %%NOTE: Matlab suggests this notation <<locateTPDA = auxTime == auxDate(1)>>;
    %update V2019-03-19:: original statement here only pulled AADT for cars and not for all categories. Corrected!
    TPDA = auxAADT(:,locateTPDA);  %pull the AADT by category for that year. - column vector
        
    %update 2018-06-20 - hourly factor now is a 6Am (night-time subtotal) or 6Pm (18hs, daytime subtotal)
    thisMonthFactor = AADTMonthlyDistr(:,auxDate(2)); %pick the monthly correction factor [column vector]
    whatDayIsIt = weekday(timestamp(k));
    thisDayFactor   = AADTDailyDistr(:,whatDayIsIt);  %pick the daily correction factor for day 1-7 [sun-sat]
    if auxDate(4) == 6   %sum late-hour nighttime traffic from current day plus nighttime traffic from prev. day
        if k > 1
            auxDate2 = datevec(timestamp(k-1));
            whatDayWasYest = weekday(timestamp(k-1));
        else
            auxDate2 = [auxDate(1) auxDate(2) auxDate(3) auxDate(4)-1 0 0];
            whatDayWasYest = weekday(datenum(auxDate2));
        end
        thisHourFactor = AADTHourlyDistr(:,1); %pick the late nighttime hourly factor from day k (1st column) and the early night factor to apply to day k-1 (3rd column)
        thisHourFactor2 = AADTHourlyDistr(:,3);
        thisMonthFactor2 = AADTMonthlyDistr(:,auxDate2(2)); %pick the monthly correction factor for k-1 day [column vector]
        thisDayFactor2   = AADTDailyDistr(:,whatDayWasYest);  %pick the daily correction factor for day 1-7 [sun-sat]
        trafficThisHour = TPDA .* thisMonthFactor .*thisDayFactor .*thisHourFactor/100 + TPDA .* thisMonthFactor2 .*thisDayFactor2 .*thisHourFactor2/100 ;   %%the "hour factor" is a percentage value!, should divide by 100 to get the intended value
    
    else   %only need to sum up daytime traffic
        thisHourFactor  = AADTHourlyDistr(:,2); %pick the daytime hourly factor  [2nd column vector]
        trafficThisHour = TPDA .* thisMonthFactor .*thisDayFactor .*thisHourFactor/100;   %%the "hour factor" is a percentage value!, should divide by 100 to get the intended value
    end    
    designTraffic(k,:) = trafficThisHour';    
end

designAADT = [auxTime; auxAADT];

end  %endfunction