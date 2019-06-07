%% PRODUCT-ONE PAVEMENT DESIGN TOOL
%FRONT END CODE FOR THE DISTRESS CALCULATIONS
%
%This script will direct the calls to auxiliary functions to compute the
%intended distresses over the pavement structure for each time moment, each
%level of load and each axle type
% 
%%THESE ARE THE VARIABLES THAT ARE TO BE FILLED. 
%EACH CALL TO THIS SCRIPT WILL FILL UP ROW (k) OF THESE MATRICES/VECTORS.
% rutDepth=zeros(termination,1);           % metric Units [m]
%
%V0.4 2019-05-14
%   Changelog: adapt code to new 4-D stress and strain matrices (added time
%   variable as 4th dimension)
%V0.3 Mother's Day: 2019-05-12
%   Changelog: Simplified rut-depth calculator fore each axle.
%   Using only the location UNDER ONE OF THE AXLE'S WHEELS
%   >>Need to clean up non-nec variables if successful<<
%V0.2 St.Patrick's Day: 2019-03-17
%   Changelog: Tuned up to account for the "strain hardening?" methodology to account for loads on previous passes
%V0.1 2019-02-22
%---first debugging completed 2019-02-26
%   Changelog: First complete beta. Separate Rut depth calculations from other distresses
%V0.0 Valentine's Day: 2019-02-14

%% CODE BEGINS
%% Update V2019-03-17: 
%If first run of the code, initialize the "cache" of plastic strains from
%previous runs and fill with zeros. The code will retrieve the numbers from
%here as needed.
%Initialize with -9999s cause this number the rutDepthCompute will
%understand refers to "no previous iteration, Neq = 0"
%%update V2019-05-14: convert to 4-D arrays (store time variable;
%%calculation results will be kept for quality check)
if k ==1
   eplCacheSingleL   = -9999*ones(length(paveDepths),nrsL,length(axlesSingleLWeights),termination);
   eplCacheSingle6   = -9999*ones(length(paveDepths),nrs6,length(axlesSingle6Weights),termination);
   eplCacheSingle10  = -9999*ones(length(paveDepths),nrs10,length(axlesSingle10Weights),termination);
   eplCacheTandem10  = -9999*ones(length(paveDepths),nrTa10,length(axlesTandem10Weights),termination);
   eplCacheTandem14  = -9999*ones(length(paveDepths),nrTa14,length(axlesTandem14Weights),termination);
   eplCacheTandem18  = -9999*ones(length(paveDepths),nrTa18,length(axlesTandemWeights),termination);
   eplCacheTridem    = -9999*ones(length(paveDepths),nrTr,length(axlesTridemWeights),termination);    
   
   %%UPDATE V2019-05-14: Add 4th dimension (time) to all rut-depth variables. I'm storing the results for post-proc and quality check
    auxrutDepthHMASingleL        = zeros(ACLayersNumber,nrsL,length(axlesSingleLWeights),termination);
    auxrutDepthGranSingleL       = zeros(length(paveDepths)-1-ACLayersNumber,nrsL,length(axlesSingleLWeights),termination);
    auxrutDepthSubGradeSingleL   = zeros(1,nrsL,length(axlesSingleLWeights),termination);
    auxMaxRutSingleL             = zeros(nrsL,length(axlesSingleLWeights),termination);    %%put here the sum of all rut depths
    % auxMaxRutPosition            = zeros(length(axlesSingleLWeights)); %%get the r position of the maximum rut depth for all weights  %%V2019-05-14: NO LONGER NEEDED
    
    auxrutDepthHMASingle6        = zeros(ACLayersNumber,nrs6,length(axlesSingle6Weights),termination);
    auxrutDepthGranSingle6       = zeros(length(paveDepths)-1-ACLayersNumber,nrs6,length(axlesSingle6Weights),termination);
    auxrutDepthSubGradeSingle6   = zeros(1,nrs6,length(axlesSingle6Weights),termination);
    auxMaxRutSingle6             = zeros(nrs6,length(axlesSingle6Weights),termination);    %%put here the sum of all rut depths
