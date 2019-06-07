function t = temperaturePreviousDay(hourlyTimestamp,tempRecord)
  %function t = temperaturePreviousDay(i,timeStamp,tempRecord)
  %this auxiliary function will calculate the average temperature for the day before hourly timestamp(s) i, 
  %according to what reads in tempRecord.
  %
  %timeStamp is a hourly timeStamp vector, whose length matches tempRecord.
  %%UPDATE 2018-06-20: convert this function to a Matrix-calculation (relieve itself from running only within a for loop)
  %%UPDATE 2019-03-15: changed the dayK searcher for a "missed 29th of
  %%february scenario": on 366-days years made with 365-days registries,
  %%I'll have a blank spot for the 29th feb.; the dayK search will come up
  %%null. Force it to go to the 28th. instead (search for
  %%hourlyTimestamp(k)-2 instead)
  %%UPDATE 2018-06-20: convert this function to a Matrix-calculation (relieve itself from running only within a for loop)
 
hourlyTimestamp = floor(hourlyTimestamp);  %round down every timestamp to timestamp value matching year/mo/day @ 0:00hs
  [a,b] = size(hourlyTimestamp);
  t = zeros(a,b);   %initialize output vector
  
  
  %% 1 - solve t for the first day (positions where day(timeStamp(:)) = day(timeStamp(1))
  %Use t = temperature of day i
  
  locateDay1 = find(hourlyTimestamp(:) == hourlyTimestamp(1));  %locateDay1 will have all the positions in timeSTamp that match day 1
  t(locateDay1,:) = mean(tempRecord(locateDay1));
  
  %1.2 - solve for day 2: fill 24 positions with avg. from day 1 as well
  locateDay2 = find(hourlyTimestamp(:) == hourlyTimestamp(1)+1); %LocateDay2 will have the positions on timeMat corresponding to the day after day 1
  t(locateDay2,:) = mean(tempRecord(locateDay1));   %fill up with day 1 avg.
  
   %% 2 - solve t for day 3 onward: t(day i) = tempRecord (day i-1)
  %start of day 3 is in position locateDay2(end)
  for k = locateDay2(end)+1:a
      dayK = find((hourlyTimestamp) == (hourlyTimestamp(k)-1));   %position in hourlyTimestamp corresponding to day before day k
      if isempty(dayK)
          %update 2019-03-15--- missing 29thFeb problem!, force to check
          %from the 1st of march to the 28th of feb
         dayK =  find((hourlyTimestamp) == (hourlyTimestamp(k)-2));
      end
      t(k) = mean(tempRecord(dayK));     %do the average of temp records for the day     
      if isnan(t(k))
         disp('stop here')
      end
  end
  
end