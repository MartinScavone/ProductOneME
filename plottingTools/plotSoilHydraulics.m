function plotSuccess = plotSoilHydraulics(timestamp,rain,soilMoistureMatrix,surfaceInfiltration,surfaceRunoff)
%function plotSuccess = plotSoilHydraulics(timestamp,rain,soilMoistureMatrix,surfaceInfiltration,surfacerunoff)
%Plotting Tools
%
%PREDICTED SOIL MOISTURE PLOTTING TOOL
%
%This auxiliary script will plot the calculated moisture of the pavement layers throughout the pavement's design life
%%V0.1 - St. Patrick's hangover: 2019-03-18
%   Changelog: x-axis labels in date format

%% code begins
%close figure 32 figure 33
figure(32)
plot(datetime(datevec(timestamp)), rain,'b','linewidth',2)
grid
xlabel('timestamp')
xtickformat('dd-MM-yy')
ylabel('unit runoff [mm/12h]')
title('Rainfall and infiltration')

hold on
plot(datetime(datevec(timestamp)),real(surfaceInfiltration),'color',[0.60,0.33,0.45],'linewidth',2);
ylabel('runoff [mm/12h]')
plot(datetime(datevec(timestamp)),real(surfaceRunoff),'k','linewidth',2);
legend([{'Rainfall'};{'infiltration'};{'surfaceRunoff'}]); 
hold off

figure(33)
yyaxis left
plot(datetime(datevec(timestamp)), rain,'b','linewidth',2)
grid
xtickformat('dd-MM-yy')
xlabel('timestamp')
ylabel('rainfall [mm]')
title('Rainfall and granular layers" moisture')
legendstring = {'Rainfall'}; 

yyaxis right
hold on
[~,b] = size(soilMoistureMatrix);
for i = 1:b
    
    plot(datetime(datevec(timestamp)), soilMoistureMatrix(:,i),'color',rand(1,3),'linewidth',2);
    if i<b
        addlegend = sprintf('Granular Layer %g moisture',i);
    else
        addlegend = sprintf('sub-grade moisture');
    end
    legendstring = [legendstring;{addlegend}];
end
ylabel('Vol. moisture cont. [%]')
legend(legendstring{:});
hold off

plotSuccess = 1;
end



   

