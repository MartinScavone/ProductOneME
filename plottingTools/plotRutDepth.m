function plotSuccess = plotRutDepth(timestamp,rutDepth)
%function plotSuccess = plotRutDepth(timestamp,rutDepth)
%Plotting Tools - Rut-depth plot
%
%This auxiliary script will plot the calculated moisture of the pavement layers throughout the pavement's design life
%%V0.2 - 2019-04-04
%Changelog: Convert rut depth values to mm (they were passing in m)
%%V0.1 - St. Patrick's hangover: 2019-03-18
%   Changelog: x-axis labels in date format

%% code begins%

rutDepth = rutDepth * 1000;  %convert to mm!

figure(41)
auu = isnan(rutDepth(:,end));
if auu(end) ==0   %not isnan
    plot(datetime(datevec(timestamp)),rutDepth(:,end),'k','linewidth',2)
else
    %%%added this case to sort out when rut depth is a mass of NaNs
    plot(datetime(datevec(timestamp)),zeros(size(timestamp)),'b','linewidth',2)
end
grid
xlabel('date')
xtickformat('dd-MM-yy')
ylabel('total rut depth[mm]')
title('Depth of rut - sum of all layers')


if auu(end) ==0
    figure(42)
    plot(datetime(datevec(timestamp)), rutDepth(:,end),'k','linewidth',2)
    grid
    xlabel('date')
    xtickformat('dd-MM-yy')
    ylabel('total rut depth[mm]')
    title('Depth of rut - all layers combined')
    legendstring = {'Total Rut Depth'}; 
    hold on
    [~,b] = size(rutDepth);
    for i = 1:b-1    
        plot(datetime(datevec(timestamp)), rutDepth(:,i),'color',rand(1,3),'linewidth',2);
        if i<b-1
            addlegend = sprintf('Rut depth at layer %g',i);
        else
            addlegend = sprintf('Rut depth at the sub-grade');
        end
        legendstring = [legendstring;{addlegend}];
    end
    legend(legendstring{:});
    hold off
    plotSuccess = 1;
else  %%rutDepth is a NaN
    plotSuccess = 0;
end


end



   

