%SETUP_V2 Rutas, carpetas y paleta comun de los experimentos v2.
rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir); addpath(fullfile(rootDir,'..','matlab'));
resDir = fullfile(rootDir,'..','resultados_v2');
figDir = fullfile(rootDir,'..','reporte','figs_v2');
if ~exist(resDir,'dir'), mkdir(resDir); end
if ~exist(figDir,'dir'), mkdir(figDir); end
co = [0.00 0.35 0.60; 0.85 0.55 0.10; 0.10 0.55 0.25; 0.60 0.20 0.45; 0.45 0.45 0.45; 0.80 0.20 0.20];
set(0,'DefaultFigureVisible','off');
