%% PRODUCT-ONE PAVEMENT DESIGN TOOL
%FRONT END CODE FOR THE DISTRESS CALCULATIONS
%
%This script will direct the calls to auxiliary functions to compute the
%intended distresses over the pavement structure for each time moment, each
%level of load and each axle type
% 
%%THESE ARE THE VARIABLES THAT ARE TO BE FILLED. 
%EACH CALL TO THIS SCRIPT WILL FILL UP ROW (k) OF THESE MATRICES/VECTORS.
%
% alligatorCrack = zeros(termination,length(HMAPaveDepth));   % units: percentage of lane area     
% topDownCrack = zeros(termination,legnth(HMAPaveDepth));     % units: m/km  [MEPDG's are ft/mile]
% BOTH ARE COMPUTED WITH THE MEPDG'S RE-FIT OF THE ASPHALT INSTITUTE
% EQUATIONS (DEFAULT CALLIBRATION PARAMETERS)
%
%V0.3 2019-09-17 -  The 30th
%   Changelog: diabled top-down cracking calculations to allow for further
%   investigation in proper top-dn crack modeling.%
%V0.2 2019-05-20
%   Changelog: topDownDamage variables to have only 1 column
%   (representative of distress calculation at the surface only)
%V0.1 2019-05-14
%   Changelog: adapted input to the alligatorCracking and TopDownCracking
%   compute functions to comply with the 4-dimensional arrays for strains
%   and stresses.

%% PART 0 - INITIALIZE THE DAMAGE VECTORS (AT TIMESTAMP 1), WHICH WILL BE USED TO COMPUTE DAMAGE
if k ==1
    %these are the damage ratios for the axle passes at timestamp K
    bottomUpDamageSingleL  = zeros(termination,ACLayersNumber);
    bottomUpDamageSingle6  = zeros(termination,ACLayersNumber);
    bottomUpDamageSingle10 = zeros(termination,ACLayersNumber);
    bottomUpDamageTandem10 = zeros(termination,ACLayersNumber);
    bottomUpDamageTandem14 = zeros(termination,ACLayersNumber);
    bottomUpDamageTandem18 = zeros(termination,ACLayersNumber);
    bottomUpDamageTridem   = zeros(termination,ACLayersNumber);    
    
%     topDownDamageSingleL  = zeros(termination,1);
%     topDownDamageSingle6  = zeros(termination,1);
%     topDownDamageSingle10 = zeros(termination,1);
%     topDownDamageTandem10 = zeros(termination,1);
%     topDownDamageTandem14 = zeros(termination,1);
%     topDownDamageTandem18 = zeros(termination,1);
%     topDownDamageTridem   = zeros(termination,1);       
end


%% PART 1 - - - BOTTOM UP ALLIGATOR CRACKING
%% compute the degree of damage for each axle type (sum of all load levels)
%%%PASS TO FUNCTION "alligatorCracking" for every axle type
%size of auxDamageBUSingleL: [HMA Layers  x 1] - its the terms of the Miner's law for all axle load levels
%%update V2019-05-14: Correct epsHXXX from 4-D to 3-D array for a correct call to alligatorCracking) 

[aaa,bbb,ccc,~] = size(epsHsingleL);
epsHSingleLk = reshape(epsHsingleL(:,:,:,k),[aaa,bbb,ccc]);
[aaa,bbb,ccc,~] = size(epsHsingle6);
epsHSingle6k = reshape(epsHsingle6(:,:,:,k),[aaa,bbb,ccc]);
[aaa,bbb,ccc,~] = size(epsHsingle10);
epsHSingle10k = reshape(epsHsingle10(:,:,:,k),[aaa,bbb,ccc]);
[aaa,bbb,ccc,~] = size(epsHtandem10);
epsHTandem10k = reshape(epsHtandem10(:,:,:,k),[aaa,bbb,ccc]);
[aaa,bbb,ccc,~] = size(epsHtandem14);
epsHTandem14k = reshape(epsHtandem14(:,:,:,k),[aaa,bbb,ccc]);
[aaa,bbb,ccc,~] = size(epsHtandem18);
epsHTandem18k = reshape(epsHtandem18(:,:,:,k),[aaa,bbb,ccc]);
[aaa,bbb,ccc,~] = size(epsHtridem);
epsHTridemk = reshape(epsHtridem(:,:,:,k),[aaa,bbb,ccc]);


