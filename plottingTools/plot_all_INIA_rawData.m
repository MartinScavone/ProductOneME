%plot INIA climate variables script

%This script is to run when executing the climate Simulator (or the
%first-time importer). But I will tweak it to import the INIA structured
%data on-the-spot if these aren't loaded when running

%fist: Check if the INIA data are loaded.

INIA_here = exist('INIA_SG','var');  %Check if at least one of the structures with climate data are loaded. if not, load it
if INIA_here == 0
    load('../dataFiles/INIAClimate.mat');
end

%now time to plot
a = input('Plotting Inia La Estanzuela, press Enter to go on.....');
b = plotClimateVariables(INIA_LE(1).timestamp,INIA_LE(1).temp,INIA_LE(1).hum,INIA_LE(1).wspd,INIA_LE(1).srad,INIA_LE(1).rain);

a = input('Plotting Inia Las Brujas, press Enter to go on.....');
b = plotClimateVariables(INIA_LB(1).timestamp,INIA_LB(1).temp,INIA_LB(1).hum,INIA_LB(1).wspd,INIA_LB(1).srad,INIA_LB(1).rain);

a = input('Plotting Inia Durazno, press Enter to go on.....');
b = plotClimateVariables(INIA_Dur(1).timestamp,INIA_Dur(1).temp,INIA_Dur(1).hum,INIA_Dur(1).wspd,INIA_Dur(1).srad,INIA_Dur(1).rain);

a = input('Plotting Inia Glencoe, press Enter to go on.....');
b = plotClimateVariables(INIA_Gle(1).timestamp,INIA_Gle(1).temp,INIA_Gle(1).hum,INIA_Gle(1).wspd,INIA_Gle(1).srad,INIA_Gle(1).rain);

a = input('Plotting Inia Tacuarambo, press Enter to go on.....');
b = plotClimateVariables(INIA_Tbo(1).timestamp,INIA_Tbo(1).temp,INIA_Tbo(1).hum,INIA_Tbo(1).wspd,INIA_Tbo(1).srad,INIA_Tbo(1).rain);

a = input('Plotting Inia Salto Grande, press Enter to go on.....');
b = plotClimateVariables(INIA_SG(1).timestamp,INIA_SG(1).temp,INIA_SG(1).hum,INIA_SG(1).wspd,INIA_SG(1).srad,INIA_SG(1).rain);

a = input('Plotting Inia Treinta y Tres, press Enter to go on.....');
b = plotClimateVariables(INIA_33(1).timestamp,INIA_33(1).temp,INIA_33(1).hum,INIA_33(1).wspd,INIA_33(1).srad,INIA_33(1).rain);

a = input('Plotting Inia Rocha, press Enter to go on.....');
b = plotClimateVariables(INIA_RO(1).timestamp,INIA_RO(1).temp,INIA_RO(1).hum,INIA_RO(1).wspd,INIA_RO(1).srad,INIA_RO(1).rain);

disp('completed')