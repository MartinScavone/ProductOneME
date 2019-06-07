function [timeLoad,wLoad] = HMALoadFrequency(HMALyrsDepth,axleSpeed,radiusAxle,HMAModulus,SubGradeMR)
%function [timeLoad,wLoad] = HMALoadFrequency(HMALyrsDepth,axleSpeed,aAxle)
%Auxiliary function that calculates the time and (angular) frequency of
%load for the passage of a certain type of axle
%%Time of load is calculated from the 45deg/midlayer methodology used by the MEPDG (reported by AlQadi et al. 2008....)
%%for each layer  (assuming that the method is valid for both single axles and tandem-tridem axles)
%Assuming frequency of load is angular (see Huang 04, chap 7), reported by AlQadi et al. (2008) as being more appropriate
%than the linear frequency
%
%V1.0 of function - 2018-06-26
%V2.0  - 2019-02-17
%Changelog: Bug corrected in leff formula, it was not considering the Odemark's effective depth approach (conver)
%Initialize variables  
%
%
%INPUT: HMALyrsDepth:: Vector containing the depths of each HMA layer      [cm]
%       axleSpeed      <Single Value>: the speed at which the axle passes  [km/h]
%       radiusAxle     <Vector>      : equivalent circular footprint radius for different weights of the referred axle type [cm]
%		HMAModulus     <vector>		 : vector of HMA elastic moduli  (I need at least a preliminary value (set at ambient temperature shortly after placement) for the effective length computations [PSI]
%       SubGradeMR	   <Single value>: resilient modulus of the subgrade (for calculation purposes, take only the saturated state - acknowleedging it's a major simplification) [PSI]
%%
%%Note: this code won't treat differently the single/tandem/tridem axles
%
%OUTPUT: timeLoad: matrix containing the time of load application (seconds) for each radiusAxle value on each HMA layer
         %size:  [nr. of hma layers x radiusAxle size]
         %wLoad: vector containing the angular frequency for each timeload value  
         %w = 1/(2*pi*timeLoad)

nHMAL = length(HMALyrsDepth);
nAxles = length(radiusAxle);

%1 calculate timeLoad for each layer 
%First: calculate "effective DEPTH" <Zeff> for each layer. Using the Odemark methodology
%(Refer to MEPDG APP CC3 for equations)\
z    = zeros(nHMAL,1);
zeff = zeros(nHMAL,1);
%moduliRatio (to compute zeff)
moduliRatio = zeros(nHMAL,1);
moduliRatio = (HMAModulus./SubGradeMR).^(1/3);  %%refer to MEPDG, appendix CC, equation 5

%compute zeff for mid-layer positions (MEPDG, appendix CC3, eqn 7)    [zeff is calculated in cm here!!!]
zeff(1) = 0.5*HMALyrsDepth(1)*moduliRatio(1);
z(1)    = 0.5*HMALyrsDepth(1); 
for i = 2:nHMAL
  %solve each value of zeff
  z(i)    = 0.5*HMALyrsDepth(i) + sum(HMALyrsDepth(1:i-1));
  zeff(i) = 0.5*HMALyrsDepth(i)*moduliRatio(i) + sum(HMALyrsDepth(1:i-1).*moduliRatio(1,i-1));
end
%calculate "effective length" <leff> for each layer. (Refer to MPEDG APPENDIX CC3 for detailed equation)
%MAJOR SIMPLIFICATION HERE: ASSUMING A SINGLE EQUATION FOR ALL AXLE TYPES (theoretical dev. exists for treating each axle type spearately but the outcome wouldn't change significatively - ref. MEPDG App. CC3)

leff = zeros(nHMAL,nAxles);
%solve one column at a time
for j = 1:nAxles
	leff(:,j) = 2.*(radiusAxle(j) + zeff);    %%equation 9 (single-axle case) in Appendix CC3, valid for multi-axles too.
end

%Then calculate the time of passage (leff and timeLoad are the same size)
%>>>>got to convert leff to inches and axleSpeed to mph to properly use the formula

% timeLoad = zeros(nHMAL,nAxles);
% wLoad = zeros(nHMAL,nAxles);
timeLoad = (leff./2.54)./(17.6*axleSpeed/1.6);  

%2 finally calculate wLoad

wLoad = 1./(timeLoad);
%add the correction factors suggested by AlQadi et al (2008) - go by column in wLoad!!
CorrFactor = 0.03.*z + 0.2333;   %%Interstate-lvl equation by the authors for avg. correction factors. Conveniently tweaked to receive z in cm!
for j = 1:nAxles
	wLoad(:,j) = CorrFactor.*wLoad(:,j);
end

end  %endfunction

