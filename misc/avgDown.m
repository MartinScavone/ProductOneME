function tempShort = avgDown(longTemp,longTimestamp,shortTimestamp)
%function tempShort = avgTemp(longTemp,longTimestamp,shortTimestamp)
%this auxiliary function will convert the hourly temperature record stored
%in longTemp (length matching longTimestamp) and calculate the average.

%Assuming all timestamp input vectors are column vectors; longTemp is a
%matrix, code will perform the averaging over columns
%Averages will be reported at 6AM and 6PM.

nst = length(shortTimestamp);
[rous,cols] = size(longTemp);
tempShort = zeros(nst,cols);

%scan the short timeStamp vector, locate when each short timestamp occurs
%in the long vector, and avg. the 
for i = 1:nst
    pos = find(longTimestamp == shortTimestamp(i));
    %now, pick the temeprature records in the longTemp series from which
    %you need the avg. value. Store in auxVec
    if pos <=11
        auxVec = longTemp(1:pos,:);
    else
        auxVec = longTemp(pos-11:pos,:);
    end
    %now do the avg and store in output
    tempShort(i,:) = mean(auxVec,1);   %perform the mean value for each column (averages all rows of auxVec)
    
    
end


end