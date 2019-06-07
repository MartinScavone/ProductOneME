%% PRODUCT-ONE PAVEMENT DESIGN TOOL
%FRONT END CODE FOR THE DISTRESS CALCULATIONS
%
%This script will direct the calls to auxiliary functions to compute the
%intended distresses over the pavement structure for each time moment, each
%level of load and each axle type
% 
%
%V0.1 2019-04-04: 
%Changelog: Corrected rut depth term, that was in milimiters (while rut depth was returning from the rutDepthCompute in meters)
%V0.0 2019-03-04
%Feature: Replaced default MEPDG's formula for HMA on unbound base IRI. [eqn 3.3.74 and branches]
%with simplified expression featured in newer MEPDg implementations (in AASHTO 2015; Garber & Hoel XXX)

%%code begins
%% compute climate variables for site factor.
%if already exist (i computed them on a previous loop), do not calculate
if ~exist('tempFI','var') 
    [rainStDev,rainAvg,tempFI] = IRIclimateSiteFactor(longTimestamp,rainFall,airTemp);
    %climateSateFactor gives rainAVG and rainStDev in mm, tempFI in degC-days 
else
   %do nothing
end

%% COMPUTE IRI
%part A) Site Factor
%use the simplified AASHTO (2008) formula instead of the newest v2015
%[doesn't need the P02 of the subgrade soil, which is hardly ever reported in sieving results]
paveAge = (1/365)*(shortTimestamp(k)-shortTimestamp(1));  %age of the pavement, in years
% subGrPI  = granPI(end);      %% PLASTICITY INDEX OF THE SUBGRADE
% subGrP200= granP200(end);    %% P200 of the subgrade.
SF = 0.02003*(1+granPI(end))+0.007947*(1+rainAvg/25.4)+0.000636*(1+tempFI*9/5+32);
SF = paveAge*SF;

% topDownCracking is received in m/km. Convert to length in ft/mi!!!. 
%<rutDepth is received in mm - convert to inches!
IRI(k) = initialIRI*1.61/0.0254 + 0.0150*SF+0.400*alligatorCrack(k,1) + 0.400*topDownCrack(k,1)*1.61/0.305*1 + 0.0080*0 + 40.0*rutDepth(k,end)/0.0254;
%THE EQUATION ABOVE GIVES IRI(k) in inches/mile; CONVERT UNITS to m/km

IRI(k) = IRI(k)*0.0254/1.61;   %convert value from in/mi to m/km


%% compute PSI(IRI). Use Al-Omari and Darter's (1992/4?) formula
PSI(k) = 5.00*exp(-0.26*IRI(k));%IRI assumed to be here in m/km.
