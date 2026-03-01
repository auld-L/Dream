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

�据，不多拿一个 0
    y_values = invResults.mKeep(i, 1:100:total_iters);
    
    plot(x_steps, y_values, '.', 'MarkerSize', 6, 'Color', [0 0.4470 0.7410 0.25]); 
    hold on;
    
    xlim([0, total_iters]); 
    xline(burning, '--r', 'Burn-in', 'LabelVerticalAlignment', 'bottom', 'FontSize', 8);

    box on; grid on; 
    ax = gca; 
    ax.FontSize = 10; 
    ax.LineWidth = 1.0; 
    
    paramName = strrep(string(invResults.model.parName(i)), 'FAUL', 'Fault');
    title(paramName, 'FontSize', 12);
    
    if contains(paramName, ["Length", "Width", "Depth", "X", "Y", "Slip"], 'IgnoreCase', true)
        ylabel('Value (m)', 'FontSize', 10);
    elseif contains(paramName, ["Dip", "Strike"], 'IgnoreCase', true)
        ylabel('Value (degrees)', 'FontSize', 10);
    else
        ylabel('Value', 'FontSize', 10);
    end
end

exportgraphics(f1, 'Trace_Plots_Fixed.png', 'Resolution', 300);


% =========================================================================
% 第二张图：后验概率密度图 (Posterior PDFs) - 同步去零版
% =========================================================================
f2 = figure('Position', [1, 1, 1200, 1000]);
t2 = tiledlayout(3, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

% 核心修改：同样只画前 9 个参数
for i = 1:9 
    nexttile;
    
    % 同样精准提取到 total_iters，防止 0 混入直方图
    valid_data = invResults.mKeep(i, burning:total_iters);
    
    xMin = mean(valid_data) - 4*std(valid_data); 
    xMax = mean(valid_data) + 4*std(valid_data); 
    bins = xMin : (xMax-xMin)/50 : xMax; 
    
    h = histogram(valid_data, bins, 'EdgeColor', 'none', ...
                  'Normalization', 'count', 'FaceColor', [0.55, 0.6, 0.65]); 
    hold on; 
    
    topLim = max(h.Values); 
    if topLim == 0, topLim = 1; end 
    plot([invResults.model.optimal(i), invResults.model.optimal(i)], [0, topLim*1.1], 'r-', 'LineWidth', 2); 
    
    xlim([xMin, xMax]);
    ylim([0, topLim*1.1]); 
    grid on;
    
    paramName = strrep(string(invResults.model.parName(i)), 'FAUL', 'Fault');
    title(paramName, 'FontSize', 14, 'FontWeight', 'bold');
    
    if contains(paramName, ["Dip", "Strike"], 'IgnoreCase', true)
        xlabel('unit (degrees)', 'FontSize', 10);
    elseif contains(paramName, ["Length", "Width", "Depth", "X", "Y", "Slip"], 'IgnoreCase', true)
        xlabel('unit (m)', 'FontSize', 10);
    else
        xlabel('Value', 'FontSize', 10);
    end
end

exportgraphics(f2, 'Posterior_PDFs_Final.png', 'Resolution', 300);
disp('✅ 两张图已成功生成并导出！');