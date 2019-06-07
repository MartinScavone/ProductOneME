function a = wheelFootprint(axleWeights,axleWheelCount,tirePressure)
%function a = wheelFootprint(axleWeights,axleWheelCount,tirePressure)
%This auxiliary function calculates the radius of the equivalent footprint for each wheel belonging to a certain type of axle.
%A circular equivalent shape is assumed for the wheel footprint(Refer to Huang '04 chapter 1 for details)
%
%Input: axleWeights: Vector of wheights in the axle category [in tonnes]
%       tirePRessure: tire pressure for each wheel in the axle (assumed constant throughout the axles -yet the code will admit a different
%       pressure for each axle weight- [PSI]
%       axle Code: 1 = single axle / 2 = tandem axle / 3 = tridem axle
%       axleWheelCount: count of all the wheels in the axle (both sides)
%
%OUTPUT: a: radius of equivalent circular footprint [cm] in a vector the
%same size as the "axleWeights" 
%NOTE: This function needs that all the axle weights included in "axleWeights" have the same number of wheels!

%0 - convert the axle weights in tonnes to pounds so that I can divide by
%tire pressure in PSI and keep units consistency
%1 ton(metric) = 1000kgf = 2204.623 pounds
axleWeights = axleWeights*2204.623;

%1 - calculate contact area for each wheel (assuming all the wheels are at
%the same pressure and load is distributed equally onto each wheel)

contactArea = (1/axleWheelCount)*(axleWeights./tirePressure);

%2 - calculate the equivalent contact radius "a"
a = sqrt(contactArea/pi);

%2b - convert a to cm  [result above is in inches]
a = a*2.54;

end

