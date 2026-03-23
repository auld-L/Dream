% This is the script to pick, repick and view strong-motion waves

%%
% Length of the wave needed in the inversion in s, expected to include the
% FULL WAVE
leng = 300;

% File name of the strong-motion records prepared
loadfile = 'ob_smwcs.mat';

% Ordinal numbers of stations that are to exclude from the inversion
%deldex = [14,21,24,26,28];
deldex = [1,22,28,29];
% Decide whether to show filtered (set 1) or original (set 0) waves in the
% following figure
iffilter = 1;

% Bandpass (in Hz) of the records shown in the following figure
% Bandpass here WILL NOT BE SAVED AND USED in the inversion
band = [0.02,0.1];

%%
load(loadfile);
ob(:,:,deldex) = [];
loca(deldex,:) = [];
mm(deldex,:) = [];

obf = ob;
if iffilter
    [bb,aa] = butter(3,band*2/srate);
    obf = filter(bb,aa,ob);
end

pltob(obf,[4,ceil(size(obf,3)/4)],mm,srate);

save ob_smwcsnew.mat ob loca mm srate
