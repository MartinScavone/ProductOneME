function y = sin18(x,z)
%function y = sin18(x,z)
%function to calculate the sin of the current hour in the 18-hour cycle, as
%defined for the BELLS equations (see FHWA RD-98-085)
% INPUT: x = hour in decimal time <treated as an angle in radians>
%        z = an auxiliary hour (the BELLS equations use 15.5 and 13.5 in
%        different terms). Refer to the RD-98-085 for details.
%OUTPUT: y = value for sin18(x) <adim.>


%first - manage the hours following the RD-98-085 rule (separate cases for
%z = 15.5 and z = 13.5)

switch z
    case 15.5
        if x >=0 && x<=5
            x = x + 24;         %for hours between 0:00 and 5:00, sum 24 hours
        elseif x>5 && x < 11
            x = 11;             %for hours between 5:00 and 11:00, replace for 11:00
        else
            %do nothing
        end                
    case 13.5
        if x >=0 && x<=3
            x = x + 24;         %for hours between 0:00 and 3:00, sum 24 hours
        elseif x>3 && x < 9
            x = 9;             %for hours between 3:00 and 9:00, replace for 9:00
        else
            %do nothing
        end             
    otherwise
    %do nothing     
end

%second, calculate the sin of the hour x
angle = 2 * pi * (x-z)/18;
y = sin(angle);

end


