function plotSuccess = plotMR(timestamp,MRMatrix)
%function plotSuccess = plotMR(timestamp,MRMatrix)
%Plotting Tools - Unbound materials' resilient modulus plotter
%
%This auxiliary script will plot the unsaturated Resilient Modulus timeseries for each
%granular material and the subgrade.
%
%MRMatrix is a [timestamp-long - by - number-of-layers] matrix containing the layers' MR values at each timestamp
%close figure 34
%
%%V2019-03-18

%% code begins

figure(34)
plot(datetime(datevec(timestamp)), MRMatrix(:,1),'r-.')
grid
xlabel('date')
xtickformat('dd-MM-yy')
ylabel('Reesilient Modulus [PSI]')
title('Granular layers and subgrade resilient Modulus')
legendString = {'Granular layer 1'};
hold on
[~,b] = size(MRMatrix); %will have to plot the "b" columns
for k = 2:b
    plot(datetime(datevec(timestamp)),MRMatrix(:,k),'color',rand(1,3));  
    %the rand(1,3) sentence will randomly cycle colors (using 3-value RGB color coordinates) for the different temperature series. 
    %Ref: https://www.mathworks.com/matlabcentral/answers/25831-plot-multiple-colours-automatically-in-a-for-loop
    if k<b
        addLegendString = sprintf('Granular layer %g',k);
        legendString = [legendString;{addLegendString}];
    else
        addLegendString = sprintf('Subgrade');
        legendString = [legendString;{addLegendString}];
    end
end
legend(legendString{:})  %The trick to make the increasing-size legend is from here: https://www.mathworks.com/matlabcentral/answers/38113-plot-help
hold off

plotSuccess = 1;
end


   

