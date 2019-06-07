function [alligatorNi,alligatorDamage] = topDownCracking(MLEstrain, axlePasses,z,HMAlayerDepth,EDyn,HMAProperties)
%function  [topDownNi,topDownDamage] = topDownCracking(MLEstrain, axlePasses,z,layerDepth,EDyn,HMAProperties)
%
%compute the degree of TOP-DOWN cracking  damage on each HMA layer for a given axle type
%(compute at all depths of interest (bottoms of the HMA layers), for all the weight ranges) for a given shortTimestamp(k)
%%
%Use MEPDG's original equations(eqns. 3.3.29/30 and so on). See Pt3 Chapter 3 of NCHRP 2004.
%
%Inputs
% MLEstrain,   MAx horizontal strain matrix at each (z,r) location -as computed by the MLE
% axlePasses,  number of axle passes in the period of interest
% z            vector of depths tied to MLEStrain     [m]
% HMAlayerDepth   vector stating the thickness of the HMA layers [cm]
% EDyn         dynamic modulus [in PSI] for the HMA layers for the given axle type and load value (compatible with MLEStrain) AT A SINGLE TIMESTAMP (t(k)).
% HMAPropertiesVector with the Mix properties for the HMA layers as imported from the dataImport sheet. Need Air voids and bitumen content in perc. volume
% 
%Outputs
% topDownNi     [size numHMALayers x numLoadLevels]: number of admissible passes for HMA layer (i) and load level (j)
% topDownDamage [size numHMALayers x 1]: degree of damage done by all the passes of the axle type of the given type (sum of all weights).
%
%%Assumption: for a given weight range, the radial position that will be summed to the admissible number of passes (and so to the topDownDamage value) is  
%that with the least admissible number of passes (Nf) on all the HMA layers.
%
%THIS IS THE "UNCALLIBRATED" VERSION OF THE RUTTING MODEL, THE EQUATIONS
%WERE PROGRAMMED HEREIN AS THEY HAVE BEEN REPORTED IN THE MEPDG GUIDE.
%THE CALLIBRATION EFFORT MAY EVENTUALLY LEAD TO RE-WRITING THIS COMPUTER CODE!
%
%V0.4 - 2019-05-20
%   Changelog: CORRECTED  EQUATION FOR K1 PARAMETER FOR TOP-DOWN CRACKING.
%   MEPDG'S P3C3 (2004) HAS WRONG EQUATION, CORRECT ONE IS MEPDG'S APPENDIX II, EQN. 27
%V0.3 - 2019-05-19:
%   Changelog: Compute top-dn cracking at surface level only.
%   Modify computations to only regard top-most layer
%V0.2 - 2019-04-04:
%   Changelog: corrected error in k1 computation (it was summing
%   HMALayerDepth twice!)
%v0.1 - 2019-04-03:
%   Changelog: Corrected M parameter equation, Vb and Va were reverted!
%   Force the Eps_H term in the N_admissible equation to use the absoulte
%   value of the horizontal strain (cause if Eps_H is negative it goes to the Cmplx plane)
%V0.0 - 2019-02-22

%% code begins

%%update V2019-05-19: Properties for Layer 1 only
airVoids = HMAProperties(1,2);  %retrieve air voids vol.. from import.
bitCont  = HMAProperties(1,3);  %retrieve bitumen content from import.
M        = 4.84.*(bitCont./(airVoids+bitCont) - 0.69);     %parameter to equation 3.3.29

%do some needed calculations 
HMAlayerDepth = HMAlayerDepth*.01;   %%convert from cm to meters to compare with Z
HMAlayerDepth = cumsum(HMAlayerDepth); %and convert thickness to depth.
%UPDATE V2019-05-20: k1 equation corrected WITH MEPDG'S APPENDIX II EQN 27.
%%K1 EQN. patched v2019-04-04. Since HMAlayerDepth is cumsummed above, the last entry is the total HMA layer depth!
k1            = 0.0001 + 29.844*(1+exp(30.544-5.7357*(HMAlayerDepth(end))/0.0254))^(-1);  
k1            = 1/k1;             %parameter k1 FOR TOP-DN CRACKING. AS PER EQUATION 27 in mepdg's appendix II (the one in P3.c3 of the MEPDG is WRONG!).
%NOTE: k1 is a scalar (or should be...)

%Locate the MLE strain rows that correspond to the base of the HMA layers.
% strainHMA = MLEstrain(z==HMAlayerDepth,:,:);   %get the strain values where z is the base of the HMA layers, all r positions and all levels of load!
auxPosZ = zeros(length(HMAlayerDepth),1);
for i = 1:length(HMAlayerDepth)
    aux = find(abs(z-HMAlayerDepth(i))<0.001);
    if ~isempty(aux)
        auxPosZ(i)  = aux;
    end
end

%%updateV2019-05-19: Remove all calculations an do the math for z = first
%%location (surface of pavement)

strainHMA = MLEstrain(1,:,:);   %<<UPDATED get the strain values at the pavement surface, all r positions and all levels of load!

[numHMALayers,radioPositions,numLoadLevels] = size(strainHMA);

%% get the admissible number of passes (NF(z,r,load)) for each z and radial position and each load level. [z = each HMA layer]

NF = zeros(size(strainHMA));    %size is HMA LAYERS X RADIAL POSITIONS X LOAD LEVEL
%alligatorNi = zeros(numHMALayers,numLoadLevels);  <<update v2019-05-19
alligatorNi = zeros(1,numLoadLevels);  

%solve for each load level (size of the axlePasses vector) AND radial position (size of retrieved from the strainHMA 3-D array)
%patched v2019-04-04. Exponent to strainHMA badly written!
%update v2019-05-19:  Use Edyn(1,x) to represent the top-most layer only
for i = 1:numLoadLevels
    for j = 1:radioPositions
        NF(:,j,i) = (0.00432*k1).*10.^M .*(abs(strainHMA(:,j,i))).^(-3.9492).*EDyn(1,i).^(-1.281);
    end
    %%now, for each load level, get a single set of NF -> alligatorNi
    %get the radial position that brings the smallest NF, 
    minNF = min(NF(:,:,i));
    [~,minCol,~] = ind2sub(size(NF(:,:,i)),find(NF(:,:,i) == minNF));   %this function call gives the coordinates x,y (row/col/stack??) for the position in NF(:,:,i) where the minNF is located
    
    %and pass that column for all stacks to alligatorNi below.
    %just in case, put the first entry of the minNF case there are many
    %occasions.
    alligatorNi(:,i) = NF(:,minCol(1),i);   
end

%% compute the degree of damage done by these axles

alligatorRatios = zeros(numHMALayers,numLoadLevels);  %compute these separately for each HMA layer
alligatorDamage = zeros(numHMALayers,1);

for i = 1:numHMALayers
    alligatorRatios(i,:) = axlePasses./alligatorNi(i,:);
    alligatorDamage(i) = sum(alligatorRatios(i,:));
end

end