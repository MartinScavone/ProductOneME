function plotSuccess = plotHMATemperature(timestamp,airTemp,asphTemp)
%function plotSuccess = plotHMATemperature(timestamp,airTemp,asphTemp)
%Plotting Tools
%
%HMA TEMPERATURE PROFILE PLOTTER
%
%This auxiliary script will plot the HMA layers temperature time series
%Read values from: timestamp vector, air temperature series, and asphalt
%layer temperature series
%V0.1 - St. Patrick's hangover: 2019-03-18
%   Changelog: x-axis labels in date format

%% code begins

%close figure 31

figure(31)
plot(datetime(datevec(timestamp)), airTemp,'r-.')
grid
xlabel('date')
xtickformat('dd-MM-yy')
ylabel('temperature [deg C.]')
title('AC layers temperature')
legendString = {'air Temperature'};
hold on
plot(datetime(datevec(timestamp)),asphTemp(:,1),'color',rand(1,3));  
legendString = [legendString;{'HMA Surface temperature'}];

[~,b] = size(asphTemp); %will have to plot the "b" columns
for k = 2:b
    plot(datetime(datevec(timestamp)),asphTemp(:,k),'color',rand(1,3));  
    %the rand(1,3) sentence will randomly cycle colors (using 3-value RGB color coordinates) for the different temperature series. 
    %Ref: https://www.mathworks.com/matlabcentral/answers/25831-plot-multiple-colours-automatically-in-a-for-loop
    addLegendString = sprintf('HMA Layer %g temperature',k-1);
    legendString = [legendString;{addLegendString}];
end
legend(legendString{:})  %The trick to make the increasing-size legend is from here: https://www.mathworks.com/matlabcentral/answers/38113-plot-help
hold off

plotSuccess = 1;
end


   

