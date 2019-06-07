function [ auxE ] = getAuxEfromE(zShort,zLong,E)
%function [ auxE ] = getZfromPaveDepth(zShort, zLong, E)
%MULTI-LYR LINEAR ELASTIC ANALYSIS PROGRAM
%This is an auxiliary function that will build the vector of variable E (with valuese for each z position in zShort.
%
%Input:
% - zShort vector of points (short series, few points [in this case, the cumsum of the layers' thicknesses)
% - zLong  vector of points (long  series, morepoints [all the computation points in the MLE problem]
% - E      Variable you want to extend from zShort to zLong
%Output:
% - auxE   Extended variable
% 
%
% V0.1: 2019-02-07

%% code begins

%convert thicknesses to depths, and cm to meters. And remove the subgrade thickness entry (I won't need it) 
auxE = zeros(length(zLong),1);

%step 1 - fill in the auxE values for each position Z in zLong
%first pass, smaller than the 1st depth value in zShort
targetPos = find(zLong<=zShort(1));
auxE(targetPos) = E(1);
%second pass, smaller than the ith depth value but greater than the i-1 th
for i = 2:length(zShort)
    targetPos = find(zLong<=zShort(i) & zLong>zShort(i-1));
    auxE(targetPos) = E(i);    
end

%%all done!
end

