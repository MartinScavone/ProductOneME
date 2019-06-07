%%%%  PRODUCT-ONE - M.E. Pavement Design tool - %%%%
%%% FRONT-END SCRIPT for the MULTI-LYR LINEAR ELASTIC ANALYSIS TOOL%%%
%
%%V 0.8 2019-05-20
    %Changelog: Rolled back some angle corrections (was pointing to pi rad - actual angle
    %
%%V 0.7 2019-05-14:
    %Changelog: now storing the stress and strain values for all axle types
    %all variables have now a time-dimension  (are R4 matrices)
%%V 0.6 2019-05-09:
    %changelog: corrected bug in calculation of horizontal max strain
    %(epsH), the term with the gammaXY is not a subtraction but a sum!.
    %This was bringing cases to the cmplx world!
%%V 0.5 2019-03-31:
    %Changelog: Corrected call to MLE_sigma: the dependency requires the
    %load pressure instead of the load's total value.
    %Corrected MLE_sigma (see file for description of fixes).
%%V 0.4 2019-03-20: 
    %changelog: corrected the 2019-02-19 update (it won't do the MLE
    %calculations for axle categories that don't have traffic). I expect to save computation time with this move.
%%V 0.3 2019-03-19
    %Changelog: Removed error in assigning load by wheel in multi-wheel axles
    %Removed r=0 cases and replaced with r=0.01m (when r=0, sigmaR and sigmaT diverge to infinity)
    %added epsX epsY epsZ epsH calculations for the SingleL and single6 axles
%%V 0.2 2019-03-12
    %Changelog: major debugging, correctred rdii and angle for most axles (cm to m conversion, erroneous angle values)
%%V 0.1 2019-02-05
%
%%THIS SCRIPT IS MEANT TO RUN IN THE MAIN-CODE WORKSPACE. ALL VARIABLES
%%USED HEREIN SHOULD BE DEFINED PREVIOUSLY IN THE MAIN CODE OR ANOTHER SCRIPT
%%EACH INSTANCE OF THIS SCRIPT OCCURS AT "timeStamp = k"
%
%Goal: calculate radial, tangential, and vertical stresses in the pavement
%structure --> with which compute the strains... which are to pass on to
%the distress calculator.

%Will stack stress(r, T, Z) for every axle type on a 3-D array, size
%(Z-domain; R-domain; weight range)

%% code begins
%%Some previous variables I need to fix
tandemAxleSep = 1.20;    %minimum legal axle separation for tandems and tridems
dualWheelSep  = 0.68;    %truck-size dual-wheel separation (from Merc.B. commercial brochure)

%% - get the domain variables for all cases: z
z = getZfromPaveDepth(paveDepths);    %%auxiliary vector to calculate the z positions from the actual pave depths in compliance with MEPDG - program separately! OUTPUT IT GIVEN IN meters!


%% Initialize stress and strain variables
nrsL  = 4;                             %4 radial positions will be analyzed for light and 6-t single axles (all under the axle axis of symmetry).
nrs6  = 4;                             %4 radial positions will be analyzed for single-wheel heavy single axles (all under the axle axis of symmetry).
nrs10 = 6;                             %6 radial positions will be analyzed for dual-wheel heavy single axles (all under the axle axis of symmetry). 
nrTa10= 6;                             %8 radial positions will be analyzed for 4-wheel tandem axles (all under the axle-group axis of symmetry).
nrTa14=15;                             %15 radial positions will be analyzed for 6-wheel tandem axles (asymmetric arrangement).
nrTa18=12;                             %12 radial positions will be analyzed for 8-wheel tandem axles (symmetric arrangement).
nrTr  =18;                             %18 radial positions will be analyzed for tridem axles.
if k ==1
    %%UPDATE V2019-05-14: INITIALIZE ALL STRESS AND STRAIN CALC. AT K ==1
    %%for singleLight
    sigmaZsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);
    % sigmaRsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights));   %%NOT WORTH KEEPING! THE MULTI-WHEEL AXLES WILL HAVE NON-ADDITIVE sigmaT and sigmaR; STORE sigmaX and sigmaY only!
    % sigmaTsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights));
    sigmaXsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);
    sigmaYsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);
    tauXYsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);

    epsXsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);
    epsYsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);
    gmXYsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);
    epsHsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);        %%only one worth computing, this is the "greatest [or smallest since it's being negative because it's tension]" horizontal tension - the one used in fatigue cracking model [After Huang 04 eq. 3.4]
    epsZsingleL = zeros(length(z),nrsL,length(axlesSingleLWeights),termination);        %% needed for vertical deflection  

    %%for single 6 ton
    sigmaZsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    % sigmaRsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights));
    sigmaTsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    sigmaXsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    sigmaYsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    tauXYsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);

    epsXsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    epsYsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    gmXYsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    epsHsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);
    epsZsingle6 = zeros(length(z),nrs6,length(axlesSingle6Weights),termination);

    %%for single 10 ton
    sigmaZsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    % sigmaRsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights));
    % sigmaTsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights));
    sigmaXsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    sigmaYsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    tauXYsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);

    epsXsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    epsYsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    gmXYsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    epsHsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);
    epsZsingle10 = zeros(length(z),nrs10,length(axlesSingle10Weights),termination);

    %%%%%%%%%%%%%%%%%%
    %%for tandem 10 ton
    sigmaZtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    sigmaXtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    sigmaYtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    tauXYtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);

    epsXtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    epsYtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    gmXYtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    epsHtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);
    epsZtandem10 = zeros(length(z),nrTa10,length(axlesTandem10Weights),termination);

    %%for tandem 14 ton
    sigmaZtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    sigmaXtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    sigmaYtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    tauXYtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);

    epsXtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    epsYtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    gmXYtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    epsHtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);
    epsZtandem14 = zeros(length(z),nrTa14,length(axlesTandem14Weights),termination);

    %%for tandem 18 ton
    sigmaXtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    sigmaYtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    sigmaZtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    tauXYtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);

    epsXtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    epsYtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    gmXYtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    epsHtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);
    epsZtandem18 = zeros(length(z),nrTa18,length(axlesTandemWeights),termination);

    %%%%%%%%%%%%%%%
    %%for tridem
    sigmaZtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    sigmaXtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    sigmaYtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    tauXYtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);

    epsXtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    epsYtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    gmXYtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    epsHtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
    epsZtridem = zeros(length(z),nrTr,length(axlesTridemWeights),termination);
end

%% Compute stresses with the MLE_sigma for each family of axles.
%% 1 Singles - light weight, 6-ton and 10.5-ton

