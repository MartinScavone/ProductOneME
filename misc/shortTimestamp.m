function shortTime = shortTimestamp(longTime)
%function shortTime = shortTimestamp(longTime)
%
%Auxiliary function to convert the hourly time series to a 6AM/6PM series
auxMat = datevec(longTime);

interestingPos = find(auxMat(:,4) == 6 | auxMat(:,4) == 18);  %locate those entries in longTime referring to any day at 6AM or 6PM
shortTime = longTime(interestingPos);

end  %endfunction
