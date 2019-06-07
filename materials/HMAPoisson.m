function nu = HMAPoisson(Edyn,inputLevel,verbose)
%function nu = HMAPoisson(Edyn,HMAparameters,inputLevel)
%
%Auxiliary function that will calculate the HMA mix poisson ratio according to level of input
%INTERIM VERSION - Using only Level 2 equation from the MEPDG guide with default fitting values (P2C2, eq. 2.2.24)
%INPUT:  EDyn: 3-D arrange containing the dynamic modulus  E* of all
%the HMA layers under different load freqs. over time.
%OUTPUT: nu = 3D array matrix (each layer size timestamp x number of HMA layers) with the Poisson coefficient for each HMA layer at each simulated temp and load condition, as calculated in Edyn



%methodology would vary across levels of input <interim version will only
%have lvl2 case (calculation of E from values pulled from local material library>
switch inputLevel
    case 1  %% Level of input 1: Master curve to be defined from lab testing (Ref: NCHRP 1-28A Vol II report -Wictzak, 2003))
        %interim version -  Level of input 1: same case as input level 2 - call recursively
        nu = HMAPoisson(Edyn,2,verbose);  
    case 2  %% Level of input 2: Master curve to be defined from material properties (NCHRP 1-37A #2, eqn 2.2.24 )
        nu = zeros(size(Edyn));
        nu = 0.15 + 0.35./(1+exp(-1.63+3.84E-6.*Edyn));
    case 3  %% Level of input 3: same case as input level 2 - call recursively
       nu = HMAPoisson(Edyn,2,verbose);
    otherwise
        error('HMA Poisson coefficient calculator error:: Level of input not supported')  %this error should never pop up (
end

end %endfunction


    