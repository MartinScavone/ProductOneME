function plotSuccess = plotTemperature(timestamp,airTemp,asphTemp)
%function plotSuccess = plotTemperature(timestamp,airTemp,asphTemp)
%Plotting Tools
%
%HMA TEMPERATURE PROFILE PLOTTER
%
%This auxiliary script will plot the HMA layers temperature time series
%Read values from: timestamp vector, air temperature series, and asphalt
%layer temperature series
%
%%v2019-03-18

%% code begins
%tip on how to plot a date in x-axis:
%%https://www.mathworks.com/help/matlab/matlab_prog/plot-dates-and-durations.html

%close figure 31

figure(31)
plot(datetime(datevec(timestamp)), airTemp,'r-.')
grid
xtickformat('dd-MMM-yyyy')
xlabel('date')
ylabel('temperature [deg C.]')
title('AC layers temperature')
legendString = {'air Temperature'};
hold on
[~,b] = size(asphTemp); %will have to plot the "b" columns
for k = 1:b
    plot(datetime(datevec(timestamp)),asphTemp(:,k),'color',rand(1,3));  
    %the rand(1,3) sentence will randomly cycle colors (using 3-value RGB color coordinates) for the different temperature series. 
    %Ref: https://www.mathworks.com/matlabcentral/answers/25831-plot-multiple-colours-automatically-in-a-for-loop
    addLegendString = sprintf('HMA Layer %g temperature',k);
    legendString = [legendString;{addLegendString}];
end
legend(legendString{:})  %The trick to make the increasing-size legend is from here: https://www.mathworks.com/matlabcentral/answers/38113-plot-help
hold off

plotSuccess = 1;
end


   

