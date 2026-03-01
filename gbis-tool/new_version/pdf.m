clear;
load("invert_1_2_3_F.mat");
% --- 终极修正：精准定位真实数据的最后一笔，彻底抛弃 blankCells ---
% 因为断层长度 (Length，第一行) 永远不可能为 0
% 所以我们直接寻找第一行最后一个不为 0 的位置，这就是真实的迭代终点
total_iters = find(invResults.mKeep(1,:) ~= 0, 1, 'last'); 
disp(['系统识别到的真实有效迭代次数为: ', num2str(total_iters)]);

% 反演模型参数的数量 (包含轨道拟合参数)
nParam = length(invResults.mKeep(:,1)); 

burning = 10000;

% =========================================================================
% 第一张图：美化后的迹线图 (MCMC Trace Plots) - 彻底去零版
% =========================================================================
f1 = figure('Position', [100, 100, 1500, 900]); 
t1 = tiledlayout(3, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

title(t1, 'MCMC Trace Plots for Model Parameters', 'FontSize', 16, 'FontWeight', 'bold');
xlabel(t1, 'Iteration Number', 'FontSize', 12); 

x_steps = 1:100:total_iters;

% 核心修改：只画前 9 个断层物理参数，完美填满 3x3 网格
for i = 1:9 
    nexttile;
    
    % 精准提取数据，不多拿一个 0
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