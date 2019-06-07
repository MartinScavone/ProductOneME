function [singleL, single6, single10, tandems, tandem10, tandem14, tridem] = trafficToAxes(designTraffic,loadPercentage,trafficAxleLoadCat)
%function [singleL, singles, tandems, tandem10, tandem14, tridem] = trafficToAxes(designTraffic,loadPercentage,trafficAxleLoadCat)
%
%this function will convert the design traffic by category to axle counts summing up the axles from all categories.
%outputs are column vectors having hourly passes of each axle type (length equal to length of timeStamp vector - given in designTraffic (hourly vehicle traffic)).
%
%V0.1 2019-03-19:
%%Changelog9:: BUG DETECTED: definition of whatWeight
       %%origginally pointed at position (j) in the whatAxleIHave vectors (positions creating a subset of FL-UL/OL vectors.) 
       %Actually, %%whatWeight must be the weight in the position said by %whatAxleIHave(j)
       
%% code begins
[n,vehCats] = size(designTraffic);

%% 1 - variable initialization
run 'axlesWeights.m';
%retrieve the list of axles weight range by axle category.

%get the lengths of the load ranges
nsl = length(axlesSingleLWeights);
ns6 = length(axlesSingle6Weights);
ns10 = length(axlesSingle10Weights);
nt10= length(axlesTandem10Weights);
nt14= length(axlesTandem14Weights);
nt  = length(axlesTandemWeights);
ntr = length(axlesTridemWeights);

singleL = zeros(n,nsl);
single6 = zeros(n,ns6);
single10 = zeros(n,ns10);
tandems = zeros(n,nt);
tandem10 = zeros(n,nt10);
tandem14 = zeros(n,nt14);
tridem = zeros(n,ntr);


%% 2 - fill up the output variables. Go by column, summing up the traffic across all times!

