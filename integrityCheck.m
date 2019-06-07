%%integrity check script to run upon start of the Product-1 MainCode

%% - 1 check if I have the I/O functions -octave only- and install if needed
isThisOctave = exist('OCTAVE_VERSION') ~=0; 
if isThisOctave
   disp('PRODUCT-ONE DETECTED YOU ARE RUNNING GNU-OCTAVE')
   more on         %%update 2019-02-11. See if this line forces Octave to print the verbose output to screen in real-time...
   checkforIOPkg = exist('xlsread')==0;    %%if this hold true (the IO package has not yet been installed/loaded), download and install pkg io
   if checkforIOPkg
       pkg load io   %%try this sentence in octave, see what's the outcome when io is not installed (and will need to download)
       %Nevertheless, Octave version will use odsread instead for importing files.
   end 
else
     disp('PRODUCT-ONE DETECTED YOU ARE RUNNING MATLAB')
end

%% - 2 check if all the files to run are AVAILABLE
%%% in addpath


%% - 3 addpaths
addpath './plottingTools';  %path to codes for plotting
addpath './climate';  %path to the climate Module scripts
addpath './materials';%path to the materials props. scripts
addpath './trafficProcessing';
addpath './dataImporting';
addpath './elasticLinearAnalysis';
addpath './distressCalculator';
%addpath './export_fig';     %path to export_fig (a 3rd. party code that allows to export graphs to pdf - uses ghostScript, it will perform integrity checks itself
addpath './dataFiles';
addpath './misc';


