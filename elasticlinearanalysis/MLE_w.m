 function [w,Rs,Lind,Lind1,ind,sumH,Lambda,A,B,C,D,L] = MLE_w(p,a,x,z,m,H,E,nu)
%function [w,Rs,Lind,Lind1,ind,sumH,Lambda,A,B,C,D,L] = MLE_w(p,a,x,z,m,H,E,nu)

m = m(:)+1e-16;
H = H(:);
E = E(:);
nu = nu(:);
nLayers = length(nu);
sumH = sum(H);
Lambda = [0;cumsum(H)/sumH;1e3];
L = z/sumH;
ro = x/sumH;
alpha = a/sumH;
ind = find(Lambda>L,1);
A = zeros(length(m),nLayers);
B = zeros(length(m),nLayers);
C = zeros(length(m),nLayers);
D = zeros(length(m),nLayers);

for i=1:length(m)
    [a,b,c,d] = MLE_bc(m(i),H,E,nu);
    A(i,:) = a(:)';
    B(i,:) = b(:)';
    C(i,:) = c(:)';
    D(i,:) = d(:)';
end

%%%found the error!!!!     - -- the fist (exp (-mLambda-l) must point to Lambda(ind)
 Rs = -(1+nu(ind-1))/E(ind-1)*besselj(0,m*ro).*((A(:,ind-1)-C(:,ind-1).*(2-4*nu(ind-1)-m*L)).*exp(-m*(Lambda(ind)-L))...
        -(B(:,ind-1)+D(:,ind-1).*(2-4*nu(ind-1)+m*L)).*exp(-m*(L-Lambda(ind-1))));
Rs = Rs(:);

if length(m)>1
    %%note v2019-03-31: According to Caicedo (2018), leave the "sumH" term
    %%in the w calculation (or inside the Rs term, as typed by the author), although it doesn't appear in Huang (2004).
    %%That gives the right results!
    w = p*alpha*sum(((Rs(1:end-1)+Rs(2:end))/2)./((m(1:end-1)+m(2:end))/2).*besselj(1,((m(1:end-1)+m(2:end))/2)*alpha).*diff(m))*sumH;
else
    w = Rs*sumH;
end

Lind = Lambda(ind);
Lind1= Lambda(ind-1);