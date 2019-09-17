%%integrity check script to run upon start of the Product-One MainCode
%%
%%
%%update V2019-09-17: Forced a 'more off' in Ocvtave so that all the on-screen messages would appear as the code runs 
%%update V2019-07-18: Added check for the datetime function in GNU-Octave (non-native). 
%%Also, added instructions on how to retrieve it.

%% - 1 check if I have the I/O functions -octave only- and install if needed
isThisOctave = exist('OCTAVE_VERSION') ~=0; 
if isThisOctave
   disp('PRODUCT-ONE DETECTED YOU ARE RUNNING GNU-OCTAVE')
   warning("off","Octave:divide-by-zero")   %disable these warnings cause Octave would otherwise throw hundreds of them when solving the MLE
   more of         %%update 2019-09-17. See if this line forces Octave to print the verbose output to screen in real-time...
   checkforIOPkg = exist('xlsread')==0;    %%if this hold true (the IO package has not yet been installed/loaded), download and install pkg io
   if checkforIOPkg
      warning('Please install IO package for Octave and restart') 
      disp('retrieve it directly from Octave-Forge')
      pkg load io   %%try this sentence in octave, see what's the outcome when io is not installed (and will need to download)
       %Nevertheless, Octave version will use odsread instead for importing files.
   end 
   checkforDateTimePkg = exist('datetime')==0;
   if checkforDateTimePkg
       warning('Please install chrono package for Octave and restart') 
       disp('retrieve it from : https://github.com/apjanke/octave-chrono/releases/download/v0.3.1/chrono-0.3.1.tar.gz')
      pkg load chrono %% The tarball that the uploader provided has some syntax error and wouldn't install with the pkg install command.
      % However, I managed to install and load a version with a small tweak. I added it to the repository. Credit to A. Janke for the "chrono" pkg.
   end
   
else
     disp('PRODUCT-ONE DETECTED YOU ARE RUNNING MATLAB')
end

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


