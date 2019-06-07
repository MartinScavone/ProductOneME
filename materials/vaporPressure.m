function pvap = vaporPressure(temp,hum)
  %function pvap = vaporPressure(temp,hum)
  %this auxiliary function will provide the actual vapor pressure for a site 
  %at temperature "temp" [in C] and a humidity value "hum" [percentage]
  %Output pvap is in mmHg
  
  %Load vapor pressure table - there's a different .mat file for whether
  %code is running in Matlab (binary .mat) or Octave (text-based .mat)
  
  isThisOctave = exist('OCTAVE_VERSION') ~=0;  %if the 'OCTAVE VERSION' variable exists, the statement is diff. from 0, the value of isThisOctave is 1
  %(in Matlab, isThisOctave shall equal to 0)
  %Ref: https://stackoverflow.com/questions/2246579/how-do-i-detect-if-im-running-matlab-or-octave
  
  if isThisOctave   
      load('./dataFiles/pvapTable_OCT.mat');   %Text version of the temp | pvap series  (stored in pvapTable variable)
  else
      load('./dataFiles/pvapTable_MAT.mat');   %Binary version of the temp | pvap series
  end
  
  %first, obtain maximum vapor pressure for given temperature Temp
  pvapMaxima = interp1(pvapTable(:,1),pvapTable(:,2),temp);
  
  %Compute the actual vapor pressure
  pvap = hum/100 .* pvapMaxima;
end