for k = 1:vehCats
    %A - Get axle data for vehicles in category k
    percentages = loadPercentage(4*k-3:4*k);   %these are the percentage of unloaded / partially loaded / loaded / overloaded vehicles
    weightUL = trafficAxleLoadCat(4*k-3,:);   %bring the weights by axle for unloaded vehicles  
    weightPL = trafficAxleLoadCat(4*k-2,:);   %bring the weights by axle for partially loaded vehicles
    weightFL = trafficAxleLoadCat(4*k-1,:);   %bring the weights by axle for fully loaded vehicles
    weightOL = trafficAxleLoadCat(4*k,:);   %bring the weights by axle for overloaded vehicles
    % B - sort out the axles
    % %columns of the axle weight table:
    %col 1-2: single lightWeight // 3 - single single/wheel //4-7 single dual-wheel // 8 - Tandem single-wheel // 9 - tandem Non-homogeneous //10-12 - tandem dual-wheel // 13 - tridem (assumed as homogeneous 
    trafficCatK = [designTraffic(:,k)*percentages(1) designTraffic(:,k)*percentages(2) designTraffic(:,k)*percentages(3) designTraffic(:,k)*percentages(4)];   %this matrix here contains the design traffic of cat-K vehicles sorted according to weight range
    
    %--1: sort axles for unloaded vehicles
    whatAxleIHave = find(weightUL ~=0);  %non-zero values in weightUL will tell me which axles I have - whatAxleIHave contains the position of those non-zero values
    for j = 1:length(whatAxleIHave)
       axleType =  whatAxleIHave(j);
       %update V2019-03-19
       %whatWeight = weightUL(j);   %%locate axle weight for j-th non-zero element in the weightUL vector
       whatWeight = weightUL(axleType);   %%locate axle weight for j-th non-zero element in the weightUL vector+
       switch axleType
           case {1,2}  %axle is a light-weight single axle 
               targetColumn = find(axlesSingleLWeights == whatWeight);                       %locate what column of the singleL output matrix should I drop the axles to
               singleL(:,targetColumn) = singleL(:,targetColumn) + trafficCatK(:,1);    %add the axles.
           case 3      %axle is a single-wheel heavy single axle (legal load of 6 ton)
               targetColumn = find(axlesSingle6Weights == whatWeight);                       %locate what column of the single6 output matrix should I drop the axles to
               single6(:,targetColumn) = single6(:,targetColumn) + trafficCatK(:,1);    %add the axles.
           case {4,5,6,7}  %axle is a dual-wheel heavy single axle (legal load of 10.5 ton)
               targetColumn = find(axlesSingle10Weights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               single10(:,targetColumn) = single10(:,targetColumn) + trafficCatK(:,1);    %add the axles.
           case 8       %axle is a single-wheel heavy tandem axle (legal load of 10 ton)
               targetColumn = find(axlesTandem10Weights == whatWeight);                       %locate what column of the tandem10 output matrix should I drop the axles to
               tandem10(:,targetColumn) = tandem10(:,targetColumn) + trafficCatK(:,1);    %add the axles.               
           case 9       %axle is a Non-homogeneous heavy tandem axle (legal load of 14 ton)
               targetColumn = find(axlesTandem14Weights == whatWeight);                       %locate what column of the tandem14 output matrix should I drop the axles to
               tandem14(:,targetColumn) = tandem14(:,targetColumn) + trafficCatK(:,1);    %add the axles.               
           case {10,11,12} %axle is a dual-wheel heavy tandem axle (legal load of 18 ton)
               targetColumn = find(axlesTandemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tandems(:,targetColumn) = tandems(:,targetColumn) + trafficCatK(:,1);    %add the axles.               
           otherwise %case 13, axle is a dual-wheel heavy tridem axle (legal load of 22/25.5 ton)
               targetColumn = find(axlesTridemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tridem(:,targetColumn) = tridem(:,targetColumn) + trafficCatK(:,1);    %add the axles.              
       end  %end-switch             
    end   %end loop for the unloaded vehicles.
    
    %--2: repeat for partially loaded vehicles.
     whatAxleIHave = find(weightPL ~=0);  %non-zero values in weightUL will tell me which axles I have - whatAxleIHave contains the position of those non-zero values
    for j = 1:length(whatAxleIHave)
       axleType =  whatAxleIHave(j);
       %updave V2019-03-19
       %whatWeight = weightPL(j);   %%locate axle weight for j-th non-zero element in the weightUL vector
       whatWeight = weightPL(axleType);   %%locate axle weight for j-th non-zero element in the weightUL vector
       switch axleType
           case {1,2}  %axle is a light-weight single axle 
               targetColumn = find(axlesSingleLWeights == whatWeight);                       %locate what column of the singleL output matrix should I drop the axles to
               singleL(:,targetColumn) = singleL(:,targetColumn) + trafficCatK(:,2);    %add the axles.
           case 3      %axle is a single-wheel heavy single axle (legal load of 6 ton)
               targetColumn = find(axlesSingle6Weights == whatWeight);                       %locate what column of the single6 output matrix should I drop the axles to
               single6(:,targetColumn) = single6(:,targetColumn) + trafficCatK(:,2);    %add the axles.
           case {4,5,6,7}  %axle is a dual-wheel heavy single axle (legal load of 10.5 ton)
               targetColumn = find(axlesSingle10Weights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               single10(:,targetColumn) = single10(:,targetColumn) + trafficCatK(:,2);    %add the axles.
           case 8       %axle is a single-wheel heavy tandem axle (legal load of 10 ton)
               targetColumn = find(axlesTandem10Weights == whatWeight);                       %locate what column of the tandem10 output matrix should I drop the axles to
               tandem10(:,targetColumn) = tandem10(:,targetColumn) + trafficCatK(:,2);    %add the axles.               
           case 9       %axle is a Non-homogeneous heavy tandem axle (legal load of 14 ton)
               targetColumn = find(axlesTandem14Weights == whatWeight);                       %locate what column of the tandem14 output matrix should I drop the axles to
               tandem14(:,targetColumn) = tandem14(:,targetColumn) + trafficCatK(:,2);    %add the axles.               
           case {10,11,12} %axle is a dual-wheel heavy tandem axle (legal load of 18 ton)
               targetColumn = find(axlesTandemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tandems(:,targetColumn) = tandems(:,targetColumn) + trafficCatK(:,2);    %add the axles.               
           otherwise %case 13, axle is a dual-wheel heavy tridem axle (legal load of 22/25.5 ton)
               targetColumn = find(axlesTridemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tridem(:,targetColumn) = tridem(:,targetColumn) + trafficCatK(:,2);    %add the axles.              
       end  %end-switch             
    end   %end loop for the partially loaded vehicles.
    
    %--3: repeat for fully loaded vehicles.
    whatAxleIHave = find(weightFL ~=0);  %non-zero values in weightUL will tell me which axles I have - whatAxleIHave contains the position of those non-zero values
    for j = 1:length(whatAxleIHave)
       axleType =  whatAxleIHave(j);
       %%update V2019-03-19:: BUG DETECTED: definition of whatWeight
       %%origginally pointed at position (j) in the whatAxleIHave vectors (positions creating a subset of FL-UL/OL vectors.) 
       %Actually, %%whatWeight must be the weight in the position said by %whatAxleIHave(j)
       %WRONG: whatWeight = weightFL(j)
       whatWeight = weightFL(axleType);   %%locate axle weight for j-th non-zero element in the weightUL vector
       switch axleType
           case {1,2}  %axle is a light-weight single axle 
               targetColumn = find(axlesSingleLWeights == whatWeight);                       %locate what column of the singleL output matrix should I drop the axles to
               singleL(:,targetColumn) = singleL(:,targetColumn) + trafficCatK(:,3);    %add the axles.
           case 3      %axle is a single-wheel heavy single axle (legal load of 6 ton)
               targetColumn = find(axlesSingle6Weights == whatWeight);                       %locate what column of the single6 output matrix should I drop the axles to
               single6(:,targetColumn) = single6(:,targetColumn) + trafficCatK(:,3);    %add the axles.
           case {4,5,6,7}  %axle is a dual-wheel heavy single axle (legal load of 10.5 ton)
               targetColumn = find(axlesSingle10Weights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               single10(:,targetColumn) = single10(:,targetColumn) + trafficCatK(:,3);    %add the axles.
           case 8       %axle is a single-wheel heavy tandem axle (legal load of 10 ton)
               targetColumn = find(axlesTandem10Weights == whatWeight);                       %locate what column of the tandem10 output matrix should I drop the axles to
               tandem10(:,targetColumn) = tandem10(:,targetColumn) + trafficCatK(:,3);    %add the axles.               
           case 9       %axle is a Non-homogeneous heavy tandem axle (legal load of 14 ton)
               targetColumn = find(axlesTandem14Weights == whatWeight);                       %locate what column of the tandem14 output matrix should I drop the axles to
               tandem14(:,targetColumn) = tandem14(:,targetColumn) + trafficCatK(:,3);    %add the axles.               
           case {10,11,12} %axle is a dual-wheel heavy tandem axle (legal load of 18 ton)
               targetColumn = find(axlesTandemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tandems(:,targetColumn) = tandems(:,targetColumn) + trafficCatK(:,3);    %add the axles.               
           otherwise %case 13, axle is a dual-wheel heavy tridem axle (legal load of 22/25.5 ton)
               targetColumn = find(axlesTridemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tridem(:,targetColumn) = tridem(:,targetColumn) + trafficCatK(:,3);    %add the axles.              
       end  %end-switch             
    end   %end loop for the fully loaded vehicles.
    
    %--4: repeat for overloaded vehicles.
    whatAxleIHave = find(weightOL ~=0);  %non-zero values in weightUL will tell me which axles I have - whatAxleIHave contains the position of those non-zero values
    for j = 1:length(whatAxleIHave)
       axleType =  whatAxleIHave(j);
       %update V2019-03-19: Bug correction.
       %whatWeight = weightOL(j);   %%locate axle weight for j-th non-zero element in the weightUL vector
       whatWeight = weightOL(axleType);   %%locate axle weight for j-th non-zero element in the weightUL vector
       switch axleType
           case {1,2}  %axle is a light-weight single axle 
               targetColumn = find(axlesSingleLWeights == whatWeight);                       %locate what column of the singleL output matrix should I drop the axles to
               singleL(:,targetColumn) = singleL(:,targetColumn) + trafficCatK(:,4);    %add the axles.
           case 3      %axle is a single-wheel heavy single axle (legal load of 6 ton)
               targetColumn = find(axlesSingle6Weights == whatWeight);                       %locate what column of the single6 output matrix should I drop the axles to
               single6(:,targetColumn) = single6(:,targetColumn) + trafficCatK(:,4);    %add the axles.
           case {4,5,6,7}  %axle is a dual-wheel heavy single axle (legal load of 10.5 ton)
               targetColumn = find(axlesSingle10Weights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               single10(:,targetColumn) = single10(:,targetColumn) + trafficCatK(:,4);    %add the axles.
           case 8       %axle is a single-wheel heavy tandem axle (legal load of 10 ton)
               targetColumn = find(axlesTandem10Weights == whatWeight);                       %locate what column of the tandem10 output matrix should I drop the axles to
               tandem10(:,targetColumn) = tandem10(:,targetColumn) + trafficCatK(:,4);    %add the axles.               
           case 9       %axle is a Non-homogeneous heavy tandem axle (legal load of 14 ton)
               targetColumn = find(axlesTandem14Weights == whatWeight);                       %locate what column of the tandem14 output matrix should I drop the axles to
               tandem14(:,targetColumn) = tandem14(:,targetColumn) + trafficCatK(:,4);    %add the axles.               
           case {10,11,12} %axle is a dual-wheel heavy tandem axle (legal load of 18 ton)
               targetColumn = find(axlesTandemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tandems(:,targetColumn) = tandems(:,targetColumn) + trafficCatK(:,4);    %add the axles.               
           otherwise %case 13, axle is a dual-wheel heavy tridem axle (legal load of 22/25.5 ton)
               targetColumn = find(axlesTridemWeights == whatWeight);                       %locate what column of the single10 output matrix should I drop the axles to
               tridem(:,targetColumn) = tridem(:,targetColumn) + trafficCatK(:,4);    %add the axles.              
       end  %end-switch             
    end   %end loop for the fully loaded vehicles.    
    
end   %end loop for vehicle categories.



end   %endfunction




