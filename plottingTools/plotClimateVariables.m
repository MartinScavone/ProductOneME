function plotSuccess = plotClimateVariables(timestamp,temp,hum,wspd,srad,rain)
%function plotSuccess = plotClimateVariables(timestamp,temp,hum,wspd,rad,rain)
%Plotting Tools
%
%SIMULATED CLIMATE VARIABLES PLOTTER
%
%This auxiliary script will plot the resulting site's simulated climate
%variables time series throughout the design life
%V0.1 - St. Patrick's hangover: 2019-03-18
%   Changelog: x-axis labels in date format

%% code begins
%close figure 1 figure 2 figure 3 figure 4 figure 5
figure(1)
plot(datetime(datevec(timestamp)), temp,'r-.');
grid
xtickformat('dd-MM-yy')
xlabel('date')
ylabel('air temperature[deg C.]')
title('Air Temperature')
legend('air Temperature');

figure (2)
plot(datetime(datevec(timestamp)), hum,'b-.');
grid
xtickformat('dd-MM-yy')
xlabel('date')
ylabel('Humidity [%]')
title('Air humidity')
legend('Humidity [%]');

figure(3)
plot(datetime(datevec(timestamp)), wspd,'k-.');
grid
xtickformat('dd-MM-yy')
xlabel('date')
ylabel('wind speed [m/s]')
title('Wind Speed')
legend('Wind [m/s]');

figure(4)
plot(datetime(datevec(timestamp)), rain,'b--');
grid
xtickformat('dd-MM-yy')
xlabel('date')
ylabel('rainfall [mm]')
title('Rainfall')
legend('Rain [mm]');

figure(5)
plot(datetime(datevec(timestamp)), srad,'color',rand(1,3));
 %the rand(1,3) sentence will randomly cycle colors (using 3-value RGB color coordinates) for the different temperature series. 
    %Ref: https://www.mathworks.com/matlabcentral/answers/25831-plot-multiple-colours-automatically-in-a-for-loop
grid
xtickformat('dd-MM-yy')
xlabel('date')
ylabel('Avg. Sun Net Radiation [Watt/m^2]')
title('Average Solar Net Radiation')
legend('SRad Net [Watt/m^2]');


plotSuccess = 1;
end



   

