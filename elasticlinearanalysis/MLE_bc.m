function [A,B,C,D,RM,LM,CM,nLayers,F,dLambda,Lambda] = MLE_bc(m,H,E,nu)
%%function [A,B,C,D,RM,LM,CM,nLayers,F,dLambda,Lambda] = MLE_bc(m,H,E,nu)

%tweaked version V2019-03-29
H = H(:); E = E(:); nu = nu(:);
nLayers = length(E);
sumH = sum(H);
H = [H;max(H)*1e3];
% H = [H;1e5];
Lambda = cumsum(H)/sumH;

LM1 = [exp(-m*Lambda(1)) 1 ; exp(-m*Lambda(1)) -1];
RM1 = [-(1-2*nu(1))*exp(-m*Lambda(1)) 1-2*nu(1) ; 2*nu(1)*exp(-m*Lambda(1)) 2*nu(1)];
%%tweak 01 - I can compute [a1--d1] directly with the surface boundary condition
%%DONT DO IT, THIS IS NOT A WELL-DEFINED SYSTEM (4 VARIABLES, 2 EQUATIONS)
% A1 = [LM1 RM1]\[1;0];  %A\B means "solve the system Ax = B. A1 IS THE COLUMN VECTOR [A1;B1;C1;D1]  

dLambda = diff([0;Lambda]);
F = exp(-m*dLambda);
R = E(1:end-1)./E(2:end).*((1+nu(2:end))./(1+nu(1:end-1)));

LM = zeros(4,4,nLayers-1);
RM = zeros(4,4,nLayers-1);
InvLM = zeros(4,4,nLayers-1);
CM = zeros(4,4,nLayers-1);
FM = zeros(4,4);

for i=1:(nLayers-1)
    LM(:,:,i) = [1,  F(i), -(1-2*nu(i)-m*Lambda(i)), (1-2*nu(i)+m*Lambda(i))*F(i);...
                 1, -F(i), 2*nu(i)+m*Lambda(i),      (2*nu(i)-m*Lambda(i))*F(i);...
                 1,  F(i), 1+m*Lambda(i),            -(1-m*Lambda(i))*F(i);...
                 1, -F(i), -(2-4*nu(i)-m*Lambda(i)), -(2-4*nu(i)+m*Lambda(i))*F(i)];
     
    InvLM(:,:,i) = inv(LM(:,:,i));
    
    RM(:,:,i) = [F(i+1),         1,    -(1-2*nu(i+1)-m*Lambda(i))*F(i+1),      1-2*nu(i+1)+m*Lambda(i);...
                 F(i+1),        -1,    (2*nu(i+1)+m*Lambda(i))*F(i+1),         2*nu(i+1)-m*Lambda(i);...
                 R(i)*F(i+1),   R(i),  (1+m*Lambda(i))*R(i)*F(i+1),            -(1-m*Lambda(i))*R(i);... 
                 R(i)*F(i+1),  -R(i),  -(2-4*nu(i+1)-m*Lambda(i))*R(i)*F(i+1), -(2-4*nu(i+1)+m*Lambda(i))*R(i)];
     
    CM(:,:,i) = InvLM(:,:,i)*RM(:,:,i);
end

FM = CM(:,:,1);

for i=2:(nLayers-1)
    FM = FM*CM(:,:,i);
end
%%Note: For the sake of stability of the equation system (apparently it may
%%become singular), use teh approach said by the CR CILA paper and other
%%refs, and bother only in Bn and Dn

FM = FM(:,[2,4]);

%BnDn = (LM1*FM(1:2,:)+RM1*FM(3:4,:))\[1;0]; 
%%tweak 01, use the [A1...D1] VECTOR TO COMPUTE BnDn   %<< debug results: %this solution or the CR solutions bring the same boundary cond. values. 
%%BUT DONT' USE IT, CAUSE A1--D1 IS NOT DETERMINED (COMES FROM 2EQ/4VAR %SYSTEM)

% BnDn = FM\A1;                                          
%%tweak 01B, use the CR paper's formula to get BnDn
BnDn = ([LM1 RM1]*FM)\[1;0];

A = zeros(nLayers,1); B = zeros(nLayers,1); C = zeros(nLayers,1); D = zeros(nLayers,1);
B(end) = BnDn(1);
D(end) = BnDn(2);

 %tweak 03 - fill up A--D up to row 2; we have row 1 from the surface boundary condition
 %DISREGARD, A1 IS NOT A VALID SOLUTION!
% A(1) = A1(1); 
% B(1) = A1(2); 
% C(1) = A1(3); 
% D(1) = A1(4);

%for i=(nLayers-1):-1:1      %bug detected here. A1--D1 COMPUTED IN THIS
%LOOP WOULD NOT VERIFY THE SURFACE BOUNDARY CONDITION. SO WEIRD....
for i=(nLayers-1):-1:1
    BC = CM(:,:,i)*[A(i+1);B(i+1);C(i+1);D(i+1)];
    A(i) = BC(1);
    B(i) = BC(2);
    C(i) = BC(3);
    D(i) = BC(4);
end

