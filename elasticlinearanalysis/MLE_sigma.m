function [sigmaZ,sigmaR,sigmaT] = MLE_sigma(q,a,x,z,H,E,nu)
%function [sigmaZ,sigmaR,sigmaT] = MLE_sigma(q,a,x,z,H,E,nu)
%
%MULTI-LAYER ELASTIC STRESSES CALCULATOR
%Bqased equations in Huang (2004), Appendix B; with update by Caicedo (2018)
%
%Inputs
% q = LOAD pressure                                                 [PA // PSI]
% a = radius of circular load                                       [METER  // INCH]
% x = location from center of load (radial) [can be a vector]       [METER // INCH]
% z = depth from surface [can be a vector]!                         [METER // INCH]
% H = matrix with each layers thickness (one less entry than E, nu) [METER // INCH]
% E = matrix with each layer's Elastic modulus                      [PA  // PSI]
% nu= matrix with each layer's Poisson module                       [DIMLESS]
%
%NOTE: UNITS OF LOAD, E, H, a, x, z SHOULD BE CONSISTENT AMONG EACH OTHER.
%
%Outputs
% sigmaZ - stress in vertical direction for each (z,x) position (given as a  Z*R matrix)
% sigmaR - stress in radial direction for each (z,x) position (given as a  Z*R matrix)
% sigmaT - stress in tangential direction for each (z,x) position (given as a  Z*R matrix)
%
%%Dependency: This function calls MLE_bc
% 
% Original code by S. K.
% Ported to Product One 2019-02-04.
% Updated V2019-03-31
% Changelog:
%    Debugged against OpenPave and PitraPave: Discovered notation in Huang
%    (2004) and Caicedo 2018 have reverted signs!. Multiply stresses by -1
%    to match actual results.
%   
%    Use the equations for vertical and radial stress 
%    The m parameter used in calculation is no longer an input but it's defined here as a vector and passed on to the calculator
%    Improved code to handle zand r as vectors of many positions.

%% code begins
%m = m(:)+1e-16;
m = 0:0.5:50; m(1) = 1e-5; m = m';        %first trial showed that m no larger than ~40-50 would be necessary, the Rs terms will dilute for greater m (and Matlab will bring a warining for singular matrices). Also, m(1) so close to 0 will give such an error too
x = x(:);
H = H(:);
E = E(:);
nu = nu(:);
nLayers = length(nu);
sumH = sum(H);                          %sumH must be THE DISTANCE FROM THE SURFACE TO THE TOP OF THE LOWEST LAYER (SUBGRADE)
Lambda = [0;cumsum(H)/sumH;1e3];        %THIS ONE 
L = z/sumH;                             %this is "lambda" in Huang's Notation. 
ro = x/sumH;                            %rho as defined after eqn B2.f
alpha = a/sumH;                         %defined as Eqn B5 in Huang '04
ind = zeros(size(z));
for i = 1:length(ind)
    ind(i) = find(Lambda>L(i),1);       %ind = first non-zero value of Lambda>L   (that is, first position that is below z(i))
end
A = zeros(length(m),nLayers);
B = zeros(length(m),nLayers);
C = zeros(length(m),nLayers);
D = zeros(length(m),nLayers);

for i=1:length(m)
    %solve the boundary conditions for that given m value (obtain A, B, C, D) equations B8-B17
    [a,b,c,d] = MLE_bc(m(i),H,E,nu);    
    A(i,:) = a(:)';
    B(i,:) = b(:)';
    C(i,:) = c(:)';
    D(i,:) = d(:)';
end

%initialize the output variables
sigmaR = zeros(length(z),length(x));
sigmaT = zeros(length(z),length(x));
sigmaZ = zeros(length(z),length(x));

%% solve for sigma Z

%get the R* value from equation B4a [vertical stress], for all layers and all
%values of m, for all values of z
for j = 1:length(x)
    for i = 1:length(z)    
        Rs = -m.*besselj(0,m*ro(j)).*((A(:,ind(i)-1)-C(:,ind(i)-1).*(1-2*nu(ind(i)-1)-m*L(i))).*exp(-m*(Lambda(ind(i))-L(i)))...
            +(B(:,ind(i)-1)+D(:,ind(i)-1).*(1-2*nu(ind(i)-1)+m*L(i))).*exp(-m*(L(i)-Lambda(ind(i)-1))));
         Rs = Rs*-1;   %%update V2019-03-31 [multiply by -1 to match sign convention]
        Rs = Rs(:);    
    %  
    %integrate R* using equation B7 to get R [sigmaZ]. 
        %Output here is w at the base of pavement, right?
        if length(m)>1
            sigmaZ(i,j) = q*alpha*sum(((Rs(1:end-1)+Rs(2:end))/2)./((m(1:end-1)+m(2:end))/2).*besselj(1,((m(1:end-1)+m(2:end))/2)*alpha).*diff(m));
        else
            sigmaZ(i,j) = Rs;
        end
    end
end
%% solve for sigma R

%get the R* value from equation B4b [radial stress], for all layers and all
%values of m, for all values of z
for j = 1:length(x)
    for i = 1:length(z)    
        Rs = (m.*besselj(0,m*ro(j))-(1/ro(j)).*besselj(1,m*ro(j))).*((A(:,ind(i)-1)+C(:,ind(i)-1).*(1+m*L(i))).*exp(-m*(Lambda(ind(i))-L(i)))...
            +(B(:,ind(i)-1)-D(:,ind(i)-1).*(1-m*L(i))).*exp(-m*(L(i)-Lambda(ind(i)-1))))...
            + 2*nu(ind(i)-1).*m.*besselj(0,m*ro(j)).*(C(:,ind(i)-1).*exp(-m*(Lambda(ind(i))-L(i)))-D(:,ind(i)-1).*exp(-m*(L(i)-Lambda(ind(i)-1))));
        Rs = Rs*-1;      %%update V2019-03-31 [multiply by -1 to match sign convention]
        Rs = Rs(:);    

    %integrate R* using equation B7 to get R [sigmaZ]. 
        %Output here is w at the base of pavement, right?
        if length(m)>1
            sigmaR(i,j) = q*alpha*sum(((Rs(1:end-1)+Rs(2:end))/2)./((m(1:end-1)+m(2:end))/2).*besselj(1,((m(1:end-1)+m(2:end))/2)*alpha).*diff(m));
        else
            sigmaR(i,j) = Rs;
        end
    end
end
%% solve for sigma T

%get the R* value from equation B4c [angular stress], for all layers and all
%values of m, for all values of z
for j = 1:length(x)
    for i = 1:length(z)    
        Rs = (1/ro(j)).*besselj(1,m*ro(j)).*((A(:,ind(i)-1)+C(:,ind(i)-1).*(1+m*L(i))).*exp(-m*(Lambda(ind(i))-L(i)))...
            +(B(:,ind(i)-1)-D(:,ind(i)-1).*(1-m*L(i))).*exp(-m*(L(i)-Lambda(ind(i)-1))))...
            +2*nu(ind(i)-1).*m.*besselj(0,m*ro(j)).*(C(:,ind(i)-1).*exp(-m*(Lambda(ind(i))-L(i)))-D(:,ind(i)-1).* exp(-m*(L(i)-Lambda(ind(i)-1))));
        Rs = Rs*-1;   %updave V2019-03-31 [multiply by -1 to match sign convention]
        Rs = Rs(:);    

    %integrate R* using equation B7 to get R [sigmaZ]. 
        %Output here is w at the base of pavement, right?
        if length(m)>1
            sigmaT(i,j) = q*alpha*sum(((Rs(1:end-1)+Rs(2:end))/2)./((m(1:end-1)+m(2:end))/2).*besselj(1,((m(1:end-1)+m(2:end))/2)*alpha).*diff(m));
        else
            sigmaT(i,j) = Rs;
        end
    end
end