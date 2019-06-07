function SWCC_matrix = kUnsatSWCC(SWCCparameters,verbose)
%function SWCC_matrix = kUnsatSWCC(SWCCparameters,verbose)
%auxiliary function to the infiltration module, it will calculate the
%hydraulic conductivity of the granular base layers using the SWCC
%(soil water char. curve --defined by Xi et al (1994) and adopted by the
%MEPDG--) and integrating it the way explained in Fredlund et al (1994).
%Inputs:: SWCCparameters, which contain
%       - Saturated vol. water content 
%       - Saturated hydr. conductivity of the granular layers (1st col)
%       -  SWCC parameters (refer to the MEPDG)  (cols 2::2nd)
%Each row of SWCCparameters is one layer%
%
%Outputs:: a 3-D matrix (each "level" is for a single granular layer),
%which will contain 3 columns: 
%       - the suction domain [0:1000 PSI converted to MPA] 
%       - the corresponding vol. moisture content(calculated with the SWCC curve), 
%       - the hydraulic conductivity for that unsaturated conditions (following Fredlund et al., 1994)
%
% V01- 2019-01-24
% V0 - 2018-10-18

%NOTE:: 1 MPA = 145.038PSI
%    :: water unit weight = 9800 N/m3 (1000kg/m3) 
%    :: kSat must be received in metric units [m/sec]

waterWeight = 9800;

 if verbose
%    disp('Materials Preprocessing:: Calculating hydraulic conductivity function for unsaturated conditions')
% no need to add this msg. line, it aklready splashes from the main code
 end
[numLayers,~] = size(SWCCparameters);
%%note: parameters' names according to MEPDG (Part 2 vol3)
humSat = SWCCparameters(:,1);  %saturated volumetric water content [%]
kSat   = SWCCparameters(:,2);  %saturated-state hydraulic conductivity [m/sec]
SWCCa  = SWCCparameters(:,3);  %parameter "a" for the SWCC curve [PSI]
SWCCb  = SWCCparameters(:,4);  %parameter "b" for the SWCC curve [adim]
SWCCc  = SWCCparameters(:,5);  %parameter "c" for the SWCC curve [adim]
SWCChr = SWCCparameters(:,6);  %parameter "hr" for the SWCC curve [PSI]

hPSI = 0:10:1000; %%Domain for suction pressure MPA (according to Fredlund et al. 1994)
hPSI = hPSI';     %%im reporting hPSI as a column!
m = length(hPSI);
SWCC_matrix = zeros(m,3,numLayers); %%for each level (layer), it must contain hPSI 
kUnsat = ones(m:1);%*kSat (remove the product);

%calculate the SWCC for each layer
%calculate the C(h) parameter of the SWCC
for k = 1:numLayers
    Ch_num = log(1+145.038*hPSI./SWCChr(k));   %log: NATURAL LOGARITHM. the 145.038 is unit conversion factor from MPA to PSI
    Ch_den = log(1+1000*145.038/SWCChr(k));
    Ch = 1-Ch_num/Ch_den;
    %calculate the SWCC (vol. water content (suction))
    SWCC = (log(exp(1)+(hPSI/SWCCa(k)).^SWCCb(k))).^-SWCCc(k);
    SWCC = Ch.*humSat(k).*SWCC;  %volumetric moisture content for a given suction pressure
    SWCC_matrix(:,1,k) = hPSI;     %the name may sound counter-intuitive, but I am outputting in MPA!
    SWCC_matrix(:,2,k) = SWCC;
    %now calculate the unSat hydraulic conductivity - use a for loop, cause
    %the equation looks somehow convoluted.
    %suctionHead2 = (hPSI.^2)/145.038/waterWeight; %get the suction Head [m] squared, but with some minor unit inconsistency (no worries, in future calculations all the unit errors cancel themselves out)
    %%BUG DETECTED 2019-01-23 - unit errors in suctionHead2: hPSI is in MPA
    %%(despite the name). no need to divide by 145.038. Actually, Fred&Xi '94 (eqn 7) don't convert hPSI to head. Removing conversion!
    %%update 2019-01-24:: corrected iteration below, wrong term in initialization of auxNum!
    suctionHead2 = hPSI.^2;
    for i = m:-1:1
        %first term of the sumation [eqn 7 in F&Xi '94 (j = m)
        auxNum=1/suctionHead2(m)*(2*(m-i)+1);
        auxDen=1/suctionHead2(m)*(2*m-1);
        if i<m  %i don't want this for loop to run in the last iteration (no terms to add to the auxNum and auxDen values)
            for j = m-1:-1:i+1
                auxNum = auxNum + (1/suctionHead2(j)*(1+2*j-2*i));
                auxDen = auxDen + (1/suctionHead2(j)*(-1+2*j));
            end
        end
       kUnsat(i) = kSat(k)*auxNum/auxDen;
    end
    SWCC_matrix(:,3,k) = kUnsat; 
    %and then reset kUnsat
    kUnsat = ones(m,1);
end

end  %endfunction

