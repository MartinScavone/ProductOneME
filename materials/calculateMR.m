function MRactual = calculateMR(materialID,moistureContent,MROpt,OptSaturation,OptMoisture)
%function MRactual = calculateMR(materialID,moistureContent,MRSat,OptSaturation,OptMoisture)
%
%% -- GRANULAR LAYERS AND SUBGRADE UNSAT MR MODULE
%
%INPUT: 
%materialID: column vector stating for each granular layer its ID (to check
%if it's fine or coarse)
%MROpt    : column vector stating for each granular layer and the sub-grade what is its MR in optimum compaction conditions [PSI by default]. 
%moistureContent: vector (row format) containing the percent moisture
%content (by volume!!) of each granular layer and the MR
%
%OUTPUT: MRactual: row vector (to be pasted in the Main Code) with the
%actual resilient Moduli for each layer, matching the actual moisture
%content
%
%METHODOLOGY: USE Witczak's formula (in 1-37A //app. DD; also mentioned by Bilodeau & Dore, 2011)
%
%%ASSUMPTIONS:
%a) separate parameter values for fine [M and C families in SUCS] and coarse [S and G families] soils and base materials
%b) use default calibration values only (refer to 1-37A, appendix DD-1)
%V 0.1 Spring semester 2019-01-22.
%V 0.0 Summer solstice 2018-12-22.

%% - code begins

%1 - set the equation's parameters for each material family (separately if
%these are fine [C, M] or coarse [S, G]
p  = zeros(length(MROpt),1);
q  = zeros(length(MROpt),1);
b  = zeros(length(MROpt),1);
ks = zeros(length(MROpt),1);

for i = 1:length(materialID)
    if materialID(i) > 150
        %coarse materials  (ID > 150)
        p(i) = -0.3123;
        q(i) = 0.3;
        ks(i) = 6.8157;
    else
        %fine materials (ID < 150)
        p(i) = -0.5934;
        q(i) = 0.4;
        ks(i) = 6.1324;        
    end
    b(i) = log(-p(i)/q(i));   %%NATURAL (e-based) logarithm. by definition
end

%2 - get saturation values for the materials' current mositure rate
saturation = moistureContent.*(OptSaturation./OptMoisture);

%3 - calculate the material's resilient modulus with the
aux = 1+ exp(b + ks.*(saturation-OptSaturation));
logMRRatio = p + (q-p)./aux;

MRRatio = 10.^logMRRatio;
MRactual = MROpt.*MRRatio;

end