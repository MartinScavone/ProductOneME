function speedByAxle = axleSpeedFromVehicleSpeed(AADTSpeed)
%function speedByAxle = axleSpeedFromVehicleSpeed(AADTSpeed)
%this function will estimate the avg. speed of each axle type from the
%speed of the different traffic vehicles.
%INPUT: is the "AADT speed" vector column -avg. speed by
%vehicle type- 
%OUTPUT: vector containing the avg. speed of each axle category (assuming
%all weights within each axle cat. run at the same speed)
%Categories as follows: [light-weight single / 6 ton single / 10 ton single
%/ 18 ton tandem / 10 ton tandem / 14 ton tandem / 22/25ton tridem]

speedByAxle = zeros(7,1);

%speed of light-weight axles (cars only)
speedByAxle(1) = AADTSpeed(1);

%speed of 6-ton single axles (entries 2,3, 5, 6 8:end)
speedByAxle(2) = mean(AADTSpeed([2,3,5,6,8:end]));

%speed of 10-ton single axles (entries 2, 5, 8, 9, 10, 11, 12 13 15 16 18 19 20 21 22 
speedByAxle(3) = mean(AADTSpeed([2,5,8,9:13,15,16,18:22]));

%speed of 18-ton tandem axles (entries 6,7,9,10,14,15,16,17,18,19,20,22,23)
speedByAxle(4) = mean(AADTSpeed([6,7,9,10,14:20,22,23]));

%speed of 10-ton tandem axles (entries 4,7 )
speedByAxle(5) = mean(AADTSpeed([4,7]));

%speed of 14-ton tandem axles (entries 3-4)
speedByAxle(6) = mean(AADTSpeed([3,4]));

%speed of tridems (entries 13 17)
speedByAxle(7) = mean(AADTSpeed([13,17]));

end  %endfunction
