function [ z ] = getZfromPaveDepth(paveDepth)
%function [ z ] = getZfromPaveDepth(paveDepth)
%MULTI-LYR LINEAR ELASTIC ANALYSIS PROGRAM
%This is an auxiliary function that will build the vector of depths at
%which to compute stresses and strains from the vector of thickness of each
%pavement layer.
%
%Input:
% - paveDepth: vector with the thickness of each layer of pavement (plus
% the subgrade) - IN CENTIMETERS (as received from the MainCode)
%
%Output:
% - z: vector with the depth of each computation point, compliant with the
% MEPDG manual (NCHRP, 2004); part 3 chap. 3.
% z will contain the positions of [in METERS]:
% [surface, 1cm underneath the surface, 1/2 depth of each layer, bottom of
% each layer (until top of subgrade), and a point 15cm underneath the
% subgrade surface]
%
% V0.3: 2019-04-03 - - added a z(subgrade)+0.02m point - needed to compute strain decay in the subgrade for rutting purposes.
% V0.2: 2019-02-22 - - removed the z = 0.01m point (not needed at all).
% V0.1: 2019-02-07

%% code begins

%convert thicknesses to depths, and cm to meters. And remove the subgrade thickness entry (I won't need it) 
paveDepth = paveDepth(1:end-1);  %remove the maybe artificial subgrade thickness
paveDepth = paveDepth(:);        %fix as column vector
z = 0.01*cumsum(paveDepth);      %convert to depths

%add midpoints. Use this workaround: https://www.mathworks.com/matlabcentral/answers/25536-selecting-mid-points
z = [z;conv(z,[0.5;0.5],'valid')];
%add the 1st layer midpoint (which the convolution above doesn't calculate)
z = [0.5*z(1);z];
z = sort(z,'ascend');
% add surface points [0.01m],
%%%update V2019-04-03: Add the z(sub grade)+0.01m [The z(end) is assumed by Matlab to be in the subbase and not in the subgrade]
z = [0.005;z;z(end)+0.01;z(end)+0.15];

%%all done!
end

