function plotSuccess = plotIRIPSI(timestamp,IRI,PSI)
%function plotSuccess = plotSoilHydraulics(timestamp,rain,soilMoistureMatrix,surfaceInfiltration,surfacerunoff)
%Plotting Tools - IRI and PSI prediction
%
%This auxiliary script will plot the predicted roughness index (IRI) and
%Serviceability index (PSI), which were computed from the predicted
%distresses
%%V0.1 - St. Patrick's hangover: 2019-03-18
%   Changelog: x-axis labels in date format

%% code begins
figure(45)
yyaxis left
plot(datetime(datevec(timestamp)), real(IRI),'b','linewidth',2)
grid
xlabel('date')
xtickformat('dd-MM-yy')
ylabel('IRI [m/km]')
title('Predicted IRI and PSI')

yyaxis right
plot(datetime(datevec(timestamp)),real(PSI),'color','r','linewidth',2);
ylabel('PSI [dimless]')
xtickformat('dd-MM-yy')
legendstring = [{'IRI'}, {'PSI'}]; 
legend(legendstring{:});
hold off

plotSuccess = 1;

end



   

