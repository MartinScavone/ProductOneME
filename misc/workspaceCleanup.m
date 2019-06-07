%% PRODUCT-ONE PAVEMENT M-E DESIGN TOOL %%%
%Workspace clean-up script
%
%This script will clear out the not necessary varaiables and leave
%only those that have some sort of meaning
%
%V0.0 2019-03-05

%% code begins
%clear stuff from the export scripts
clear plotted15 plotted21 plotted31 plotted3233 plotted34 plotCheck auxPlotList failyPlot
clear rangeToExport
clear finalRowToExport
clear createFigures

%clear other main-code stuff
clear termination
clear currentDay currentHour currentMonth churrentYear
clear deltaTime
clear auxDate

%clear stuff from the MLE and Distress Calculator
clear r i j k
clear whereInTime
clear nax nrs10 nrs6 nrsL nrTa10 nrTa14 nrTa18 nrTr
clear c1p c2p
clear cummDamage
clear auxDamage
clear auxv_HMA
clear auxE_HMA
clear auxLayersE auxLayersv auxLGMR
clear auxR1 auxR2 auxR3 auxR4 auxR5 auxR6
clear auxAlpha1 auxAlpha2 auxAlpha3 auxAlpha4 auxAlpha5 auxAlpha6
clear auxSigmaR1 auxSigmaR2 auxSigmaR3 auxSigmaR4 auxSigmaR5 auxSigmaR6
clear auxSigmaT1 auxSigmaT2 auxSigmaT3 auxSigmaT4 auxSigmaT5 auxSigmaT6
clear auxSigmaX1 auxSigmaX2 auxSigmaX3 auxSigmaX4 auxSigmaX5 auxSigmaX6
clear auxSigmaY1 auxSigmaY2 auxSigmaY3 auxSigmaY4 auxSigmaY5 auxSigmaY6
clear auxSigmaZ1 auxSigmaZ2 auxSigmaZ3 auxSigmaZ4 auxSigmaZ5 auxSigmaZ6
clear auxTauXY1  auxTauXY2  auxTauXY3  auxTauXY4  auxTauXY5  auxTauXY6
clear aux
% clear auxMaxRut auxMaxRutPosition
% clear auxrutDepthGranSingleL auxrutDepthHMASingleL auxrutDepthSubGradeSingleL
% clear auxrutDepthGranSingle6 auxrutDepthHMASingle6 auxrutDepthSubGradeSingle6
% clear auxrutDepthGranSingle10 auxrutDepthHMASingle10 auxrutDepthSubGradeSingle10
% clear auxrutDepthGranTandem10 auxrutDepthHMATandem10 auxrutDepthSubGradeTandem10
% clear auxrutDepthGranTandem14 auxrutDepthHMATandem14 auxrutDepthSubGradeTandem14
% clear auxrutDepthGranTandem18 auxrutDepthHMATandem18 auxrutDepthSubGradeTandem18
% clear auxrutDepthGranTridem auxrutDepthHMATridem auxrutDepthSubGradeTridem

%clear stuff from the materials' module
clear previousHumidity
clear numLayersForMoisture
clear moistureLyrJaux
clear currentHumidity
clear downwardRunoff downwardRunoffAux
clear intervalInfiltration intervalRainfall