% auxMaxRutPosition            = zeros(length(axlesSingle6Weights)); % %%get the r position of the maximum rut depth for all weights %%V2019-05-14: NO LONGER NEEDED

    auxrutDepthHMASingle10        = zeros(ACLayersNumber,nrs10,length(axlesSingle10Weights),termination);
    auxrutDepthGranSingle10       = zeros(length(paveDepths)-1-ACLayersNumber,nrs10,length(axlesSingle10Weights),termination);
    auxrutDepthSubGradeSingle10   = zeros(1,nrs10,length(axlesSingle10Weights),termination);
    auxMaxRutSingle10             = zeros(nrs10,length(axlesSingle10Weights),termination);    %%put here the sum of all rut depths
    
    auxrutDepthHMATandem10        = zeros(ACLayersNumber,nrTa10,length(axlesTandem10Weights),termination);
    auxrutDepthGranTandem10       = zeros(length(paveDepths)-1-ACLayersNumber,nrTa10,length(axlesTandem10Weights),termination);
    auxrutDepthSubGradeTandem10   = zeros(1,nrTa10,length(axlesTandem10Weights),termination);
    auxMaxRutTandem10             = zeros(nrTa10,length(axlesTandem10Weights),termination);    %%put here the sum of all rut depths
    % auxMaxRutPosition            = zeros(length(axlesTandem10Weights));  %%get the r position of the maximum rut depth for all weights  <<NO LONGER NEEDED
    
    auxrutDepthHMATandem14        = zeros(ACLayersNumber,nrTa14,length(axlesTandem14Weights),termination);
    auxrutDepthGranTandem14       = zeros(length(paveDepths)-1-ACLayersNumber,nrTa14,length(axlesTandem14Weights),termination);
    auxrutDepthSubGradeTandem14   = zeros(1,nrTa14,length(axlesTandem14Weights),termination);
    auxMaxRutTandem14             = zeros(nrTa14,length(axlesTandem14Weights),termination);    %%put here the sum of all rut depths
    
    auxrutDepthHMATandem18        = zeros(ACLayersNumber,nrTa18,length(axlesTandemWeights),termination);
    auxrutDepthGranTandem18       = zeros(length(paveDepths)-1-ACLayersNumber,nrTa18,length(axlesTandemWeights),termination);
    auxrutDepthSubGradeTandem18   = zeros(1,nrTa18,length(axlesTandemWeights),termination);
    auxMaxRutTandem18             = zeros(nrTa18,length(axlesTandemWeights),termination);    %%put here the sum of all rut depths
    % auxMaxRutPosition            = zeros(length(axlesTandemWeights));       %%get the r position of the maximum rut depth for all weights
    
    auxrutDepthHMATridem        = zeros(ACLayersNumber,nrTr,length(axlesTridemWeights),termination);
    auxrutDepthGranTridem       = zeros(length(paveDepths)-1-ACLayersNumber,nrTr,length(axlesTridemWeights),termination);
    auxrutDepthSubGradeTridem   = zeros(1,nrTr,length(axlesTridemWeights),termination);
    auxMaxRutTridem             = zeros(nrTr,length(axlesTridemWeights),termination);    %%put here the sum of all rut depths
    % auxMaxRutPosition            = zeros(length(axlesTridemWeights));       %%get the r position of the maximum rut depth for all weights

end

%% light weight single axle
%%NOTE: nrsL and all the nr**; z; epsZ*** have been defined in the MLE_frontEnd
%a) compute rutting for each type of axle.

maxRutDepthHMASingleL        = zeros(ACLayersNumber,1,length(axlesSingleLWeights));
maxRutDepthGranSingleL       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesSingleLWeights));
maxRutDepthSubGradeSingleL   = zeros(1,1,length(axlesSingleLWeights));

