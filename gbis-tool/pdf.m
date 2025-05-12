clear;clc;
load("invert_1_2_F.mat");

burning = 1000;

if invpar.nRuns < 10000
    blankCells = 999; 
else
    blankCells = 9999;
end

nParam = length(invResults.mKeep(:,1)); % Number of model parameters

for i = 1:nParam-1
    subplot(round(nParam/3),3,i)    % Determine poistion in subplot
    plot(1:100:length(invResults.mKeep(1,:))-blankCells, invResults.mKeep(i,1:100:end-blankCells),'r.') % Plot one point every 100 iterations
    title(invResults.model.parName(i))
end

figure('Position', [1, 1, 1200, 1000]);
for i = 1:nParam-1
    subplot(round(nParam/3),3,i) % Determine poistion in subplot
    xMin = mean(invResults.mKeep(i,burning:end-blankCells))-4*std(invResults.mKeep(i,burning:end-blankCells));
    xMax = mean(invResults.mKeep(i,burning:end-blankCells))+4*std(invResults.mKeep(i,burning:end-blankCells));
    bins = xMin: (xMax-xMin)/50: xMax;
    h = histogram(invResults.mKeep(i,burning:end-blankCells),bins,'EdgeColor','none','Normalization','count');
    hold on
    topLim = max(h.Values);
    plot([invResults.model.optimal(i),invResults.model.optimal(i)],[0,topLim+10000],'r-') % Plot optimal value
    ylim([0 topLim+10000])
    title(invResults.model.parName(i))
end

