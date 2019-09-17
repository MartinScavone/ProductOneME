%script for importing climate data to climate database
%%I will create structure files for each station
%with these contents
%-------------
%%%%Station name, <location : x, Y, Z coordinates> (UTM zone 21; may need to check 33, it may be in zone 22)
%%%%timestamp record (datenum function on date and time)
%%%%average temperature (deg C)
%%%%relative humidity
%%%%wind speed avg. (m/sec)
%%%%rainfall (mm)
%%%% Solar radiation (Avg. rad in W/m2);

clear variables
clc
more off


disp('starting up First-time climate data importer')
%%Create structures
%%Each structure will be 1x1 type struct, but each field will have varying length according to availability of raw input data.

INIA_LE = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %la estanzuela
INIA_LB = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %las brujas
INIA_33 = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %Treinta y tres
INIA_Tbo = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %Tacuarembo
INIA_Dur = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %Durazno
INIA_Gle = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %Glencoe
INIA_SG = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %Salto Grande
INIA_RO = struct('Name',[],'Location',[],'timestamp',[], 'temp',[],'hum',[],'wspd',[],'rain',[],'srad',[]);  %Rocha

%%load each station's tag (name and location)
INIA_LE(1).Name = 'La Estanzuela';
INIA_LB(1).Name = 'Las Brujas';
INIA_33(1).Name = 'Treinta y Tres';
INIA_Gle(1).Name = 'Glencoe';
INIA_Tbo(1).Name = 'Tacuarembo';
INIA_SG(1).Name = 'Salto Grande';
INIA_RO(1).Name = 'Rocha';
INIA_Dur(1).Name = 'Durazno'; 

%  %%Solve XYZ coordinates UTM ZONE 21 South [x,y, elevation].
INIA_LE(1).Location = [436327.9253 6200235.5018 72];  % Estanzuela
INIA_LB(1).Location = [560465.9452 6163137.9443 29];  %'Las Brujas'
INIA_33(1).Location = [734091.6752 6316794.8323 57];  %'Treinta y Tres';
INIA_Gle(1).Location =[487380.5105 6458909.9269 111]; % 'Glencoe';
INIA_Tbo(1).Location =[611179.8412 6491232.6381 143]; % 'Tacuarembo';
INIA_SG(1).Location = [415197.1076 6539824.5511 47];  %'Salto Grande';
INIA_Dur(1).Location =[544344.3630 6313843.9710 90];  %'Durazno';
INIA_RO(1).Location = [737562.7296 6169126.4819 19];   %Rocha

%Bring Data for each INIA station

%%INIA LE
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Estanzuela')
drawnow
%INIAData = odsread('INIA_LE.ods',1,'a5:j73484'); 
INIAData = csvread('INIA_LE.csv'); 
INIA_LE(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0);
INIA_LE(1).temp = INIAData(:,5);
INIA_LE(1).hum = INIAData(:,6);
INIA_LE(1).wspd = INIAData(:,8);
INIA_LE(1).rain = INIAData(:,7);
INIA_LE(1).srad = INIAData(:,10);

%%INIA LB
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Las Brujas')
drawnow
%INIAData = odsread('INIA_LB.ods',1,'a5:j71256');
INIAData = csvread('INIA_LB.csv');
INIA_LB(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0);
INIA_LB(1).temp = INIAData(:,5);
INIA_LB(1).hum = INIAData(:,6);
INIA_LB(1).wspd = INIAData(:,7);
INIA_LB(1).rain = INIAData(:,8);
INIA_LB(1).srad = INIAData(:,10);

%INIA_33
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA TrrrreintayTrrres')
drawnow
%INIAData = odsread('INIA_33.ods',1,'a5:j64381');
INIAData = csvread('INIA_33.csv');
INIA_33(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0) ;
INIA_33(1).temp = INIAData(:,5);
INIA_33(1).hum = INIAData(:,6);
INIA_33(1).wspd = INIAData(:,8);
INIA_33(1).rain = INIAData(:,7);
INIA_33(1).srad = INIAData(:,10);

%INIA_tbo
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Tacuarembo')
drawnow
%INIAData = odsread('INIA_Tbo.ods',1,'a5:j73065');
INIAData = csvread('INIA_Tbo.csv');
INIA_Tbo(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0) ;
INIA_Tbo(1).temp = INIAData(:,5);
INIA_Tbo(1).hum = INIAData(:,6);
INIA_Tbo(1).wspd = INIAData(:,8);
INIA_Tbo(1).rain = INIAData(:,7);
INIA_Tbo(1).srad = INIAData(:,10);

%INIA_Gle
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Glencoe')
drawnow
%INIAData = odsread('INIA_Gle.ods',1,'a5:j68990');
INIAData = csvread('INIA_Gle.csv');

INIA_Gle(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0);
INIA_Gle(1).temp = INIAData(:,5);
INIA_Gle(1).hum = INIAData(:,6);
INIA_Gle(1).wspd = INIAData(:,8);
INIA_Gle(1).rain = INIAData(:,7);
INIA_Gle(1).srad = INIAData(:,10);

%Inia durazno
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Durazno')
drawnow
%INIAData = odsread('INIA_Dur.ods',1,'a5:j38165');
INIAData = csvread('INIA_Dur.csv');

INIA_Dur(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0);
INIA_Dur(1).temp = INIAData(:,5);
INIA_Dur(1).hum = INIAData(:,6);
INIA_Dur(1).wspd = INIAData(:,8);
INIA_Dur(1).rain = INIAData(:,7);
INIA_Dur(1).srad = INIAData(:,10);

%INIA Salto Grande.
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Salto Grande')
drawnow
%INIAData = odsread('INIA_SG.ods',1,'a5:j27120');
INIAData = csvread('INIA_SG.csv');
INIA_SG(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0) ;
INIA_SG(1).temp = INIAData(:,5);
INIA_SG(1).hum = INIAData(:,6);
INIA_SG(1).wspd = INIAData(:,8);
INIA_SG(1).rain = INIAData(:,7);
INIA_SG(1).srad = INIAData(:,10);

%Inia Rocha
%Arrange xls file as follows: Timestamp, year, temp, humidity, windspeed <msec>, rain, srad
disp('Reading climate data for INIA Rocha')
drawnow
%INIAData = odsread('INIA_RO.ods',1,'a5:j7784');
INIAData = csvread('INIA_RO.csv');
INIA_RO(1).timestamp = datenum(INIAData(:,3),INIAData(:,1),INIAData(:,2),INIAData(:,4),0,0);
INIA_RO(1).temp = INIAData(:,5);
INIA_RO(1).hum = INIAData(:,6);
INIA_RO(1).wspd = INIAData(:,8);
INIA_RO(1).rain = INIAData(:,7);
INIA_RO(1).srad = INIAData(:,10);

clear INIAData

%%Now that I have imported everything, save contents to a MAT file
save('INIAClimateOctave.mat','INIA_LE','INIA_LB','INIA_33','INIA_Tbo','INIA_Dur','INIA_Gle','INIA_SG','INIA_RO');
disp ('Complete successfuly')

%EOF