for j = 1:length(axlesSingleLWeights)
    for r = 1:nrsL   %%<< update v2019-05-14:: Compute all positions, but pass POSITION r = 1 ONLY  as maxRutDepth (under the wheel)
        %%update V2019-03-17:: pass on previous-iteration to rutDepthCompute (strain hardening approach)
        eplHMAprev = eplCacheSingleL(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheSingleL(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheSingleL(end,r,j,k);
        %%update V2019-05-14: Add 4th-dimension to call to rutDepthCompute
        %%and to eplCacheXXX
        [auxrutDepthHMASingleL(:,r,j,k),auxrutDepthGranSingleL(:,r,j,k),auxrutDepthSubGradeSingleL(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZsingleL(:,r,j,k),axlesSingleLight(k,j),z,paveDepths,shortAsphLyrTemp(k,2:ACLayersNumber+1),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
        eplCacheSingleL(:,r,j,k+1) = [eplHMA;eplGran;eplSG];
        
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutSingleL(r,j,k) = sum(auxrutDepthHMASingleL(:,r,j,k))+sum(auxrutDepthGranSingleL(:,r,j,k))+sum(auxrutDepthSubGradeSingleL(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end   
   %get the position where the maximum rutting occurs for each weight level
   %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==1 %case as maxRutDepth (under the wheel)
%    aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%    if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end       
    maxRutDepthHMASingleL(:,1,j)        = auxrutDepthHMASingleL(:,1,j,k);
%    maxRutDepthHMASingleL(:,1,j)        = auxrutDepthHMASingleL(:,auxMaxRutPosition(j),j);
   maxRutDepthGranSingleL(:,1,j)       = auxrutDepthGranSingleL(:,1,j,k);
   maxRutDepthSubGradeSingleL(:,1,j)   = auxrutDepthSubGradeSingleL(:,1,j,k);
end

%% single-wheel single axle

maxRutDepthHMASingle6        = zeros(ACLayersNumber,1,length(axlesSingle6Weights));
maxRutDepthGranSingle6       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesSingle6Weights));
maxRutDepthSubGradeSingle6   = zeros(1,1,length(axlesSingle6Weights));

for j = 1:length(axlesSingle6Weights)
    for r = 1:nrs6  %<< update v2019-05-14:: Compute all positions, but pass POSITION r = 1 ONLY  as maxRutDepth (under the wheel)
        %%updateV2019-03-17:: pass on previous-iteration
        eplHMAprev = eplCacheSingle6(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheSingle6(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheSingle6(end,r,j,k);        
        [auxrutDepthHMASingle6(:,r,j,k),auxrutDepthGranSingle6(:,r,j,k),auxrutDepthSubGradeSingle6(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZsingle6(:,r,j,k),axlesSingle6(k,j),z,paveDepths,shortAsphLyrTemp(k,2:end),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
        eplCacheSingle6(:,r,j,k+1) = [eplHMA;eplGran;eplSG];
        
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutSingle6(r,j,k) = sum(auxrutDepthHMASingle6(:,r,j,k))+sum(auxrutDepthGranSingle6(:,r,j,k))+sum(auxrutDepthSubGradeSingle6(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end
    %get the position where the maximum rutting occurs for each weight level
    %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==1 %case as maxRutDepth (under the wheel)
%     aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%     if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end      
%    maxRutDepthHMASingle6(:,1,j)        = auxrutDepthHMASingle6(:,auxMaxRutPosition(j),j);
   maxRutDepthHMASingle6(:,1,j)        = auxrutDepthHMASingle6(:,1,j,k);
   maxRutDepthGranSingle6(:,1,j)       = auxrutDepthGranSingle6(:,1,j,k);
   maxRutDepthSubGradeSingle6(:,1,j)   = auxrutDepthSubGradeSingle6(:,1,j,k);
end

%% dual-wheel single axle

maxRutDepthHMASingle10        = zeros(ACLayersNumber,1,length(axlesSingle10Weights));
maxRutDepthGranSingle10       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesSingle10Weights));
maxRutDepthSubGradeSingle10   = zeros(1,1,length(axlesSingle10Weights));

for j = 1:length(axlesSingle10Weights)
    for r = 1:nrs10     %%<< update v2019-05-14:: Compute all positions, but pass POSITION r = 4 ONLY   (under the wheel)
        %%updateV2019-03-17:: pass on previous-iteration
        eplHMAprev = eplCacheSingle10(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheSingle10(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheSingle10(end,r,j,k);   
        [auxrutDepthHMASingle10(:,r,j,k),auxrutDepthGranSingle10(:,r,j,k),auxrutDepthSubGradeSingle10(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZsingle10(:,r,j,k),axlesSingle105(k,j),z,paveDepths,shortAsphLyrTemp(k,2:end),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
         eplCacheSingle10(:,r,j,k+1) = [eplHMA;eplGran;eplSG];
         
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutSingle10(r,j,k) = sum(auxrutDepthHMASingle10(:,r,j,k))+sum(auxrutDepthGranSingle10(:,r,j,k))+sum(auxrutDepthSubGradeSingle10(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end
     %get the position where the maximum rutting occurs for each weight level
    %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==4 %case as maxRutDepth (under the wheel)
%     aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%     if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end      
%    maxRutDepthHMASingle10(:,1,j)        = auxrutDepthHMASingle10(:,auxMaxRutPosition(j),j);
   maxRutDepthHMASingle10(:,1,j)        = auxrutDepthHMASingle10(:,4,j,k);
   maxRutDepthGranSingle10(:,1,j)       = auxrutDepthGranSingle10(:,4,j,k);
   maxRutDepthSubGradeSingle10(:,1,j)   = auxrutDepthSubGradeSingle10(:,4,j,k);
end

%% single-wheel tandem axle

maxRutDepthHMATandem10        = zeros(ACLayersNumber,1,length(axlesTandem10Weights));
maxRutDepthGranTandem10       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesTandem10Weights));
maxRutDepthSubGradeTandem10   = zeros(1,1,length(axlesTandem10Weights));

for j = 1:length(axlesTandem10Weights)
    for r = 1:nrTa10    %%update v2019-05-12::  USE POSITION r = 4 ONLY   (under the wheel)
        %%updateV2019-03-17:: pass on previous-iteration
        eplHMAprev = eplCacheTandem10(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheTandem10(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheTandem10(end,r,j,k);
        [auxrutDepthHMATandem10(:,r,j,k),auxrutDepthGranTandem10(:,r,j,k),auxrutDepthSubGradeTandem10(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZtandem10(:,r,j,k),axlesTandem10(k,j),z,paveDepths,shortAsphLyrTemp(k,2:end),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
         eplCacheTandem10(:,r,j,k+1) = [eplHMA;eplGran;eplSG]; 
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutTandem10(r,j,k) = sum(auxrutDepthHMATandem10(:,r,j,k))+sum(auxrutDepthGranTandem10(:,r,j,k))+sum(auxrutDepthSubGradeTandem10(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end
    %get the position where the maximum rutting occurs for each weight level
   %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==4 %case as maxRutDepth (under the wheel)
%     aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%     if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end      
%    maxRutDepthHMATandem10(:,1,j)        = auxrutDepthHMATandem10(:,auxMaxRutPosition(j),j);
   maxRutDepthHMATandem10(:,1,j)        = auxrutDepthHMATandem10(:,4,j,k);
   maxRutDepthGranTandem10(:,1,j)       = auxrutDepthGranTandem10(:,4,j,k);
   maxRutDepthSubGradeTandem10(:,1,j)   = auxrutDepthSubGradeTandem10(:,4,j,k);
end

%% non-homogeneous tandem axle

maxRutDepthHMATandem14        = zeros(ACLayersNumber,1,length(axlesTandem14Weights));
maxRutDepthGranTandem14       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesTandem14Weights));
maxRutDepthSubGradeTandem14   = zeros(1,1,length(axlesTandem14Weights));

for j = 1:length(axlesTandem14Weights)
    for r = 1:nrTa14  
        eplHMAprev = eplCacheTandem14(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheTandem14(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheTandem14(end,r,j,k);
        [auxrutDepthHMATandem14(:,r,j,k),auxrutDepthGranTandem14(:,r,j,k),auxrutDepthSubGradeTandem14(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZtandem14(:,r,j,k),axlesTandem14(k,j),z,paveDepths,shortAsphLyrTemp(k,2:end),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
        eplCacheTandem14(:,r,j,k+1) = [eplHMA;eplGran;eplSG]; 
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutTandem14(r,j,k) = sum(auxrutDepthHMATandem14(:,r,j,k))+sum(auxrutDepthGranTandem14(:,r,j,k))+sum(auxrutDepthSubGradeTandem14(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end
    %get the position where the maximum rutting occurs for each weight level
    %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==1 %case as maxRutDepth (under the wheel)
%     aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%     if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end        
%    maxRutDepthHMATandem14(:,1,j)        = auxrutDepthHMATandem14(:,auxMaxRutPosition(j),j);
   maxRutDepthHMATandem14(:,1,j)        = auxrutDepthHMATandem14(:,1,j,k);
   maxRutDepthGranTandem14(:,1,j)       = auxrutDepthGranTandem14(:,1,j,k);
   maxRutDepthSubGradeTandem14(:,1,j)   = auxrutDepthSubGradeTandem14(:,1,j,k);
end

%% dual wheel tandem axle

maxRutDepthHMATandem18        = zeros(ACLayersNumber,1,length(axlesTandemWeights));
maxRutDepthGranTandem18       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesTandemWeights));
maxRutDepthSubGradeTandem18   = zeros(1,1,length(axlesTandemWeights));

for j = 1:length(axlesTandemWeights)
    for r = 1:nrTa18
        eplHMAprev = eplCacheTandem18(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheTandem18(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheTandem18(end,r,j,k);
        [auxrutDepthHMATandem18(:,r,j,k),auxrutDepthGranTandem18(:,r,j,k),auxrutDepthSubGradeTandem18(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZtandem18(:,r,j,k),axlesTandem18(k,j),z,paveDepths,shortAsphLyrTemp(k,2:end),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
        eplCacheTandem18(:,r,j,k+1) = [eplHMA;eplGran;eplSG]; 
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutTandem18(r,j,k) = sum(auxrutDepthHMATandem18(:,r,j,k))+sum(auxrutDepthGranTandem18(:,r,j,k))+sum(auxrutDepthSubGradeTandem18(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end
    %get the position where the maximum rutting occurs for each weight level
    %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==10 %case as maxRutDepth (under a wheel)
%     aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%     if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end      
%    maxRutDepthHMATandem18(:,1,j)        = auxrutDepthHMATandem18(:,auxMaxRutPosition(j),j);
   maxRutDepthHMATandem18(:,1,j)        = auxrutDepthHMATandem18(:,10,j,k);
   maxRutDepthGranTandem18(:,1,j)       = auxrutDepthGranTandem18(:,10,j,k);
   maxRutDepthSubGradeTandem18(:,1,j)   = auxrutDepthSubGradeTandem18(:,10,j,k);
end

%% tridem axle

maxRutDepthHMATridem        = zeros(ACLayersNumber,1,length(axlesTridemWeights));
maxRutDepthGranTridem       = zeros(length(paveDepths)-1-ACLayersNumber,1,length(axlesTridemWeights));
maxRutDepthSubGradeTridem   = zeros(1,1,length(axlesTridemWeights));

for j = 1:length(axlesTridemWeights)
    for r=1:nrTr    %
        eplHMAprev = eplCacheTridem(1:ACLayersNumber,r,j,k);
        eplGranprev= eplCacheTridem(ACLayersNumber+1:end-1,r,j,k);
        eplSGprev  = eplCacheTridem(end,r,j,k);
        [auxrutDepthHMATridem(:,r,j,k),auxrutDepthGranTridem(:,r,j,k),auxrutDepthSubGradeTridem(:,r,j,k),eplHMA,eplGran,eplSG] = rutDepthCompute(epsZtridem(:,r,j,k),axlesTridem(k,j),z,paveDepths,shortAsphLyrTemp(k,2:end),layersMoisture(k,:),granDens,eplHMAprev,eplGranprev,eplSGprev);
        eplCacheTridem(:,r,j,k+1) = [eplHMA;eplGran;eplSG]; 
        %apply simplification 2019-02-20: locate point where overall maximum rutting occurs (sum all stacks)
        auxMaxRutTridem(r,j,k) = sum(auxrutDepthHMATridem(:,r,j,k))+sum(auxrutDepthGranTridem(:,r,j,k))+sum(auxrutDepthSubGradeTridem(:,r,j,k));  %Get the total rut depth at each radial location and each load level
    end
   %get the position where the maximum rutting occurs for each weight level
   %%UPDATE V2019-05-14: store all auxMatRutPosition, but save the r==4 %case as maxRutDepth (under a wheel)
%     aux =  find(auxMaxRut(:,j)==max(auxMaxRut(:,j)));
%     if ~isempty(aux)
%        auxMaxRutPosition(j) = aux(1);
%    else
%        auxMaxRutPosition(j) = 1;
%    end   
%    maxRutDepthHMATridem(:,1,j)        = auxrutDepthHMATridem(:,auxMaxRutPosition(j),j);
   maxRutDepthHMATridem(:,1,j)        = auxrutDepthHMATridem(:,4,j,k);
   maxRutDepthGranTridem(:,1,j)       = auxrutDepthGranTridem(:,4,j,k);
   maxRutDepthSubGradeTridem(:,1,j)   = auxrutDepthSubGradeTridem(:,4,j,k);
end

%% sum them all together!
%%sum over the " stack dimension" (I'll get small vectors with the sum of
%%all rut depths for all the load levels, each the size of the HMA, gran, and subgrade).
%Then I must transpose them to row vector and stack together in row kth of rutDepth
rutDepth(k,1:end-1) = [(sum(maxRutDepthHMASingleL,3))' (sum(maxRutDepthGranSingleL,3))' (sum(maxRutDepthSubGradeSingleL,3))'] + ...
     [(sum(maxRutDepthHMASingle6,3))' (sum(maxRutDepthGranSingle6,3))' (sum(maxRutDepthSubGradeSingle6,3))'] + ...
     [(sum(maxRutDepthHMASingle10,3))' (sum(maxRutDepthGranSingle10,3))' (sum(maxRutDepthSubGradeSingle10,3))'] + ... 
     [(sum(maxRutDepthHMATandem10,3))' (sum(maxRutDepthGranTandem10,3))' (sum(maxRutDepthSubGradeTandem10,3))'] + ...
     [(sum(maxRutDepthHMATandem14,3))' (sum(maxRutDepthGranTandem14,3))' (sum(maxRutDepthSubGradeTandem14,3))'] + ...
     [(sum(maxRutDepthHMATandem18,3))' (sum(maxRutDepthGranTandem18,3))' (sum(maxRutDepthSubGradeTandem18,3))'] + ...
     [(sum(maxRutDepthHMATridem,3))' (sum(maxRutDepthGranTridem,3))' (sum(maxRutDepthSubGradeTridem,3))'];

 %get the total depth of rutting
rutDepth(k,end) = sum(rutDepth(k,1:end-1),2);   %sum over the second dimension of rutDepth (sum by rows.)