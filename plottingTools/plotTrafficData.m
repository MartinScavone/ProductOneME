function [plotSuccess,reducedTrafficVars] = plotTrafficData(timestamp,AADTMatrix)
%function plotSuccess = plotTrafficData(timestamp,AADTMatrix)
%Plotting Tools - Yearly Traffic by category
%
%This auxiliary script will plot the predicted AADT values for each R103
%and %R110 category (cars, buses, light-trucks, semi-trucks, heavy-trucks)
%over each year
%close figure 21

%% 1 - get years' vector from the timeStamp

years = year(datetime(datevec(timestamp(1)))):1:year(datetime(datevec(timestamp(end))));

%% 2  - plot AADT by cat. as is.

figure(21)
plot(years, AADTMatrix(1,:),'color',rand(1,3));
grid
xlabel('year')
ylabel('AADT design lane [vehicles/year]')
title('Traffic by R103 category - design lane only')

hold on

[a,~] = size(AADTMatrix); %will have to plot the "a"rows (each for a vehicle category
for k = 2:a
    plot(years,AADTMatrix(k,:),'color',rand(1,3));  
    %the rand(1,3) sentence will randomly cycle colors (using 3-value RGB color coordinates) for the different temperature series. 
    %Ref: https://www.mathworks.com/matlabcentral/answers/25831-plot-multiple-colours-automatically-in-a-for-loop
end
legend([{'A11'},{'O11'},{'O12'},{'O22'},{'C11'},{'C12'},{'C22'},{'T11S1'},{'T11S2'},{'T12S1'},{'T11S11'},{'C11R11'},{'T11S3'},{'T12S2'},{'T11S12'},{'T12S11'},{'T12S3'},{'C11R12'},{'C12R11'},{'C12R12'},{'T11S111'},{'T12S111'},{'T12S2S2'}]);
hold off

%% - get reduced plot (5-cat)
cars = AADTMatrix(1,:);
buses = AADTMatrix(2,:)+AADTMatrix(3,:)+AADTMatrix(4,:);
trucksLT = AADTMatrix(5,:)+AADTMatrix(6,:);
trucksMD = +AADTMatrix(7,:)+AADTMatrix(8,:)+AADTMatrix(9,:)+AADTMatrix(10,:)+AADTMatrix(11,:);
trucksHV = sum(AADTMatrix(12:end,:));  %I don't feel like writing all the columns manually. This workaround may do the job.

reducedTrafficVars = [cars; buses; trucksLT; trucksMD; trucksHV];
figure(22)
plot(years,cars,'r')
grid
title('Traffic by Reduced category - design lane only')
xlabel('year')
ylabel('AADT design lane [vehicles/year]')
hold on
plot(years,buses,'b')
plot(years,trucksLT,'color',rand(1,3))
plot(years,trucksMD,'color',rand(1,3))
plot(years,trucksHV,'color',rand(1,3))
legend('cars','buses','light trucks','mid-size trucks','heavy trucks')
hold off
plotSuccess = 1;
end



   

