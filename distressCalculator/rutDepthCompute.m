 function [rutDepthHMALayers,rutDepthGranLayers,rutDepthSubGrade,eplHMA,eplGran,eplSG] = rutDepthCompute(MLEstrain,axlePasses,z,layerDepth,asphTemp,granMoisture,granDensity,eplHMAPrev,eplGranPrev,eplSGPrev)
%function [rutDepthHMALayers,rutDepthGranLayers,rutDepthSubGrade,eplHMa,eplGran,eplSG] = rutDepthCompute(MLEstrain,axlePasses,z,layerDepth,asphTemp,granMoisture,granDensity,eplHMAPrev,eplGranPrev,eplSGPrev)
%
%compute the vertical deformation (rutting) on each layer and over the
%entire structure for the strain produced by a certain axle type (thus
%load- and axle-type-related) for each single moment in time shortTimestamp(k), 
%
%Use MEPDG's original equations(eqns. 3.3.10 and so on). See Pt3 Chapter 3 of NCHRP 2004.
%
%Inputs
% MLEstrain,   vertical strains as computed in the MLE module [VECTOR!]
% axlePasses,  number of axle passes (of a given axle type and load level) in the period of interest [scalar]
% z            vector of depths tied to MLEStrain     [m]
% layerDepth   vector stating the depth of all pavement layers [cm]
% asphTemp:    temperature at each of the HMA layers [C]. DON'T PASS the surface temperature!
% granMoisture volumetric moisture content of the granular layers [as received from the infiltration module (PERCENTAGE), CONVERTED TO RATIO HERE]
% granDensity  granular materials' density [in g/cm3] (which is equal (in number value) to their bulk unit weight)
% eplHMAprev   plastic strain at the asphalt layers due to the input axle type and load computed in previous iteration (if first iteration = -9999)
% eplGranPrev  plastic strain at the granular layers due to the input axle type and load computed in previous iteration (if first iteration = -9999)
% eplGranSG    plastic strain at the subgrade due to the input axle type and load computed in previous iteration (if first iteration = -9999)
% 
%Outputs
% rutDepthHMALayers   = HMA layers only rut depth [m] - COLUMN VECTOR FORMAT!
% rutDepthGranLayers  = rut depth in the granular aggregate layers [m] -  COLUMN VECTOR FORMAT
% rutDepthSubGrade    = rut depth in the subgrade [m] - COLUMN VECTOR FORMAT
% eplHMA              = plastic deformation in the asphalt layers (same format as rutDepthHMALayers)
% eplGran             = plastic deformation in the granular layers (same format as rutDepthHMALayers)
% eplSG               = plastic deformation in the subgrade (same format as rutDepthHMALayers)%
% 
%THIS IS THE "UNCALLIBRATED" VERSION OF THE RUTTING MODEL, THE EQUATIONS
%WERE PROGRAMMED HEREIN AS THEY HAVE BEEN REPORTED IN THE MEPDG GUIDE.
%THE CALLIBRATION EFFORT MAY EVENTUALLY LEAD TO RE-WRITING THIS COMPUTER CODE!
%
%V0.8 - 2021-03-11
%   Changelog: Corrected the search for auxPosZ (it was going out of
%   tolerance and thus returning nothing and crashing the code).
%v0.7 - 2019-05-21
%   Changelog: stability correction for granular materials and subgrade: At
%   times the epl/ez ratio to compute Neq gives an impossible Neq number
%   [the Log(epl/(b1*ez*eoer) becomes >1 and then crashes into CMPLx].
%   These translate to moments in which no increase in Epl occurs. FORCE
%   SUCH CASES TO EPL = EPL_PREV
%   Also, major cleanup to the unbound-materials calculators.
%V0.6 - 2019-05-20
%   Changelog: bug detected on SubGrade epl prediction (missing 1.35 factor added)
%V0.5 - 2019-05-09
    %Changelog: use absolute value of strain in the Epl equations to
    %prevent them from going to the Cmplx dimension. Revert with signum
    %function once calculation completed to assign proper sign to rut depth
%V0.4 - 2019-04-03
    %Changelog: Added missing term 10^-3.4488 and exponent to temperature
    %temp in HMA plastic def. equation
%V0.3 - Delayed April's fools 2019-04-02:
    % *Changelog: Corrected calculation of eplPlastic for subgrade and unbound materials: when traffic = 0
    %it will hit a division by 0 and return NaN. Force a 0 deflection in such cases
    %**Corrected the expression for rut depth in granular and sub-grade soils,
    %it was falling to the Complex numbers (having a negative base powered to a <1 exponent)
    %**Corrected expression to compute (eps0/epsR) for granular and
    %subgrade - use that of Appendix GG in MEPDG guide (remove the log10
    %relationship, which was causing overly huge deformation values)...
%V0.2 - StPatrick's Hangover. 2019-03-18: Stability update added to Neq
%calculations when no strain occured on the previous iteration (assume 0 passes)
%V0.1 - StPatrick's day. 2019-03-17
%%changelog: programmed "strain hardening?" methodology to compute the
%%amount of plastic strain and number of passes, as stated in the 1-37A, P3C3
% - Cached content will be retrieved upon each call
%V0.0 - Valentine's day. 2019-02-14


%% Certical deformation in the HMA layers
%rutDepthHMALayers = zeros(length(asphTemp),1); 
%initialize the vector for rutDepthHMALayers  [Matlab suggests against doing so, that's why I commented this line]

layerDepthHMA = layerDepth(1:length(asphTemp));
layerDepthHMA = layerDepthHMA/2.54;         %convert the vector of layer depths from cm. to inches.
auxTotalDepthHMA = sum(layerDepthHMA);      %get the total depth of the HMA layers, inch

%locate the midDepth positions in "z" that correspond to the HMA layers midpoints
midpointsHMA = zeros(length(layerDepthHMA),1);
auxPosZ = zeros(length(layerDepthHMA),1);
for i = 1:length(layerDepthHMA)
    if i ==1
        midpointsHMA(i) = 0.5*layerDepthHMA(1);
    else
        midpointsHMA(i) = sum(layerDepthHMA(1:i-1))+0.5*layerDepthHMA(i);  
    end
    aux                 = find(abs(z-midpointsHMA(i)*0.0254)== min(abs(z-midpointsHMA(i)*0.0254)));
    aux = aux(1);
    if ~isempty(aux)
        auxPosZ(i)      = aux;
    end
end

strainHMA = MLEstrain(auxPosZ);   %get the strain values where z is a midpoint of the HMA layers (remember that z is in meters and midpointsHMA in inches!!)

asphTemp = asphTemp*18/10+32;               %convert the HMA temperature vector from deg. C to deg F for calculation purposes.
asphTemp = asphTemp(:);
C1 = -0.1039*auxTotalDepthHMA^2+2.4868*auxTotalDepthHMA-17.342;
C2 =  0.0172*auxTotalDepthHMA^2-1.7331*auxTotalDepthHMA+27.428;
k1z = (C1 + C2.*midpointsHMA).*0.328196.^midpointsHMA;

%update v2019-03-17:: get the Neq (equivalent number of passes of the previous season)
if eplHMAPrev(1) ~= -9999
    %%%the -9999 case is reserved for case timestamp (k = 1), casue there's no previous iteration.
    %%update V2019-03-18 (Stability update) -> force if strain = 0, Neq = 0
    %%update V2019-04-03 Added missing exponent in asphTemp  and 10^3.4488 term here below!
    if strainHMA(1) ~= 0
%         Neq = (10^3.4488).*(eplHMAPrev./strainHMA).*(1./k1z).*(asphTemp.^-1.5606);
        Neq = (10^3.4488).*(abs(eplHMAPrev)./abs(strainHMA)).*(1./k1z).*(asphTemp.^-1.5606);  %%update V0.5 - use absolue vaules in this equation to prevent cmplx. Neq values (all variables must be positive before being raised at the 1/whatever.
        Neq = Neq.^(1/0.479244);
    else
        Neq = 0*ones(size(strainHMA));
    end
else
    Neq = 0*ones(size(strainHMA));
end
%update v2019-03-17:: correct the axle passes by summing the N_equivalent
%from previous iteration (if apply)
%Update V2019-04-02:
%   add this just in case (prevent a negative Neq from entering there and eventually taking eplHMA into the Cmplx plane...
if Neq >0
    axlePassesHMA = axlePasses + Neq;
else
    axlePassesHMA = axlePasses;
end

eplHMA = abs(strainHMA).*k1z.*10^(-3.4488).*asphTemp.^1.5606.*axlePassesHMA.^0.479244;  %%%this is the equation to obtain the plastic deformation at each HMA layer
eplHMA = eplHMA.*sign(strainHMA); %<<update V0.5: compute epl with absolute value and assign sign with te signum function.
auxRutDepthHMA = layerDepthHMA.*eplHMA;        %get a vector with each terms of the Permanent Def. equation [inches]
rutDepthHMALayers = 0.0254*auxRutDepthHMA;     %pass all the Permanent deformation terms. Convert from Inches back to meters!!

%% vertical deformation in granular layers
layerDepthGranular = layerDepth(length(asphTemp)+1:end-1)/2.54;   %get the depth of the granular layers, convert it to inches
%get the strain at each layer's midpoint!. Use same methodology than for the HMA layers to locate the midpoints

midpointsGranular = zeros(length(layerDepth)-1-length(layerDepthHMA),1);
auxPosZ = zeros(length(layerDepth)-1-length(layerDepthHMA),1);

for i = 1:length(layerDepthGranular)
    if i == 1
        midpointsGranular(1) = 0.5*layerDepthGranular(i) + auxTotalDepthHMA;  %depth of the midpoint of the 1st granular layer [inches]
    else
       midpointsGranular(i) = auxTotalDepthHMA + sum(layerDepthGranular(1:i-1)) + 0.5*layerDepthGranular(i);    
    end
    aux                 = find(abs(z-midpointsHMA(i)*0.0254)== min(abs(z-midpointsHMA(i)*0.0254)));
    aux = aux(1);
    if ~isempty(aux)
        auxPosZ(i)      = aux;
    end
end
%%%I NEED TO RETRIEVE THE MID/LYR MLE_strain for the Gran layers!
strainGranular = MLEstrain(auxPosZ);   %get the strain values where z is a midpoint of the granular layers (remember that z is in meters and midpointsHMA in inches!!)
% strainGranular = strainGranular(:);

%IMPORTANT:::  granMoisture must be converted back to moisture by weight to be used in beta!!! (though the MEPDG guide doesn't state that it's by weight, REFER TO FHWA, 2006).
%BUT I'M REPLACING THE ORIGINALLY GIVEN EQUATION (cause it won't account for moisture variations due to infiltration, only the ground water table depth)
%%conversion to moisture by weight 
betaGran = 10.^(-0.61119-0.017638.*granMoisture(1:end-1)'.*1.00.*(granDensity(1:end-1)).^-1) ;              %%Eq 3.3.10.a. Converting moisture content in % volume to weight [need to divide by material's bulk gravity]
betaGran = betaGran(:);
%use the MEPDG globally-callibrated formula to compute rutting depth in each layer
CoGranular   = log(0.15/20);                                                                     %%Eq 3.3.10c after simplification [no extra cal. factors]   NATURAL LOGARITHM!!!!
rhoGranular  = CoGranular./(1-(10^9).^betaGran);
rhoGranular  = rhoGranular.^(1./betaGran);
rhoGranular  = 10^9 .*rhoGranular;                                                              %%as per eq. 3.3.10c
eoer         = 0.5.*(0.15.*exp(rhoGranular.^betaGran) + 20.*exp((rhoGranular.*10^-9).^betaGran));  %%as per eq. 3.3.10b
% eoer         = 10.^eoer;

%update V2019-03-17 get the Neq (equivalent number of passes of the previous season)
%update v2019-05-20: Added the abs(eplSGPrev>0) condition for stability, if not i'd get a Neq becoming Nan (log(0))
if eplGranPrev(1) == -9999 
    %%%the -9999 case is reserved for case timestamp (k = 1), casue there's no previous iteration.
    Neq = 0* ones(size(eplGranPrev));
    axlePassesGran = axlePasses+Neq;
    eplGran = 1.673.*strainGranular.*eoer.*exp(-1*((rhoGranular./axlePassesGran).^betaGran));   %equation 3.3.11. giving the rut depth in each layer in INCHES!
       
else %case eplGranPrev(1) >0 (must do strain hardening to get neq and compute epl)
    %update v2019-03-17:: correct the axle passes by summing the N_equivalent from previous iteration (if apply)
    %update V2019-04-02:: Corrected exp(-1(rho/N)^b). Previously I had the -1 inside the term to be powered up, that was going to the Cmplx plane...
    %%UPDATE V2019-05-21 - STABILITY UPDATE: Force that if log(xxxx) [below] is <1. if log(xxx) is > 1, epl gran = eplGranPrev.! MUST HAVE TO FORCE THIS FOR EACH LAYER IN THE SUBGRADE
    Neq = zeros(size(betaGran));
    axlePassesGran = axlePasses+Neq;
    eplGran = eplGranPrev;
    
    for nn = 1:length(betaGran)  %must treat the granular layers separately for the stability condition.        
        if  (eplGranPrev(nn)/(1.673*eoer(nn)*abs(strainGranular(nn))))<1   %%stability condition! When this doesn't hold, Neq goes to the cmplx plane.  
            Neq(nn) = -1*log(eplGranPrev(nn)./(1.673*eoer(nn).*abs(strainGranular(nn))));   %%update v0.5: use abs. value of eplGranPrev and strainGranular to prevent weird negatives from appearing
            Neq(nn) = Neq(nn).^(-1./betaGran(nn));
            Neq(nn) = rhoGranular(nn).*Neq(nn);
            axlePassesGran(nn) = axlePasses+Neq(nn);
            eplGran(nn) = 1.673*strainGranular(nn)*eoer(nn)*exp(-1*((rhoGranular(nn)/axlePassesGran(nn))^betaGran(nn)));   %equation 3.3.11. giving the rut depth in each layer in INCHES!
        else
            %stability condition doesn't hold. In this timestamp, no increase in plastic strain occurs. force plastic strain to match the previous value
            eplGran(nn) = eplGranPrev(nn);          
        end  
    end %%by now I should get the eplGran for all granular layers properly calculated.
end
auxRutDepthGranular = eplGran.*layerDepthGranular;
rutDepthGranLayers  = 0.0254*auxRutDepthGranular;  %pass them all, convert to meters

%% vertical deformation in the Subgrade - use the MEPDG approach for integrating the exp. decaying rutting over infinite depth [equations 3.3.60-3.3.62]

%get the eo/er parameter
% strainSubGrade = MLEstrain;
strainSubGrade = MLEstrain(end-1:end);  %two last values in the strain vector, correspond to top-most level of subgrade and 15cm underneath the surface.
%rutDepthSubGrade requires the deformation at the subgrade start and 15cm underneath for calculation!
betaSubgrade = 10.^(-0.61119-0.017638.*(granMoisture(end)./granDensity(end)));             %https://en.wikipedia.org/wiki/Water_content  Converting moisture content in % volume to weight [need to divide by material's bulk gravity]

%use the MEPDG globally-callibrated formula to compute rutting depth in each layer
CoSubgrade   = log(0.15/20);                             %%Eq 3.3.10c after simplification
rhoSubgrade  = CoSubgrade./(1-(10^9).^betaSubgrade);
rhoSubgrade  = (rhoSubgrade).^(1./betaSubgrade);         %%as per eq. 3.3.10c
rhoSubgrade  = 10^9 .* rhoSubgrade;
eoer         = 0.5.*(0.15.*exp(rhoSubgrade.^betaSubgrade) + 20.*exp((rhoSubgrade.*10^-9).^betaSubgrade));     %%as per eq. 3.3.10b
% eoer         = 10.^eoer;
%%update V2019-03-17 get the Neq (equivalent number of passes of the previous season)
%%update v2019-05-20: ADDED A MISSING 1/1.35. Also added the abs(eplSGPrev>0) condition for stability, if not i'd get a Neq becoming Nan (log(0))

if(eplSGPrev(1) == -9999)
    %%first timestamp iteration case. No Neq. computation. Do the calculations straightforward
    Neq = zeros(size(strainSubGrade));
    axlePassesSG = axlePasses+Neq;
    auxRutSubgrade = 1.35*strainSubGrade.*eoer.*exp(-1*((rhoSubgrade./axlePassesSG).^betaSubgrade));   %equation 3.3.19. giving the rut depth in each layer in INCHES!
    %% BUG-PREVENTION. IF auxRutSubgrade == 0; force kappaCoeff to 1 (because if not I'll get a log of 0 [-inf]
    %6 comes for 6 inches, and auxRutSubgrade(2) has been computed 6 inches below the surface of the subgrade.
    if auxRutSubgrade(1) ~= 0
        kappaCoeff = 1/6.*log(auxRutSubgrade(1)/auxRutSubgrade(2));  %unit = [1/in]
    else
        kappaCoeff = 1;
    end
    eplSG = auxRutSubgrade(1);
    rutDepthSubGrade = eplSG.*(1/kappaCoeff).*(1-exp(-kappaCoeff*(layerDepth(end))/2.54));   %%eqn. 3.3.23
    rutDepthSubGrade = 0.0254*rutDepthSubGrade;
else
    %case eplGranPrev(1) >0 (must do strain hardening to get neq and compute epl)
    %update v2019-03-17:: correct the axle passes by summing the N_equivalent from previous iteration (if apply)
    %update V2019-04-02:: Corrected exp(-1(rho/N)^b). Previously I had the -1 inside the term to be powered up, that was going to the Cmplx plane...
    %%UPDATE V2019-05-21 - STABILITY UPDATE: Force that if log(xxxx) [below] is <1. if log(xxx) is > 1, epl gran = eplGranPrev.! MUST HAVE TO FORCE THIS FOR EACH LAYER IN THE SUBGRADE
    
    if (eplSGPrev/(1.35*eoer(1)*strainSubGrade(1)))<1   %%stability condition! When this doesn't hold, Neq goes to the cmplx plane. 
       Neq = -log((1/1.35)*abs(eplSGPrev)./(eoer(1).*strainSubGrade(1)));
       Neq = Neq.^(-1/betaSubgrade(1));
       Neq = rhoSubgrade(1).*Neq;
       axlePassesSG = axlePasses+Neq;
       
       auxRutSubgrade = 1.35*strainSubGrade.*eoer.*exp(-1*((rhoSubgrade./axlePassesSG).^betaSubgrade));   %equation 3.3.19. giving the rut depth in each layer in INCHES!
       if auxRutSubgrade(1) ~= 0
           kappaCoeff = 1/6.*log(auxRutSubgrade(1)/auxRutSubgrade(2));  %unit = [1/in]
       else
           kappaCoeff = 1;
       end
       eplSG = auxRutSubgrade(1);
       rutDepthSubGrade = eplSG.*(1/kappaCoeff).*(1-exp(-kappaCoeff*(layerDepth(end))/2.54));   %%eqn. 3.3.23
       rutDepthSubGrade = 0.0254*rutDepthSubGrade;
        
    else        
         %stability condition doesn't hold. In this timestamp, no increase in plastic strain occurs. force plastic strain to match the previous value and a kappa of 1 just to say sth.
         eplSG = eplSGPrev;
         kappaCoeff = 1;
         rutDepthSubGrade = eplSG.*(1/kappaCoeff).*(1-exp(-kappaCoeff*(layerDepth(end))/2.54));   %%eqn. 3.3.23
         rutDepthSubGrade = 0.0254*rutDepthSubGrade;        
    end        
end   %%this completes all cases for the subgrade.
   

end