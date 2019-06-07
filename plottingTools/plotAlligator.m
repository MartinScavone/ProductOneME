function plotSuccess = plotAlligator(timestamp,AlligatorCrack,TopDownCrack)
%function plotSuccess = plotRutDepth(timestamp,rutDepth)
%Plotting Tools - Alligator cracking and top-down cracking
%
%This auxiliary script will plot the predicted extent of alligator
%(bottom-up) and longitudinal (top-down) cracking over the HMA layers
%
%%V0.1 - St. Patrick's hangover: 2019-03-18
%   Changelog: x-axis labels in date format

%% code begins
%
auu = isnan(AlligatorCrack(:,end));
figure(43)
if auu(end)==0
    plot(datetime(datevec(timestamp)), real(AlligatorCrack(:,1)),'b','linewidth',2)
    plotSuccess = 1;  
    legendstring = {'Cracking asph. lyr. 1'};
    hold on
    [~,b] = size(AlligatorCrack);
    for i = 2:b    
        plot(datetime(datevec(timestamp)), real(AlligatorCrack(:,i)),'color',rand(1,3),'linewidth',2);
        addlegend = sprintf('Cracking asph. lyr. %g',i);
        legendstring = [legendstring;{addlegend}];
    end
    legend(legendstring{:});
else
    plot(datetime(datevec(timestamp)), zeros(size(timestamp)),'b','linewidth',2)
    plotSuccess = 0;
end
grid
xlabel('date')
xtickformat('dd-MM-yy')
ylabel('alligator cracking [perc. lane area]')
title('Alligator cracking - all asphalt layers') 
hold off


%
figure(44)
if auu(end)==0
    plot(datetime(datevec(timestamp)), real(TopDownCrack(:,1)),'b','linewidth',2)
    legendstring = {'Cracking asph. lyr. 1'}; 
    hold on
    [~,b] = size(AlligatorCrack);
%     for i = 2:b    
%         plot(datetime(datevec(timestamp)), real(TopDownCrack(:,i)),'color',rand(1,3),'linewidth',2);
%         addlegend = sprintf('Cracking asph. lyr. %g',i);
%         legendstring = [legendstring;{addlegend}];
%     end
    legend(legendstring{:});
    hold off
else
    plot(datetime(datevec(timestamp)), zeros(size(timestamp)),'b','linewidth',2)
end
grid
xtickformat('dd-MM-yy')
xlabel('date')
ylabel('Top-Dn cracking [m/km]')
title('Top-Down cracking - all asphalt layers')


end



   