%nrsL = length(rSingleL); [4 pos]
nax = length(axlesSingleLWeights);
rSingleL = zeros(nax,nrsL);            %%store the 4 radial positions for each weight combination (they depend on the contact radius, which depends on the load)

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynSingleLight(:,:,k);
auxv_HMA = HMAPoissonSingleLight(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons


for j = 1:nax     
    %update v2019-03-19: replaced r=0 with r=0.01m
    rSingleL(j,:) = [0.01 0.5*0.01*aSingleLight(j) 0.01*aSingleLight(j) 0.01*aSingleLight(j) + 0.10];
    %for i = 1:nrsL
        %get axle Load (tons), convert to load by wheel -> That's axleSingleLWeights(j)/2
        %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
        %get E, nu, height for all materials! - watchful for asphalt materials!
       %get the sigmaZ, sigmaR, sigmaT values at each Z,R pair. No need to        %compose calculations for multiple wheels
       %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
       %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
       if axlesSingleLight(k,j)~=0   %"if there's actual traffic of these axles"
           %%update V2019-03-31:: pass pressure instead of total load to MLE_sigma.
           %%update V2019-05-14: Add 4th dimension to sigmaXXX outputs from %MLE
           aj = 0.01*aSingleLight(j);
           qj = 1/2*9800*axlesSingleLWeights(j)/(pi*(aj)^2);
           [sigmaZsingleL(:,:,j,k),sigmaXsingleL(:,:,j,k),sigmaYsingleL(:,:,j,k)] = MLE_sigma(qj,aj,rSingleL(j,:),z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       end
     %create these auxiliar auxE and aux_Poisson variables with the E and v for this load level to use with the conversion to strain        %equations
     auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
     auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
     %%these two above are in vector format [length(z) by 1]. need to convert
     %%them to z x r matrices. Multiply them for ones(1,length(r))
     auxLayersE = auxLayersE * ones(1,nrsL);
     auxLayersv = auxLayersv * ones(1,nrsL);

    %Convert stresses to strains (refer to Huang 04, chap 3)
    %%update V2019-05-14: Add 4th dimension to epsX, epsY, epsZ, epsH
    epsXsingleL(:,:,j,k) = 1./auxLayersE.*(sigmaXsingleL(:,:,j,k) - auxLayersv.*(sigmaYsingleL(:,:,j,k) + sigmaZsingleL(:,:,j,k)));
    epsYsingleL(:,:,j,k) = 1./auxLayersE.*(sigmaYsingleL(:,:,j,k) - auxLayersv.*(sigmaXsingleL(:,:,j,k) + sigmaZsingleL(:,:,j,k)));
    epsZsingleL(:,:,j,k) = 1./auxLayersE.*(sigmaZsingleL(:,:,j,k) - auxLayersv.*(sigmaXsingleL(:,:,j,k) + sigmaYsingleL(:,:,j,k)));
%     gmXYsingleL(:,:,j) = zeros(size(epsSingleL));
%%simplified formular for epsH, since there is no tauXY
    epsHsingleL(:,:,j,k) = 0.5.*(epsXsingleL(:,:,j,k) + epsYsingleL(:,:,j,k)) - 0.5.*(epsXsingleL(:,:,j,k)-epsYsingleL(:,:,j,k));
    %end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nrs6 = length(rSingle6); [4 pos]
nax = length(axlesSingle6Weights);
rSingle6 = zeros(nax,nrs6);            %%store the 4 radial positions for each weight combination (they depend on the contact radius, which depends on the load)

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynSingle6(:,:,k);
auxv_HMA = HMAPoissonSingle6(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons

for j = 1:nax
    %update v2019-03-19: replaced r=0 with r=0.01m
    rSingle6(j,:) = [0.01 0.5*0.01*aSingle6(j) 0.01*aSingle6(j) 0.01*aSingle6(j)+0.10];
    %for i = 1:nrs
        %get axle Load (tons), convert to load by wheel -> That's axleSingleLWeights(j)/2
        %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
        %get E, nu, height for all materials! - watchful for asphalt        %materials!
        %get the sigmaZ, sigmaR, sigmaT values at each Z,R pair. No need to compose calculations for multiple wheels
        %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
       if axlesSingle6(k,j)~=0   %"if there's actual traffic of these axles"
            %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
            %%update V2019-03-31:: pass pressure [qj] instead of total load to MLE_sigma.
            %%update V2019-05-14: Add 4th dimension to sigmaXXX outputs from %MLE
            aj = 0.01*aSingle6(j);
            qj = 1/2*9800*axlesSingle6Weights(j)/(pi*(aj)^2);
        	[sigmaZsingle6(:,:,j,k),sigmaXsingle6(:,:,j,k),sigmaYsingle6(:,:,j,k)] = MLE_sigma(qj,aj,rSingle6(j,:),z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       end
     %create these auxiliar auxE and aux_Poisson variables with the E and v for this load level to use with the conversion to strain        %equations
     auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
     auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
     %%these two above are in vector format [length(z) by 1]. need to convert
     %%them to z x r matrices. Multiply them for ones(1,length(r))
     auxLayersE = auxLayersE * ones(1,nrs6);
     auxLayersv = auxLayersv * ones(1,nrs6);

    %Convert stresses to strains (refer to Huang 04, chap 3)
    %%update V2019-05-14: Add 4th dimension to epsX, epsY, epsZ, epsH
    epsXsingle6(:,:,j,k) = 1./auxLayersE.*(sigmaXsingle6(:,:,j,k) - auxLayersv.*(sigmaYsingle6(:,:,j,k) + sigmaZsingle6(:,:,j,k)));
    epsYsingle6(:,:,j,k) = 1./auxLayersE.*(sigmaYsingle6(:,:,j,k) - auxLayersv.*(sigmaXsingle6(:,:,j,k) + sigmaZsingle6(:,:,j,k)));
    epsZsingle6(:,:,j,k) = 1./auxLayersE.*(sigmaZsingle6(:,:,j,k) - auxLayersv.*(sigmaXsingle6(:,:,j,k) + sigmaYsingle6(:,:,j,k)));
%     gmXYsingleL(:,:,j) = zeros(size(epsSingleL));
%%simplified formular for epsH, since there is no tauXY
    epsHsingle6(:,:,j,k) = 0.5.*(epsXsingle6(:,:,j,k) + epsYsingle6(:,:,j,k)) - 0.5.*(epsXsingle6(:,:,j,k)-epsYsingle6(:,:,j,k));
    %end
    %end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nrs = length(rSingles);  [6 pos]
nax = length(axlesSingle10Weights);
rSingle10 = zeros(nax,nrs10);  

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynSingle105(:,:,k);
auxv_HMA = HMAPoissonSingle105(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons

for j = 1:nax
    %update v2019-03-19: replaced r=0 in auxR1-auxR2 with r=0.01m
    rSingle10(j,:) = 0:1:5;
    %since I need to compose the effects of the dual wheels (and rSingle10 measures from the midpoint between the two wheels' centers (as in the MEPDG), I need to define respective r vectors for each.
    %auxR1 and auxR2 are the radial distance to each wheel from each rSingle10 position [calculated manually elsewhere]
    auxR1 = [0.5*dualWheelSep 0.75*dualWheelSep-0.5*0.01*aSingle105(j) dualWheelSep-0.01*aSingle105(j) dualWheelSep dualWheelSep+0.01*aSingle105(j) dualWheelSep+0.01*aSingle105(j)+0.10];
    auxR2 = [0.5*dualWheelSep 0.25*dualWheelSep+0.5*0.01*aSingle105(j) 0.01*aSingle105(j) 0.01 0.01*aSingle105(j) 0.01*aSingle105(j)+0.10];
    auxAlpha1 = zeros(1,6);   %%update v2019-05-20... rolled back these angles
    auxAlpha2 = [pi pi pi 0 0 0];
    %for the rotation calculations, extend auxAlpha1 and auxAlpha2 to the size of auxSigmaX1 and auxSigmaY2 (z x r)
    auxAlpha1 = ones(length(z),1)*auxAlpha1;
    auxAlpha2 = ones(length(z),1)*auxAlpha2;
    %for j = 1:nax
        %get axle Load (tons), convert to load by wheel -> That's axleSingleLWeights(j)/2
        %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
        %get E, nu, height for all materials! - watchful for asphalt materials!
        %get the sigmaZ, sigmaR, sigmaT values at each Z,R pair. - COMPOSE THE EFFECTS OF THE DUAL WHEELS!
      
        %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
        %%update 2019-03-19:: Correted it to properly work for each load      %%level and axle type
       if axlesSingle105(k,j)~=0   %"if there's actual traffic of these axles and load value"
            %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
             %update V2019-03-31:: pass pressure [qj] instead of total load to MLE_sigma.
            aj = 0.01*aSingle105(j);
            qj = 1/4*9800*axlesSingle10Weights(j)/(pi*(aj)^2);
            [auxSigmaZ1,auxSigmaR1,auxSigmaT1] = MLE_sigma(qj,aj,auxR1,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ2,auxSigmaR2,auxSigmaT2] = MLE_sigma(qj,aj,auxR2,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       else
           auxSigmaZ1 = zeros(length(z),nrs10);
           auxSigmaR1 = zeros(length(z),nrs10);
           auxSigmaT1 = zeros(length(z),nrs10);
           auxSigmaZ2 = zeros(length(z),nrs10);
           auxSigmaR2 = zeros(length(z),nrs10);
           auxSigmaT2 = zeros(length(z),nrs10);
       end
        %%update V2019-05-14: Add 4th dimension to sigmaXXX outputs from %MLE
       sigmaZsingle10(:,:,j,k) = auxSigmaZ1 + auxSigmaZ2;   %these sums here are the superposition of the sigmas of both wheels at each rSingle10 position
        %rotate the sigmaR and sigmaT to cartesian coordinates, sum them together
        auxSigmaX1 = auxSigmaR1.*(cos(auxAlpha1).^2) + auxSigmaT1.*(sin(auxAlpha1).^2);
        auxSigmaX2 = auxSigmaR2.*(cos(auxAlpha2).^2) + auxSigmaT2.*(sin(auxAlpha2).^2);
        auxSigmaY1 = auxSigmaR1.*(sin(auxAlpha1).^2) + auxSigmaT1.*(cos(auxAlpha1).^2);
        auxSigmaY2 = auxSigmaR2.*(sin(auxAlpha2).^2) + auxSigmaT2.*(cos(auxAlpha2).^2);
        auxTauXY1  = (auxSigmaR1 - auxSigmaT1).*sin(auxAlpha1).*cos(auxAlpha1);
        auxTauXY2  = (auxSigmaR2 - auxSigmaT2).*sin(auxAlpha2).*cos(auxAlpha2);
        
        %%update V2019-05-14: Add 4th dimension to sigmaXXX outputs from %MLE
        sigmaXsingle10(:,:,j,k) = auxSigmaX1 + auxSigmaX2; 
        sigmaYsingle10(:,:,j,k) = auxSigmaY1 + auxSigmaY2;
        tauXYsingle10(:,:,j,k) = auxTauXY1 + auxTauXY2;
        
        %create these auxiliar auxE and aux_Poisson variables with the E       %and v for this load level to use with the conversion to strain        %equations
        auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
        auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
        %%these two above are in vector format [length(z) by 1]. need to convert
        %%them to z x r matrices. Multiply them for ones(1,length(r))
        auxLayersE = auxLayersE * ones(1,nrs10);
        auxLayersv = auxLayersv * ones(1,nrs10);

        %Convert stresses to strains (refer to Huang 04, chap 3)
        %%update V2019-05-14: Add 4th dimension to epsX, epsY, epsZ, epsH
        epsXsingle10(:,:,j,k) = 1./auxLayersE.*(sigmaXsingle10(:,:,j,k) - auxLayersv.*(sigmaYsingle10(:,:,j,k) + sigmaZsingle10(:,:,j,k)));
        epsYsingle10(:,:,j,k) = 1./auxLayersE.*(sigmaYsingle10(:,:,j,k) - auxLayersv.*(sigmaXsingle10(:,:,j,k) + sigmaZsingle10(:,:,j,k)));
        epsZsingle10(:,:,j,k) = 1./auxLayersE.*(sigmaZsingle10(:,:,j,k) - auxLayersv.*(sigmaXsingle10(:,:,j,k) + sigmaYsingle10(:,:,j,k)));
        gmXYsingle10(:,:,j,k) = 2./auxLayersE.*(1+auxLayersv).*tauXYsingle10(:,:,j,k);
        %update v2019-03-19:: corrected formula for epsH, missing a ^2
        %UPDATE V2019-05-09:: BUG CORRECTED - the 'minus' sign in -gmXY is incorrect, should be a sum!
        epsHsingle10(:,:,j,k) = 0.5.*(epsXsingle10(:,:,j,k) + epsYsingle10(:,:,j,k)) - sqrt(0.25.*(epsXsingle10(:,:,j,k)-epsYsingle10(:,:,j,k)).^2 + gmXYsingle10(:,:,j,k).^2);
    %end
end

%% 2 Tandems - 10-ton, 14-ton, 18-ton

nax = length(axlesTandem10Weights);
rTandem10 = zeros(nax,nrTa10);

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynTandem10(:,:,k);
auxv_HMA = HMAPoissonTandem10(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons

for j = 1:nax
    %update v2019-03-19: replaced r=0 in auxR1-auxR2 with r=0.01m
    rTandem10(j,:) = 0:1:5;
    %since I need to compose the effects of the dual wheels (and rTandem10 measures from the midpoint between the two axles' centers, I need to define respective r vectors for each.
    %auxR1 and auxR2 are the radial distance to each wheel from each rSingle10 position [calculated manually elsewhere]
    auxR1 = [0.5*tandemAxleSep sqrt((0.5*tandemAxleSep)^2+(0.01*aTandem10(j))^2) sqrt((0.5*tandemAxleSep)^2+(0.01*aTandem10(j)+0.10)^2) tandemAxleSep sqrt(tandemAxleSep^2+(0.01*aTandem10(j))^2) sqrt(tandemAxleSep^2+(0.01*aTandem10(j)+0.10)^2)];
    auxR2 = [0.5*tandemAxleSep sqrt((0.5*tandemAxleSep)^2+(0.01*aTandem10(j))^2) sqrt((0.5*tandemAxleSep)^2+(0.01*aTandem10(j)+0.10)^2) 0.01 0.01*aTandem10(j) 0.01*aTandem10(j)+0.10];
    auxAlpha1 = [0.5*pi atan(tandemAxleSep/(2*0.01*aTandem10(j))) atan(tandemAxleSep/(2*0.01*aTandem10(j)+2*0.10)) 0.5*pi atan(tandemAxleSep/(0.01*aTandem10(j))) atan(tandemAxleSep/(0.01*aTandem10(j)+0.10))];
    auxAlpha2 = [-0.5*pi atan(-tandemAxleSep/(2*0.01*aTandem10(j)))  atan(-tandemAxleSep/(2*0.01*aTandem10(j)+2*0.10)) 0 0 0];
    %for the rotation calculations, extend auxAlpha1 and auxAlpha2 to the size of auxSigmaX1 and auxSigmaY2 (z x r)
    auxAlpha1 = ones(length(z),1)*auxAlpha1;
    auxAlpha2 = ones(length(z),1)*auxAlpha2;
    %get axle Load (tons) -  convert to load by wheel!
    %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
    %get E, nu, height for all materials! - watchful for asphalt  %materials!
    
     %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
      %%update 2019-03-19:: Correted it to properly work for each load      %%level and axle type
       if axlesTandem10(k,j)~=0   %"if there's actual traffic of these axles"
            %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
            %update V2019-03-31:: pass pressure [qj] instead of total load to MLE_sigma.
            aj = 0.01*aTandem10(j);
            qj = 1/4*9800*axlesTandem10Weights(j)/(pi*(aj)^2);
            [auxSigmaZ1,auxSigmaR1,auxSigmaT1] = MLE_sigma(qj,aj,auxR1,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ2,auxSigmaR2,auxSigmaT2] = MLE_sigma(qj,aj,auxR2,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       else
           auxSigmaZ1 = zeros(length(z),nrTa10);
           auxSigmaR1 = zeros(length(z),nrTa10);
           auxSigmaT1 = zeros(length(z),nrTa10);
           auxSigmaZ2 = zeros(length(z),nrTa10);
           auxSigmaR2 = zeros(length(z),nrTa10);
           auxSigmaT2 = zeros(length(z),nrTa10);
       end
    sigmaZtandem10(:,:,j,k) = auxSigmaZ1 + auxSigmaZ2;   %these sums here are the superposition of the sigmas of both wheels at each rSingle10 position
    %rotate the sigmaR and sigmaT to cartesian coordinates, sum them together
    auxSigmaX1 = auxSigmaR1.*(cos(auxAlpha1).^2) + auxSigmaT1.*(sin(auxAlpha1).^2);
    auxSigmaX2 = auxSigmaR2.*(cos(auxAlpha2).^2) + auxSigmaT2.*(sin(auxAlpha2).^2);
    auxSigmaY1 = auxSigmaR1.*(sin(auxAlpha1).^2) + auxSigmaT1.*(cos(auxAlpha1).^2);
    auxSigmaY2 = auxSigmaR2.*(sin(auxAlpha2).^2) + auxSigmaT2.*(cos(auxAlpha2).^2);
    auxTauXY1  = (auxSigmaR1 - auxSigmaT1).*sin(auxAlpha1).*cos(auxAlpha1);
    auxTauXY2  = (auxSigmaR2 - auxSigmaT2).*sin(auxAlpha2).*cos(auxAlpha2);

    %%update V2019-05-14: Add 4th dimension to sigmaXXX outputs
    sigmaXtandem10(:,:,j,k) = auxSigmaX1 + auxSigmaX2; 
    sigmaYtandem10(:,:,j,k) = auxSigmaY1 + auxSigmaY2;
    tauXYtandem10(:,:,j,k) = auxTauXY1 + auxTauXY2;

    %create these auxiliar auxE and aux_Poisson variables with the E       %and v for this load level to use with the conversion to strain        %equations
    auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
    auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
    %%these two above are in vector format [length(z) by 1]. need to convert
    %%them to z x r matrices. Multiply them for ones(1,length(r))
    auxLayersE = auxLayersE * ones(1,nrTa10);
    auxLayersv = auxLayersv * ones(1,nrTa10);

    %Convert stresses to strains (refer to Huang 04, chap 3)
    %%update V2019-05-14: Add 4th dimension to epsX, epsY, epsZ, epsH
    %%BUG DETECTED V2019-05-14: CORRECT FORMULA FOR gmXY (was calling
    %%"single10")
    epsXtandem10(:,:,j,k) = 1./auxLayersE.*(sigmaXtandem10(:,:,j,k) - auxLayersv.*(sigmaYtandem10(:,:,j,k) + sigmaZtandem10(:,:,j,k)));
    epsYtandem10(:,:,j,k) = 1./auxLayersE.*(sigmaYtandem10(:,:,j,k) - auxLayersv.*(sigmaXtandem10(:,:,j,k) + sigmaZtandem10(:,:,j,k)));
    epsZtandem10(:,:,j,k) = 1./auxLayersE.*(sigmaZtandem10(:,:,j,k) - auxLayersv.*(sigmaXtandem10(:,:,j,k) + sigmaYtandem10(:,:,j,k)));
    gmXYtandem10(:,:,j,k) = 2./auxLayersE.*(1+auxLayersv).*tauXYtandem10(:,:,j,k);
    %update v2019-03-19:: corrected formula for epsH, missing a ^2
    epsHtandem10(:,:,j,k) = 0.5.*(epsXtandem10(:,:,j,k) + epsYtandem10(:,:,j,k)) - sqrt(0.25.*(epsXtandem10(:,:,j,k)-epsYtandem10(:,:,j,k)).^2 + gmXYtandem10(:,:,j,k).^2);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nax = length(axlesTandem14Weights);
rTandem14 = zeros(nax,nrTa14);

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynTandem14(:,:,k);
auxv_HMA = HMAPoissonTandem14(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons

for j = 1:nax
    %update V2019-05-20: bug detected in auxAlpha1. Corrected. Also rolled back angle convention
    %update v2019-03-19: replaced r=0 in auxR1-auxR2 with r=0.01m
    rTandem14(j,:) = 0:1:14;
    %since I need to compose the effects of the THREE wheels (and rTandem14 measures from the center of the outermost wheel in the dualwheel axle, I need to define respective r vectors for each.
    %auxR1 and auxR2 are the radial distance to each wheel from each rSingle10 position [calculated manually elsewhere]
    auxR1 = [0.01 0.01*aTandem14(j) 0.25*dualWheelSep+0.5*0.01*aTandem14(j) 0.5*dualWheelSep 0.75*dualWheelSep-0.5*0.01*aTandem14(j) dualWheelSep-0.01*aTandem14(j) dualWheelSep dualWheelSep+0.01*aTandem14(j) dualWheelSep+0.01*aTandem14(j)+0.10 ...
        0.5*tandemAxleSep sqrt((0.5*tandemAxleSep)^2+(0.01*aTandem14(j))^2) sqrt((0.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) tandemAxleSep sqrt((0.01*aTandem14(j))^2+tandemAxleSep^2) sqrt(tandemAxleSep^2+(0.01*aTandem14(j)+0.10)^2)];
    auxR2 = [dualWheelSep dualWheelSep-0.01*aTandem14(j) 0.75*dualWheelSep-0.5*0.01*aTandem14(j) 0.5*dualWheelSep 0.25*dualWheelSep+0.01*0.5*aTandem14(j) 0.01*aTandem14(j) 0.01 0.01*aTandem14(j) 0.01*aTandem14(j)+0.10 ...
        sqrt(dualWheelSep^2+(0.5*tandemAxleSep)^2) sqrt((0.5*tandemAxleSep)^2+(dualWheelSep-0.01*aTandem14(j))^2) sqrt((0.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+dualWheelSep^2) sqrt(tandemAxleSep^2+(dualWheelSep-0.01*aTandem14(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep-0.01*aTandem14(j)-0.10)^2)];
    auxR3 = [tandemAxleSep sqrt(tandemAxleSep^2+(0.01*aTandem14(j))^2) sqrt(tandemAxleSep^2+(0.25*dualWheelSep+0.5*0.01*aTandem14(j))^2) sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.75*dualWheelSep-0.5*0.01*aTandem14(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep-0.01*aTandem14(j))^2) sqrt(tandemAxleSep^2+dualWheelSep^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTandem14(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTandem14(j)+0.10)^2)...
        0.5*tandemAxleSep sqrt((0.01*aTandem14(j))^2+(0.5*tandemAxleSep)^2) sqrt((0.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) 0.01 0.01*aTandem14(j) 0.01*aTandem14(j)+0.10];
    auxAlpha1 = [0 0 0 0 0 0 0 0 0 ...
        0.5*pi atan(tandemAxleSep/(2*0.01*aTandem14(j))) atan(tandemAxleSep/dualWheelSep) 0.5*pi atan(tandemAxleSep/(0.01*aTandem14(j))) atan(2*tandemAxleSep/dualWheelSep)];
    auxAlpha2 = [pi pi pi pi pi pi 0 0 0 ...
        pi-atan(0.5*tandemAxleSep/dualWheelSep) pi-atan(0.5*tandemAxleSep/(dualWheelSep-0.01*aTandem14(j))) pi-atan(tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep/(dualWheelSep-0.01*aTandem14(j))) pi-atan(2*tandemAxleSep/dualWheelSep)];
    auxAlpha3 = [-pi/2 atan(-tandemAxleSep/auxR1(2)) atan(-tandemAxleSep/auxR1(3)) atan(-tandemAxleSep/auxR1(4)) atan(-tandemAxleSep/auxR1(5)) atan(-tandemAxleSep/auxR1(6)) ...
        atan(-tandemAxleSep/auxR1(7)) atan(-tandemAxleSep/auxR1(8)) atan(-tandemAxleSep/auxR1(9)) -pi/2 atan(-0.5*tandemAxleSep/(0.01*aTandem14(j))) atan(-tandemAxleSep/dualWheelSep) 0 0 0];
    %for the rotation calculations, extend auxAlpha1 and auxAlpha2 to the size of auxSigmaX1 and auxSigmaY2 (z x r)
    auxAlpha1 = ones(length(z),1)*auxAlpha1;
    auxAlpha2 = ones(length(z),1)*auxAlpha2;
    auxAlpha3 = ones(length(z),1)*auxAlpha3;
     
    %get axle Load (tons) -  convert to load by wheel!
    %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
    %get E, nu, height for all materials! - watchful for asphalt        %materials! 
         %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
          %%update 2019-03-19:: Correted it to properly work for each load      %%level and axle type
          %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
       if axlesTandem14(k,j)~=0   %"if there's actual traffic of these axles"
           %update V2019-03-31:: pass pressure [qj] instead of total load to MLE_sigma.
            aj = 0.01*aTandem14(j);
            qj = 1/6*9800*axlesTandem14Weights(j)/(pi*(aj)^2);
            [auxSigmaZ1,auxSigmaR1,auxSigmaT1] = MLE_sigma(qj,aj,auxR1,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ2,auxSigmaR2,auxSigmaT2] = MLE_sigma(qj,aj,auxR2,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ3,auxSigmaR3,auxSigmaT3] = MLE_sigma(qj,aj,auxR3,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       else
           auxSigmaZ1 = zeros(length(z),nrTa14);
           auxSigmaR1 = zeros(length(z),nrTa14);
           auxSigmaT1 = zeros(length(z),nrTa14);
           auxSigmaZ2 = zeros(length(z),nrTa14);
           auxSigmaR2 = zeros(length(z),nrTa14);
           auxSigmaT2 = zeros(length(z),nrTa14);
           auxSigmaZ3 = zeros(length(z),nrTa14);
           auxSigmaR3 = zeros(length(z),nrTa14);
           auxSigmaT3 = zeros(length(z),nrTa14);
       end
       
    sigmaZtandem14(:,:,j,k) = auxSigmaZ1 + auxSigmaZ2 + auxSigmaZ3;   %these sums here are the superposition of the sigmas of both wheels at each rSingle10 position

     %rotate the sigmaR and sigmaT to cartesian coordinates, sum them together
    auxSigmaX1 = auxSigmaR1.*(cos(auxAlpha1).^2) + auxSigmaT1.*(sin(auxAlpha1).^2);
    auxSigmaX2 = auxSigmaR2.*(cos(auxAlpha2).^2) + auxSigmaT2.*(sin(auxAlpha2).^2);
    auxSigmaX3 = auxSigmaR3.*(cos(auxAlpha3).^2) + auxSigmaT3.*(sin(auxAlpha3).^2);
    auxSigmaY1 = auxSigmaR1.*(sin(auxAlpha1).^2) + auxSigmaT1.*(cos(auxAlpha1).^2);
    auxSigmaY2 = auxSigmaR2.*(sin(auxAlpha2).^2) + auxSigmaT2.*(cos(auxAlpha2).^2);
    auxSigmaY3 = auxSigmaR3.*(sin(auxAlpha3).^2) + auxSigmaT3.*(cos(auxAlpha3).^2);
    auxTauXY1  = (auxSigmaR1 - auxSigmaT1).*sin(auxAlpha1).*cos(auxAlpha1);
    auxTauXY2  = (auxSigmaR2 - auxSigmaT2).*sin(auxAlpha2).*cos(auxAlpha2);
    auxTauXY3  = (auxSigmaR3 - auxSigmaT3).*sin(auxAlpha3).*cos(auxAlpha3);

    %%update V2019-05-14: Add 4th dimension to sgimaXXX outputs
    sigmaXtandem14(:,:,j,k) = auxSigmaX1 + auxSigmaX2 + auxSigmaX3; 
    sigmaYtandem14(:,:,j,k) = auxSigmaY1 + auxSigmaY2 + auxSigmaY3;
    tauXYtandem14(:,:,j,k) = auxTauXY1 + auxTauXY2 + auxTauXY3;

    %create these auxiliar auxE and aux_Poisson variables with the E       %and v for this load level to use with the conversion to strain        %equations
    auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
    auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
    %%these two above are in vector format [length(z) by 1]. need to convert
    %%them to z x r matrices. Multiply them for ones(1,length(r))
    auxLayersE = auxLayersE * ones(1,nrTa14);
    auxLayersv = auxLayersv * ones(1,nrTa14);

    %Convert stresses to strains (refer to Huang 04, chap 3)
    %%update V2019-05-14: Add 4th dimension to epsX, epsY, epsZ, epsH
    epsXtandem14(:,:,j,k) = 1./auxLayersE.*(sigmaXtandem14(:,:,j,k) - auxLayersv.*(sigmaYtandem14(:,:,j,k) + sigmaZtandem14(:,:,j,k)));
    epsYtandem14(:,:,j,k) = 1./auxLayersE.*(sigmaYtandem14(:,:,j,k) - auxLayersv.*(sigmaXtandem14(:,:,j,k) + sigmaZtandem14(:,:,j,k)));
    epsZtandem14(:,:,j,k) = 1./auxLayersE.*(sigmaZtandem14(:,:,j,k) - auxLayersv.*(sigmaXtandem14(:,:,j,k) + sigmaYtandem14(:,:,j,k)));
    gmXYtandem14(:,:,j,k) = 2./auxLayersE.*(1+auxLayersv).*tauXYtandem14(:,:,j,k);
    %update v2019-03-19:: corrected formula for epsH, missing a ^2
    epsHtandem14(:,:,j,k) = 0.5.*(epsXtandem14(:,:,j,k) + epsYtandem14(:,:,j,k)) - sqrt(0.25.*(epsXtandem14(:,:,j,k)-epsYtandem14(:,:,j,k)).^2 + gmXYtandem14(:,:,j,k).^2);
%     
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nax = length(axlesTandemWeights);
rTandem18 = zeros(nax,nrTa18);

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynTandem18(:,:,k);
auxv_HMA = HMAPoissonTandem18(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons

for j = 1:nax
    %update v2019-05-20: Rolled back angle convention (was incorrect)
    %update v2019-03-19: replaced r=0 in auxR1-auxR2 with r=0.01m
  rTandem18(j,:) = 0:1:11;
    %since I need to compose the effects of the THREE wheels (and rTandem18 measures from the center of the outermost wheel in the dualwheel axle, I need to define respective r vectors for each.
    %auxR1 and auxR2 are the radial distance to each wheel from each rSingle10 position [calculated manually elsewhere]
    auxR1 = [sqrt((0.5*dualWheelSep)^2+(0.5*tandemAxleSep)^2) sqrt((0.5*dualWheelSep)^2+(0.75*tandemAxleSep-0.5*0.01*aTandem18(j))^2) sqrt((0.5*dualWheelSep)^2+(tandemAxleSep-0.01*aTandem18(j))^2) sqrt((0.5*dualWheelSep)^2+tandemAxleSep^2) sqrt((0.5*dualWheelSep)^2+(tandemAxleSep+0.01*aTandem18(j))^2) sqrt((0.5*dualWheelSep)^2+(tandemAxleSep+0.01*aTandem18(j)+0.10)^2)...
        sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(-0.5*0.01*aTandem18(j)+0.75*dualWheelSep)^2) sqrt(tandemAxleSep^2+(dualWheelSep-0.01*aTandem18(j))^2) sqrt(tandemAxleSep^2+dualWheelSep^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTandem18(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTandem18(j)+0.1)^2)];
    auxR2 =  [sqrt((0.5*dualWheelSep)^2+(0.5*tandemAxleSep)^2) sqrt((0.5*dualWheelSep)^2+(0.25*tandemAxleSep+0.5*0.01*aTandem18(j))^2) sqrt((0.5*dualWheelSep)^2+(0.01*aTandem18(j))^2) 0.5*dualWheelSep sqrt((0.5*dualWheelSep)^2+(0.01*aTandem18(j))^2) sqrt((0.5*dualWheelSep)^2+(0.01*aTandem18(j)+0.10)^2)...
        sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.5*0.01*aTandem18(j)+0.25*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.01*aTandem18(j))^2) tandemAxleSep sqrt(tandemAxleSep^2+(0.01*aTandem18(j))^2) sqrt(tandemAxleSep^2+(0.01*aTandem18(j)+0.1)^2)];
    auxR3 = [auxR1(1) auxR1(2) auxR1(3) auxR1(4) auxR1(5) auxR1(6) dualWheelSep/2 0.75*dualWheelSep-0.5*0.01*aTandem18(j) dualWheelSep-0.01*aTandem18(j) dualWheelSep dualWheelSep+0.01*aTandem18(j) dualWheelSep+0.01*aTandem18(j)+0.10];
    auxR4 = [auxR2(1) auxR2(2) auxR2(3) auxR2(4) auxR2(5) auxR2(6) dualWheelSep/2 0.25*dualWheelSep+0.5*0.01*aTandem18(j) 0.01*aTandem18(j) 0.01 0.01*aTandem18(j) 0.01*aTandem18(j)+0.10];
    auxAlpha1 = [atan(tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(3*dualWheelSep/2-0.01*aTandem18(j))) atan(tandemAxleSep*0.5/(dualWheelSep-0.01*aTandem18(j))) atan(tandemAxleSep*0.5/dualWheelSep) atan(tandemAxleSep*0.5/(dualWheelSep+0.01*aTandem18(j))) atan(tandemAxleSep*0.5/(dualWheelSep+0.01*aTandem18(j)+0.10))...
        atan(2*tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(0.75*dualWheelSep-0.5*0.01*aTandem18(j))) atan(tandemAxleSep/(dualWheelSep-0.01*aTandem18(j))) atan(tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(dualWheelSep+0.01*aTandem18(j))) atan(tandemAxleSep/(dualWheelSep+0.01*aTandem18(j)+0.10))];
    auxAlpha2 = [pi-atan(tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep/(0.01*aTandem18(j)+0.5*dualWheelSep)) pi-atan(tandemAxleSep*0.5/(0.01*aTandem18(j))) 0.5*pi atan(tandemAxleSep*0.5/(0.01*aTandem18(j))) atan(tandemAxleSep*0.5/(0.10+0.01*aTandem18(j)))...
        pi-atan(2*tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep/(0.25*dualWheelSep+0.5*0.01*aTandem18(j))) pi-atan(tandemAxleSep/(0.01*aTandem18(j))) pi/2 atan(tandemAxleSep/(0.01*aTandem18(j))) atan(tandemAxleSep/(0.10+0.01*aTandem18(j)))];
    auxAlpha3 = [atan(-tandemAxleSep/dualWheelSep) atan(-tandemAxleSep/(3*dualWheelSep/2-0.01*aTandem18(j))) atan(-tandemAxleSep*0.5/(dualWheelSep-0.01*aTandem18(j))) atan(-tandemAxleSep*0.5/dualWheelSep) atan(-tandemAxleSep*0.5/(dualWheelSep+0.01*aTandem18(j))) atan(-tandemAxleSep*0.5/(dualWheelSep+0.01*aTandem18(j)+0.10))...
        0 0 0 0 0 0 ];
    auxAlpha4 = [pi+atan(tandemAxleSep/dualWheelSep) pi+atan(tandemAxleSep/(0.01*aTandem18(j)+0.5*dualWheelSep)) pi+atan(tandemAxleSep*0.5/(0.01*aTandem18(j))) -0.5*pi atan(-tandemAxleSep*0.5/(0.01*aTandem18(j))) atan(-tandemAxleSep*0.5/(0.10+0.01*aTandem18(j)))...
        pi pi pi 0 0 0];
    %for the rotation calculations, extend auxAlpha1 and auxAlpha2 to the size of auxSigmaX1 and auxSigmaY2 (z x r)
    auxAlpha1 = ones(length(z),1)*auxAlpha1;
    auxAlpha2 = ones(length(z),1)*auxAlpha2;
    auxAlpha3 = ones(length(z),1)*auxAlpha3;
    auxAlpha4 = ones(length(z),1)*auxAlpha4;
    %get axle Load (tons) -  convert to load by wheel!
    %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
    %get E, nu, height for all materials! - watchful for asphalt        %materials! 
       %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
        %%update 2019-03-19:: Correted it to properly work for each load      %%level and axle type
        %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
       if axlesTandem18(k,j)~=0   %"if there's actual traffic of these axles"
           %update V2019-03-31:: pass pressure [qj] instead of total load to MLE_sigma.
            aj = 0.01*aTandem18(j);
            qj = 1/8*9800*axlesTandemWeights(j)/(pi*(aj)^2);
            [auxSigmaZ1,auxSigmaR1,auxSigmaT1] = MLE_sigma(qj,aj,auxR1,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ2,auxSigmaR2,auxSigmaT2] = MLE_sigma(qj,aj,auxR2,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ3,auxSigmaR3,auxSigmaT3] = MLE_sigma(qj,aj,auxR3,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ4,auxSigmaR4,auxSigmaT4] = MLE_sigma(qj,aj,auxR4,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       else
           auxSigmaZ1 = zeros(length(z),nrTa18);
           auxSigmaR1 = zeros(length(z),nrTa18);
           auxSigmaT1 = zeros(length(z),nrTa18);
           auxSigmaZ2 = zeros(length(z),nrTa18);
           auxSigmaR2 = zeros(length(z),nrTa18);
           auxSigmaT2 = zeros(length(z),nrTa18);
           auxSigmaZ3 = zeros(length(z),nrTa18);
           auxSigmaR3 = zeros(length(z),nrTa18);
           auxSigmaT3 = zeros(length(z),nrTa18);
           auxSigmaZ4 = zeros(length(z),nrTa18);
           auxSigmaR4 = zeros(length(z),nrTa18);
           auxSigmaT4 = zeros(length(z),nrTa18);
       end   
    sigmaZtandem18(:,:,j,k) = auxSigmaZ1 + auxSigmaZ2 + auxSigmaZ3 + auxSigmaZ4;   %these sums here are the superposition of the sigmas of both wheels at each rSingle10 position

     %rotate the sigmaR and sigmaT to cartesian coordinates, sum them together
    auxSigmaX1 = auxSigmaR1.*(cos(auxAlpha1).^2) + auxSigmaT1.*(sin(auxAlpha1).^2);
    auxSigmaX2 = auxSigmaR2.*(cos(auxAlpha2).^2) + auxSigmaT2.*(sin(auxAlpha2).^2);
    auxSigmaX3 = auxSigmaR3.*(cos(auxAlpha3).^2) + auxSigmaT3.*(sin(auxAlpha3).^2);
    auxSigmaX4 = auxSigmaR4.*(cos(auxAlpha4).^2) + auxSigmaT4.*(sin(auxAlpha4).^2);
    auxSigmaY1 = auxSigmaR1.*(sin(auxAlpha1).^2) + auxSigmaT1.*(cos(auxAlpha1).^2);
    auxSigmaY2 = auxSigmaR2.*(sin(auxAlpha2).^2) + auxSigmaT2.*(cos(auxAlpha2).^2);
    auxSigmaY3 = auxSigmaR3.*(sin(auxAlpha3).^2) + auxSigmaT3.*(cos(auxAlpha3).^2);
    auxSigmaY4 = auxSigmaR4.*(sin(auxAlpha4).^2) + auxSigmaT4.*(cos(auxAlpha4).^2);
    auxTauXY1  = (auxSigmaR1 - auxSigmaT1).*sin(auxAlpha1).*cos(auxAlpha1);
    auxTauXY2  = (auxSigmaR2 - auxSigmaT2).*sin(auxAlpha2).*cos(auxAlpha2);
    auxTauXY3  = (auxSigmaR3 - auxSigmaT3).*sin(auxAlpha3).*cos(auxAlpha3);
    auxTauXY4  = (auxSigmaR4 - auxSigmaT4).*sin(auxAlpha4).*cos(auxAlpha4);

    %%update V2019-05-14: Add 4th dimension to sigmaXXXX
    sigmaXtandem18(:,:,j,k) = auxSigmaX1 + auxSigmaX2 + auxSigmaX3 + auxSigmaX4; 
    sigmaYtandem18(:,:,j,k) = auxSigmaY1 + auxSigmaY2 + auxSigmaY3 + auxSigmaY4;
    tauXYtandem18(:,:,j,k) = auxTauXY1 + auxTauXY2 + auxTauXY3 + auxTauXY4;

    %create these auxiliar auxE and aux_Poisson variables with the E       %and v for this load level to use with the conversion to strain equations
    auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
    auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
    %%these two above are in vector format [length(z) by 1]. need to convert them to z x r matrices. Multiply them for ones(1,length(r))
    auxLayersE = auxLayersE * ones(1,nrTa18);
    auxLayersv = auxLayersv * ones(1,nrTa18);

    %Convert stresses to strains (refer to Huang 04, chap 3)
    %%update V2019-05-14: Add 4th dimension to epsX, epsY, epsZ, epsH
    epsXtandem18(:,:,j,k) = 1./auxLayersE.*(sigmaXtandem18(:,:,j,k) - auxLayersv.*(sigmaYtandem18(:,:,j,k) + sigmaZtandem18(:,:,j,k)));
    epsYtandem18(:,:,j,k) = 1./auxLayersE.*(sigmaYtandem18(:,:,j,k) - auxLayersv.*(sigmaXtandem18(:,:,j,k) + sigmaZtandem18(:,:,j,k)));
    epsZtandem18(:,:,j,k) = 1./auxLayersE.*(sigmaZtandem18(:,:,j,k) - auxLayersv.*(sigmaXtandem18(:,:,j,k) + sigmaYtandem18(:,:,j,k)));
    gmXYtandem18(:,:,j,k) = 2./auxLayersE.*(1+auxLayersv).*tauXYtandem18(:,:,j,k);
    %update v2019-03-19:: corrected formula for epsH, missing a ^2
    epsHtandem18(:,:,j,k) = 0.5.*(epsXtandem18(:,:,j,k) + epsYtandem18(:,:,j,k)) - sqrt(0.25.*(epsXtandem18(:,:,j,k)-epsYtandem18(:,:,j,k)).^2 + gmXYtandem18(:,:,j,k).^2);
%
end

%% 3 Tridem - 25.5-ton only

nax = length(axlesTridemWeights);
rTridem = zeros(nax,nrTr);

%%compose the vector of Es from the HMA layers (temperature and load varying) and the gran. layers MR.. 
auxE_HMA = EDynTridem(:,:,k);
auxv_HMA = HMAPoissonTridem(:,:,k);%%get the poisson coefficients for all HMA layers (rows) and all load ranges (cols) for timestamp k (stack)

layersE = MR(k,:)' * ones(1,nax);     %Step 1: retrieve the granular and subgrade's MRs and turn it to a matrix the same size of the E*. The product gives a matrix [layers x axleWeight] in size
layersE = [auxE_HMA;layersE];         %Step 2: stack the two matrices together
%%update v2019-03-19:: unit consistency check, convert layersE from PSI to Pa
layersE = layersE/145.04*1e6;

layersv = granPoiss * ones(1,nax);
layersv = [auxv_HMA; layersv];         %repeat to get the Poissons

for j = 1:nax
    rTridem(j,:) = 0:1:17;
    %since I need to compose the effects of the THREE wheels (and rTridem measures from the center of the outermost wheel in the dualwheel axle, I need to define respective r vectors for each.
    %auxR1 and auxR2 are the radial distance to each wheel from each rSingle10 position [calculated manually elsewhere]
    auxR1 = [sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.75*dualWheelSep-0.5*0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep-0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+dualWheelSep^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTridem(j)+0.10)^2)...
        sqrt((1.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt((1.5*tandemAxleSep)^2+(0.75*dualWheelSep-0.5*0.01*aTridem(j))^2) sqrt((1.5*tandemAxleSep)^2+(dualWheelSep-0.01*aTridem(j))^2) sqrt((1.5*tandemAxleSep)^2+dualWheelSep^2) sqrt((1.5*tandemAxleSep)^2+(dualWheelSep+0.01*aTridem(j))^2) sqrt((1.5*tandemAxleSep)^2+(dualWheelSep+0.01*aTridem(j)+0.10)^2)...
        sqrt((2*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt((2*tandemAxleSep)^2+(0.75*dualWheelSep-0.5*0.01*aTridem(j))^2) sqrt((2*tandemAxleSep)^2+(dualWheelSep-0.01*aTridem(j))^2) sqrt((2*tandemAxleSep)^2+dualWheelSep^2) sqrt((2*tandemAxleSep)^2+(dualWheelSep+0.01*aTridem(j))^2) sqrt((2*tandemAxleSep)^2+(dualWheelSep+0.01*aTridem(j)+0.10)^2)];
    auxR2 = [sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.25*dualWheelSep+0.5*0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(0.01*aTridem(j))^2) tandemAxleSep sqrt(tandemAxleSep^2+(0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(0.01*aTridem(j)+0.10)^2)...
        sqrt((1.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt((1.5*tandemAxleSep)^2+(0.25*dualWheelSep+0.5*0.01*aTridem(j))^2) sqrt((1.5*tandemAxleSep)^2+(0.01*aTridem(j))^2) 1.5*tandemAxleSep sqrt((1.5*tandemAxleSep)^2+(0.01*aTridem(j))^2) sqrt((1.5*tandemAxleSep)^2+(0.01*aTridem(j)+0.10)^2)...
        sqrt((2*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt((2*tandemAxleSep)^2+(0.25*dualWheelSep+0.5*0.01*aTridem(j))^2) sqrt((2*tandemAxleSep)^2+(0.01*aTridem(j))^2) 2*tandemAxleSep sqrt((2*tandemAxleSep)^2+(0.01*aTridem(j))^2) sqrt((2*tandemAxleSep)^2+(0.01*aTridem(j)+0.10)^2)];
    auxR3 = [0.5*dualWheelSep 0.75*dualWheelSep-0.5*0.01*aTridem(j) dualWheelSep-0.01*aTridem(j) dualWheelSep dualWheelSep+0.01*aTridem(j) dualWheelSep+0.01*aTridem(j)+0.10...
        sqrt((0.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt((0.5*tandemAxleSep)^2+(0.75*dualWheelSep-0.5*0.01*aTridem(j))^2) sqrt((0.5*tandemAxleSep)^2+(dualWheelSep-0.01*aTridem(j))^2) sqrt((0.5*tandemAxleSep)^2+dualWheelSep^2) sqrt((0.5*tandemAxleSep)^2+(dualWheelSep+0.01*aTridem(j))^2) sqrt((0.5*tandemAxleSep)^2+(dualWheelSep+0.01*aTridem(j)+0.10)^2)...
        sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.75*dualWheelSep-0.5*0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep-0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+dualWheelSep^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(dualWheelSep+0.01*aTridem(j)+0.10)^2)];
    auxR4 = [0.5*dualWheelSep 0.25*dualWheelSep+0.5*0.01*aTridem(j) 0.01*aTridem(j) 0.01 0.01*aTridem(j) 0.01*aTridem(j)+0.10...
        sqrt((0.5*tandemAxleSep)^2+(0.5*dualWheelSep)^2) sqrt((0.5*tandemAxleSep)^2+(0.25*dualWheelSep+0.5*0.01*aTridem(j))^2) sqrt((0.5*tandemAxleSep)^2+(0.01*aTridem(j))^2) 1.5*tandemAxleSep sqrt((0.5*tandemAxleSep)^2+(0.01*aTridem(j))^2) sqrt((0.5*tandemAxleSep)^2+(0.01*aTridem(j)+0.10)^2)...
        sqrt(tandemAxleSep^2+(0.5*dualWheelSep)^2) sqrt(tandemAxleSep^2+(0.25*dualWheelSep+0.5*0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(0.01*aTridem(j))^2) tandemAxleSep sqrt(tandemAxleSep^2+(0.01*aTridem(j))^2) sqrt(tandemAxleSep^2+(0.01*aTridem(j)+0.10)^2)];
    auxR5 = [auxR1(1) auxR1(2) auxR1(3) auxR1(4) auxR1(5) auxR1(6)...
        auxR3(7) auxR3(8) auxR3(9) auxR3(10) auxR3(11) auxR3(12)...
        0.5*dualWheelSep 0.75*dualWheelSep-0.5*0.01*aTridem(j) dualWheelSep-0.01*aTridem(j) dualWheelSep dualWheelSep+0.01*aTridem(j) dualWheelSep+0.01*aTridem(j)+0.10];
    auxR6 = [auxR2(1) auxR2(2) auxR2(3) auxR2(4) auxR2(5) auxR2(6)...
        auxR4(7) auxR4(8) auxR4(9) auxR4(10) auxR4(11) auxR4(12)...
        0.5*dualWheelSep 0.25*dualWheelSep+0.5*0.01*aTridem(j) 0.01*aTridem(j) 0.01 0.01*aTridem(j) 0.01*aTridem(j)+0.10];
    auxAlpha1 = [atan(2*tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(tandemAxleSep/(dualWheelSep-0.01*aTridem(j))) atan(tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(dualWheelSep+0.01*aTridem(j))) atan(tandemAxleSep/(dualWheelSep+0.01*aTridem(j)+0.10))...
        atan(3*tandemAxleSep/dualWheelSep) atan(1.5*tandemAxleSep/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(1.5*tandemAxleSep/(dualWheelSep-0.01*aTridem(j))) atan(1.5*tandemAxleSep/dualWheelSep) atan(1.5*tandemAxleSep/(dualWheelSep+0.01*aTridem(j))) atan(1.5*tandemAxleSep/(dualWheelSep+0.01*aTridem(j)+0.10))...
        atan(4*tandemAxleSep/dualWheelSep) atan(2*tandemAxleSep/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(2*tandemAxleSep/(dualWheelSep-0.01*aTridem(j))) atan(2*tandemAxleSep/dualWheelSep) atan(2*tandemAxleSep/(dualWheelSep+0.01*aTridem(j))) atan(2*tandemAxleSep/(dualWheelSep+0.01*aTridem(j)+0.10))];
    auxAlpha2 = [pi-atan(2*tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi-atan(tandemAxleSep/(0.01*aTridem(j))) 0.5*pi atan(tandemAxleSep/(0.01*aTridem(j))) atan(tandemAxleSep/(0.01*aTridem(j)+0.10))...
        pi-atan(3*tandemAxleSep/dualWheelSep) pi-atan(1.5*tandemAxleSep/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi-atan(1.5*tandemAxleSep/(0.01*aTridem(j))) 0.5*pi atan(1.5*tandemAxleSep/(0.01*aTridem(j))) atan(1.5*tandemAxleSep/(0.01*aTridem(j)+0.10))...
        pi-atan(4*tandemAxleSep/dualWheelSep) pi-atan(2*tandemAxleSep/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi-atan(2*tandemAxleSep/(0.01*aTridem(j))) 0.5*pi atan(2*tandemAxleSep/(0.01*aTridem(j))) atan(2*tandemAxleSep/(0.01*aTridem(j)+0.10))];
    auxAlpha3 = [0 0 0 0 0 0 ...
        atan(tandemAxleSep/dualWheelSep) atan(tandemAxleSep*0.5/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(tandemAxleSep*0.5/(dualWheelSep-0.01*aTridem(j))) atan(tandemAxleSep*0.5/dualWheelSep) atan(tandemAxleSep*0.5/(dualWheelSep+0.01*aTridem(j))) atan(tandemAxleSep*0.5/(dualWheelSep+0.01*aTridem(j)+0.10))...
        atan(2*tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(tandemAxleSep/(dualWheelSep-0.01*aTridem(j))) atan(tandemAxleSep/dualWheelSep) atan(tandemAxleSep/(dualWheelSep+0.01*aTridem(j))) atan(tandemAxleSep/(dualWheelSep+0.01*aTridem(j)+0.10))];
    auxAlpha4 = [pi pi pi 0 0 0 ...
        pi-atan(tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep*0.5/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi-atan(tandemAxleSep*0.5/(0.01*aTridem(j))) 0.5*pi atan(tandemAxleSep*0.5/(0.01*aTridem(j))) atan(tandemAxleSep*0.5/(aTridem(j)*0.01+0.10))...
        pi-atan(2*tandemAxleSep/dualWheelSep) pi-atan(tandemAxleSep/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi-atan(tandemAxleSep/(0.01*aTridem(j))) 0.5*pi atan(tandemAxleSep/(0.01*aTridem(j))) atan(tandemAxleSep/(aTridem(j)*0.01+0.10))];
    auxAlpha5 = [atan(-2*tandemAxleSep/dualWheelSep) atan(-tandemAxleSep/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(-tandemAxleSep/(dualWheelSep-0.01*aTridem(j))) atan(-tandemAxleSep/dualWheelSep) atan(-tandemAxleSep/(dualWheelSep+0.01*aTridem(j))) atan(-tandemAxleSep/(dualWheelSep+0.01*aTridem(j)+0.10))...    
        atan(-tandemAxleSep/dualWheelSep) atan(-tandemAxleSep*0.5/(0.75*dualWheelSep-0.5*0.01*aTridem(j))) atan(-tandemAxleSep*0.5/(dualWheelSep-0.01*aTridem(j))) atan(-tandemAxleSep*0.5/dualWheelSep) atan(-tandemAxleSep*0.5/(dualWheelSep+0.01*aTridem(j))) atan(-tandemAxleSep*0.5/(dualWheelSep+0.01*aTridem(j)+0.10))...
        0 0 0 0 0 0];
    auxAlpha6 = [pi+atan(2*tandemAxleSep/dualWheelSep) pi+atan(tandemAxleSep/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi+atan(tandemAxleSep/(0.01*aTridem(j))) -0.5*pi atan(-tandemAxleSep/(0.01*aTridem(j))) atan(-tandemAxleSep/(0.01*aTridem(j)+0.10))...
        pi+atan(tandemAxleSep/dualWheelSep) pi+atan(tandemAxleSep*0.5/(0.25*dualWheelSep+0.5*0.01*aTridem(j))) pi+atan(tandemAxleSep*0.5/(0.01*aTridem(j))) -0.5*pi atan(-tandemAxleSep*0.5/(0.01*aTridem(j))) atan(-tandemAxleSep*0.5/(aTridem(j)*0.01+0.10))...
        pi pi pi 0 0 0];
   %for the rotation calculations, extend auxAlpha1 and auxAlpha2 to the size of auxSigmaX1 and auxSigmaY2 (z x r)
    auxAlpha1 = ones(length(z),1)*auxAlpha1;
    auxAlpha2 = ones(length(z),1)*auxAlpha2;
    auxAlpha3 = ones(length(z),1)*auxAlpha3;
    auxAlpha4 = ones(length(z),1)*auxAlpha4;
    auxAlpha5 = ones(length(z),1)*auxAlpha5;
    auxAlpha6 = ones(length(z),1)*auxAlpha6;
    
    %get axle Load (tons) -  convert to load by wheel!
    %get load radius - - - - computed with wheelFootprint (called from the MainCode) - - IT'S GIVEN IN CM and accounts for the fact that the axle load is equally divided over all the axle's wheels!
    %get E, nu, height for all materials! - watchful for asphalt        %materials! 
     %%UPDATE 2019-02-19:: DON'T COMPUTE ANYTHING (AND KEEP ZEROS) IF THERE'S 0 TRAFFIC IN THIS CATEGORY.
      %%UPDATE 2019-03-19:: CONVERT LOAD TO NEWTON ( ton x 9800), DISTANCES TO METERS (cm x 0.01), AND E TO PA (psi x 1.000.000 / 145.04)
      %%%BUG DETECTED HERE!. Calling AxlesTandem18 instead of axlesTridem!
      if axlesTridem(k,j)~=0   %"if there's actual traffic of these axles"
            %update V2019-03-31:: pass pressure [qj] instead of total load to MLE_sigma.
            aj = 0.01*aTridem(j);
            qj = 1/12*9800*axlesTridemWeights(j)/(pi*(aj)^2);
            [auxSigmaZ1,auxSigmaR1,auxSigmaT1] = MLE_sigma(qj,aj,auxR1,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ2,auxSigmaR2,auxSigmaT2] = MLE_sigma(qj,aj,auxR2,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ3,auxSigmaR3,auxSigmaT3] = MLE_sigma(qj,aj,auxR3,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ4,auxSigmaR4,auxSigmaT4] = MLE_sigma(qj,aj,auxR4,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ5,auxSigmaR5,auxSigmaT5] = MLE_sigma(qj,aj,auxR5,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
            [auxSigmaZ6,auxSigmaR6,auxSigmaT6] = MLE_sigma(qj,aj,auxR6,z,0.01*paveDepths(1:end-1),layersE(:,j),layersv(:,j));
       else
           auxSigmaZ1 = zeros(length(z),nrTr);
           auxSigmaR1 = zeros(length(z),nrTr);
           auxSigmaT1 = zeros(length(z),nrTr);
           auxSigmaZ2 = zeros(length(z),nrTr);
           auxSigmaR2 = zeros(length(z),nrTr);
           auxSigmaT2 = zeros(length(z),nrTr);
           auxSigmaZ3 = zeros(length(z),nrTr);
           auxSigmaR3 = zeros(length(z),nrTr);
           auxSigmaT3 = zeros(length(z),nrTr);
           auxSigmaZ4 = zeros(length(z),nrTr);
           auxSigmaR4 = zeros(length(z),nrTr);
           auxSigmaT4 = zeros(length(z),nrTr);
           auxSigmaZ5 = zeros(length(z),nrTr);
           auxSigmaR5 = zeros(length(z),nrTr);
           auxSigmaT5 = zeros(length(z),nrTr);
           auxSigmaZ6 = zeros(length(z),nrTr);
           auxSigmaR6 = zeros(length(z),nrTr);
           auxSigmaT6 = zeros(length(z),nrTr);
    
       end
    sigmaZtridem(:,:,j,k) = auxSigmaZ1 + auxSigmaZ2 + auxSigmaZ3 + auxSigmaZ4 + auxSigmaZ5 + auxSigmaZ6;   %these sums here are the superposition of the sigmas of both wheels at each rSingle10 position

     %rotate the sigmaR and sigmaT to cartesian coordinates, sum them together
    auxSigmaX1 = auxSigmaR1.*(cos(auxAlpha1).^2) + auxSigmaT1.*(sin(auxAlpha1).^2);
    auxSigmaX2 = auxSigmaR2.*(cos(auxAlpha2).^2) + auxSigmaT2.*(sin(auxAlpha2).^2);
    auxSigmaX3 = auxSigmaR3.*(cos(auxAlpha3).^2) + auxSigmaT3.*(sin(auxAlpha3).^2);
    auxSigmaX4 = auxSigmaR4.*(cos(auxAlpha4).^2) + auxSigmaT4.*(sin(auxAlpha4).^2);
    auxSigmaX5 = auxSigmaR5.*(cos(auxAlpha5).^2) + auxSigmaT5.*(sin(auxAlpha5).^2);
    auxSigmaX6 = auxSigmaR6.*(cos(auxAlpha6).^2) + auxSigmaT6.*(sin(auxAlpha6).^2);
    auxSigmaY1 = auxSigmaR1.*(sin(auxAlpha1).^2) + auxSigmaT1.*(cos(auxAlpha1).^2);
    auxSigmaY2 = auxSigmaR2.*(sin(auxAlpha2).^2) + auxSigmaT2.*(cos(auxAlpha2).^2);
    auxSigmaY3 = auxSigmaR3.*(sin(auxAlpha3).^2) + auxSigmaT3.*(cos(auxAlpha3).^2);
    auxSigmaY4 = auxSigmaR4.*(sin(auxAlpha4).^2) + auxSigmaT4.*(cos(auxAlpha4).^2);
    auxSigmaY5 = auxSigmaR5.*(sin(auxAlpha5).^2) + auxSigmaT5.*(cos(auxAlpha5).^2);
    auxSigmaY6 = auxSigmaR6.*(sin(auxAlpha6).^2) + auxSigmaT6.*(cos(auxAlpha6).^2);
    auxTauXY1  = (auxSigmaR1 - auxSigmaT1).*sin(auxAlpha1).*cos(auxAlpha1);
    auxTauXY2  = (auxSigmaR2 - auxSigmaT2).*sin(auxAlpha2).*cos(auxAlpha2);
    auxTauXY3  = (auxSigmaR3 - auxSigmaT3).*sin(auxAlpha3).*cos(auxAlpha3);
    auxTauXY4  = (auxSigmaR4 - auxSigmaT4).*sin(auxAlpha4).*cos(auxAlpha4);
    auxTauXY5  = (auxSigmaR5 - auxSigmaT5).*sin(auxAlpha5).*cos(auxAlpha5);
    auxTauXY6  = (auxSigmaR6 - auxSigmaT6).*sin(auxAlpha6).*cos(auxAlpha6);

    %%update V2019-05-14: Add 4th dimension to sigmaXXXX
    sigmaXtridem(:,:,j,k) = auxSigmaX1 + auxSigmaX2 + auxSigmaX3 + auxSigmaX4 + auxSigmaX5 + auxSigmaX6; 
    sigmaYtridem(:,:,j,k) = auxSigmaY1 + auxSigmaY2 + auxSigmaY3 + auxSigmaY4 + auxSigmaY5 + auxSigmaY6;
    tauXYtridem(:,:,j,k) = auxTauXY1 + auxTauXY2 + auxTauXY3 + auxTauXY4 + auxTauXY5 + auxTauXY6;

    %create these auxiliar auxE and aux_Poisson variables with the E       %and v for this load level to use with the conversion to strain        %equations
    auxLayersE = getAuxEfromE(0.01*cumsum(paveDepths),z,layersE(:,j));   %%stretch to the z domain, will need it to superimpose the horizontal stresses  [although not needed in single and 6-ton axles...]
    auxLayersv = getAuxEfromE(0.01*cumsum(paveDepths),z,layersv(:,j));   
    %%these two above are in vector format [length(z) by 1]. need to convert
    %%them to z x r matrices. Multiply them for ones(1,length(r))
    auxLayersE = auxLayersE * ones(1,nrTr);
    auxLayersv = auxLayersv * ones(1,nrTr);

    %Convert stresses to strains (refer to Huang 04, chap 3)
    epsXtridem(:,:,j,k) = 1./auxLayersE.*(sigmaXtridem(:,:,j,k) - auxLayersv.*(sigmaYtridem(:,:,j,k) + sigmaZtridem(:,:,j,k)));
    epsYtridem(:,:,j,k) = 1./auxLayersE.*(sigmaYtridem(:,:,j,k) - auxLayersv.*(sigmaXtridem(:,:,j,k) + sigmaZtridem(:,:,j,k)));
    epsZtridem(:,:,j,k) = 1./auxLayersE.*(sigmaZtridem(:,:,j,k) - auxLayersv.*(sigmaXtridem(:,:,j,k) + sigmaYtridem(:,:,j,k)));
    gmXYtridem(:,:,j,k) = 2./auxLayersE.*(1+auxLayersv).*tauXYtridem(:,:,j,k);
    %update v2019-03-19:: corrected formula for epsH, missing a ^2
    epsHtridem(:,:,j,k) = 0.5.*(epsXtridem(:,:,j,k) + epsYtridem(:,:,j,k)) - sqrt(0.25.*(epsXtridem(:,:,j,k)-epsYtridem(:,:,j,k)).^2 + gmXYtridem(:,:,j,k).^2);
%   
end
%% --END OF SCRIPT
