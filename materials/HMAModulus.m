function E = HMAModulus(HMAtemperature,HMAparameters,HMAFrequency,inputLevel,verbose)
%function E = HMAModulus(HMAtemperature,HMAparameters,HMAFrequency,inputLevel,verbose)
%
%Auxiliary function that will calculate the HMA mix dynamic modulus off mix
%or binder properties (according to level of input)
%INTERIM VERSION - It will calculate the Dynamic modulus of the HMA mixes using the Asphalt Institute (1979) formulas
%(refer to Huang '04, chap 7). Same methodology for the three levels of input.
%INPUT:  HMAtemperature: vector containing the predicted temperature series of each HMA layer during the design period [in C]
 %       HMAparameters:  matrix containing, for each HMA layer, P200 <percentage of fines passing #200 mesh>, Va <volume of air voids>,  
        %Vb <effective bitumen volume content %>, P25c <penetration at 25 deg. C>
         %HMAFrequency
         %inputLevel
         %verbose: boolean variable (1 = report on screen progress of calculations / 0 = run silently)
%OUTPUT: E = 3D array matrix (each layer size number of HMA layers x length of load applications) with the E* value for each temperature (timestamp) value.  [PSI]
%(1 PSI = 6.9 kPa)


%methodology would vary across levels of input <interim version will only
%have lvl2 case (calculation of E from values pulled from local material library>
switch inputLevel
    case 1  %% Level of input 1: Master curve to be defined from lab testing (Ref: NCHRP 1-28A Vol II report -Wictzak, 2003))
        %interim version -  Level of input 1: same case as input level 2 - call recursively
        E = HMAModulus(HMAtemperature,HMAparameters,HMAFrequency,2,verbose);  
    case 2  %% Level of input 2: Master curve to be defined from material properties (NCHRP 1-37A #2 & App. CC)
        %WARNING: HMATemperature matrix has the temperature of each layer
        %PLUS the temperature at the surface of the pavement. Peel off 1st
        %column before starting the routine!!!!!
        HMAtemperature = HMAtemperature(:,2:end);
        
        [nTemp,nHMA] = size(HMAtemperature);  %should be timestamp x number of HMA layers  (length will give me the largest of both (timestamp))
        [nFreqs] = length(HMAFrequency);      %size of the load frequency matrix is [number of layers / frequencies]
        E = -1*ones(nHMA,nFreqs,nTemp);        %initalize E, each stack is the E* for all the asphalt layers on different timestamps 
        P200 = HMAparameters(:,1);
        Va = HMAparameters(:,2);
        Vb = HMAparameters(:,3);
        P25c = HMAparameters(:,4);
        
        
        for k = 1:nTemp %open the loop to go over all the temperature values (along all timestamps)
            if verbose
                 if round(k/1000) == (k/1000)
                     fprintf(' \t HMA E* calculation completed %g percent \n',k/nTemp*100);
                 end
            end
            %solve E* with the Asphalt Institute (1979) equations for each  temperature(timestamp) value
            
            lambda = 29508.2*P25c.^-2.1929.*ones(size(HMAFrequency)); %matrix the same size as HMAFrequency
            tempK = HMAtemperature(k,:).*1.8 + 32;     %before running convert HMA temperature from deg. C to F!!!! 
            tempK = tempK' .*ones(size(HMAFrequency)); %matrix the same size as HMAFrequency
            beta5 = 1.3+0.49825*log10(HMAFrequency);   %matrix the same size as HMAFrequency
            beta4 = 0.483*Vb.*ones(size(HMAFrequency));%matrix the same size as HMAFrequency
            beta3 = 0.533833 + 0.028829*((P200.*ones(size(HMAFrequency))).*HMAFrequency.^-0.1703) - 0.03476.*Va.*ones(size(HMAFrequency)) + 0.070377*lambda + 0.931757.*HMAFrequency.^-0.02774;
            beta2 = sqrt(beta4).*(tempK).^beta5;
            beta1 = beta3 + 0.000005*beta2-0.00189*beta2.*HMAFrequency.^-1.1;
            E(:,:,k) = 100000*(10.^beta1);  %Modulus in PSI!
        end                
    case 3  %% Level of input 3: same case as input level 2 - call recursively
       E = HMAModulus(HMAtemperature,HMAparameters,HMAFrequency,2,verbose);
    otherwise
        error('HMA Master Curve Calculator error:: Level of input not supported')  %this error should never pop up (
end

end %endfunction


    