[~, auxDamage] = alligatorCracking(epsHSingleLk, axlesSingleLight(k,:),z,ACPaveDepth(:),EDynSingleLight(:,:,k),HMAparameters);
bottomUpDamageSingleL(k,:) = auxDamage';
[~, auxDamage] = alligatorCracking(epsHSingle6k, axlesSingle6(k,:),z,ACPaveDepth(:),EDynSingle6(:,:,k),HMAparameters);
bottomUpDamageSingle6(k,:) = auxDamage';
[~, auxDamage] = alligatorCracking(epsHSingle10k, axlesSingle105(k,:),z,ACPaveDepth(:),EDynSingle105(:,:,k),HMAparameters);
bottomUpDamageSingle10(k,:) = auxDamage';
[~, auxDamage] = alligatorCracking(epsHTandem10k, axlesTandem10(k,:),z,ACPaveDepth(:),EDynTandem10(:,:,k),HMAparameters);
bottomUpDamageTandem10(k,:) = auxDamage';
[~, auxDamage] = alligatorCracking(epsHTandem14k, axlesTandem14(k,:),z,ACPaveDepth(:),EDynTandem14(:,:,k),HMAparameters);
bottomUpDamageTandem14(k,:) = auxDamage';
[~, auxDamage] = alligatorCracking(epsHTandem18k, axlesTandem18(k,:),z,ACPaveDepth(:),EDynTandem18(:,:,k),HMAparameters);
bottomUpDamageTandem18(k,:) = auxDamage';
[~, auxDamage] = alligatorCracking(epsHTridemk, axlesTridem(k,:),z,ACPaveDepth(:),EDynTridem(:,:,k),HMAparameters);
bottomUpDamageTridem(k,:) = auxDamage';

%% compute the degree of alligator cracking for all layers at timestamp K
% alligatorCrack = zeros(termination,ACLayersNumber);   % units: percentage of lane area // k is from 0--termination, following the shortTimestamp    %%DEFINED IN THE MAINCODE

c2p = -2.40874-39.748*(1+ACtotalDepth/2.54)^-2.85609;   %ACtotalDepth is in centimeters!
c1p = -1*c2p;
cummDamage = zeros(1,ACLayersNumber);
for i = 1:ACLayersNumber
    cummDamage(i) = sum(bottomUpDamageSingleL(1:k,i)) + sum(bottomUpDamageSingle6(1:k,i)) + sum(bottomUpDamageSingle10(1:k,i)) + ...
        sum(bottomUpDamageTandem10(1:k,i)) + sum(bottomUpDamageTandem14(1:k,i)) + sum(bottomUpDamageTandem18(1:k,i)) + sum(bottomUpDamageTridem(1:k,i));
    alligatorCrack(k,i) = (6000/60).*(1+exp(c1p + c2p.*log10(100*cummDamage(i)))).^-1;
end

%% PART 2 - - - TOP DOWN ALLIGATOR CRACKING
%% compute the degree of damage for each axle type
%%%PASS TO FUNCTION "topDownCracking" for every axle type
% [~, auxDamage] = topDownCracking(epsHSingleLk, axlesSingleLight(k,:),z,ACPaveDepth(:),EDynSingleLight(:,:,k),HMAparameters);
% topDownDamageSingleL(k,:) = auxDamage';
% [~, auxDamage] = topDownCracking(epsHSingle6k, axlesSingle6(k,:),z,ACPaveDepth(:),EDynSingle6(:,:,k),HMAparameters);
% topDownDamageSingle6(k,:) = auxDamage';
% [~, auxDamage] = topDownCracking(epsHSingle10k, axlesSingle105(k,:),z,ACPaveDepth(:),EDynSingle105(:,:,k),HMAparameters);
% topDownDamageSingle10(k,:) = auxDamage';
% [~, auxDamage] = topDownCracking(epsHTandem10k, axlesTandem10(k,:),z,ACPaveDepth(:),EDynTandem10(:,:,k),HMAparameters);
% topDownDamageTandem10(k,:) = auxDamage';
% [~, auxDamage] = topDownCracking(epsHTandem14k, axlesTandem14(k,:),z,ACPaveDepth(:),EDynTandem14(:,:,k),HMAparameters);
% topDownDamageTandem14(k,:) = auxDamage';
% [~, auxDamage] = topDownCracking(epsHTandem18k, axlesTandem18(k,:),z,ACPaveDepth(:),EDynTandem18(:,:,k),HMAparameters);
% topDownDamageTandem18(k,:) = auxDamage';
% [~, auxDamage] = topDownCracking(epsHTridemk, axlesTridem(k,:),z,ACPaveDepth(:),EDynTridem(:,:,k),HMAparameters);
% topDownDamageTridem(k,:) = auxDamage';

%% compute the degree of top down cracking for all layers at timestamp K
% topDownCrack = zeros(termination,ACLayersNumber);     % units: m/km
% [MEPDG's are ft/mile]. 1 m/km = 1.61/0.305 ft/mi
% 
% cummDamage = zeros(1,1);
%     cummDamage = sum(topDownDamageSingleL(1:k,1)) + sum(topDownDamageSingle6(1:k,1)) + sum(topDownDamageSingle10(1:k,1)) + ...
%         sum(topDownDamageTandem10(1:k,1)) + sum(topDownDamageTandem14(1:k,1)) + sum(topDownDamageTandem18(1:k,1)) + sum(topDownDamageTridem(1:k,1));
%     topDownCrack(k,1) = 10.56*1000.*(1+exp(7.0 - 3.5.*log10(100*cummDamage))).^-1;
%     topDownCrack(k,1) = 0.305/1.61.*topDownCrack(k,1);    %%convert ft/mi --> m/km

