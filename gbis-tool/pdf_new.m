clear;clc;
load("invert_1_2_F.mat");

burning = 1000;

if invpar.nRuns < 10000
    blankCells = 999; 
else
    blankCells = 9999;
end

nParam = length(invResults.mKeep(:,1)); % Number of model parameters

% for i = 1:nParam-1
%     subplot(round(nParam/3),3,i)    % Determine poistion in subplot
%     plot(1:100:length(invResults.mKeep(1,:))-blankCells, invResults.mKeep(i,1:100:end-blankCells),'r.') % Plot one point every 100 iterations
%     title(invResults.model.parName(i))
% end


% --- 美化后的迹线图 (Trace Plots) ---
figure('Position', [100, 100, 1500, 900]); % 创建一个尺寸合适的窗口

% 使用 tiledlayout 更好地控制子图间距，比 subplot 更好用
t = tiledlayout(3, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

% 为整个图添加一个总标题
title(t, 'MCMC Trace Plots for Model Parameters', 'FontSize', 16, 'FontWeight', 'bold');
xlabel(t, 'Iteration Number', 'FontSize', 12); % 为整个图添加X轴总标签

for i = 1:nParam-3
    % 移动到下一个子图位置
    nexttile; 
    
    % --- 核心绘图命令 ---
    % 使用半透明的蓝色点来展示数据密度，而不是简单的红点
    plot(1:100:length(invResults.mKeep(1,:))-blankCells, ...
         invResults.mKeep(i,1:100:end-blankCells), ...
         '.', 'MarkerSize', 6, 'Color', [0 0.4470 0.7410 0.25]); % 最后一个值0.25代表透明度
    
    hold on;
    
    % --- 美化细节 ---
    box on; % 显示完整的坐标轴边框
    grid on; % 添加网格线，方便读数
    ax = gca; % 获取当前坐标轴的句柄
    ax.FontSize = 10; % 统一设置坐标轴刻度的字体大小
    ax.LineWidth = 1.0; % 让坐标轴的线条稍微粗一点
    
    % 限制X轴范围，让图形更饱满
    xlim([0 length(1:100:length(invResults.mKeep(1,:))-blankCells)]);
    
    % --- 清晰的标题和标签 ---
    % 自动修正标题中的 "FAUL" -> "Fault"
    paramName = strrep(string(invResults.model.parName(i)), 'FAUL', 'Fault');
    
    % 为不同参数添加单位
    if contains(paramName, ["Length", "Width", "Depth", "X", "Y", "Slip"], 'IgnoreCase', true)
        ylabelValue = 'Value (m)';
    elseif contains(paramName, ["Dip", "Strike"], 'IgnoreCase', true)
        ylabelValue = 'Value (degrees)';
    else
        ylabelValue = 'Value (m)';
    end
    
    title(paramName, 'FontSize', 12);
    ylabel(ylabelValue, 'FontSize', 10);
end

% --- 添加下面这行代码来保存图片 ---
exportgraphics(gcf, 'Trace_Plots.png', 'Resolution', 300);
disp('迹线图已保存为 Trace_Plots.png');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%第二张图%%%%%%
% figure('Position', [1, 1, 1200, 1000]);
% for i = 1:nParam-1
%     subplot(round(nParam/3),3,i) % Determine poistion in subplot
%     xMin = mean(invResults.mKeep(i,burning:end-blankCells))-4*std(invResults.mKeep(i,burning:end-blankCells));
%     xMax = mean(invResults.mKeep(i,burning:end-blankCells))+4*std(invResults.mKeep(i,burning:end-blankCells));
%     bins = xMin: (xMax-xMin)/50: xMax;
%     h = histogram(invResults.mKeep(i,burning:end-blankCells),bins,'EdgeColor','none','Normalization','count');
%     hold on
%     topLim = max(h.Values);
%     plot([invResults.model.optimal(i),invResults.model.optimal(i)],[0,topLim+10000],'r-') % Plot optimal value
%     ylim([0 topLim+10000])
%     title(invResults.model.parName(i))
% end
% 
% % 保存最终的精美图片
% exportgraphics(gcf, 'Posterior_PDFs_Final_Compatible.png', 'Resolution', 300);

f = figure('Position', [1, 1, 1200, 1000]);

% tiledlayout 内部的间距可以设为紧凑或宽松，不影响外部大边距
t.Padding = 'compact';
t.TileSpacing = 'compact';

for i = 1:nParam-3
  % 3. 在循环中使用 nexttile 代替 subplot
  nexttile; 

  xMin = mean(invResults.mKeep(i,burning:end-blankCells))-4*std(invResults.mKeep(i,burning:end-blankCells));
  xMax = mean(invResults.mKeep(i,burning:end-blankCells))+4*std(invResults.mKeep(i,burning:end-blankCells));
  bins = xMin: (xMax-xMin)/50: xMax;
  h = histogram(invResults.mKeep(i,burning:end-blankCells),bins,'EdgeColor','none','Normalization','count','FaceColor',[0.1725, 0.2431, 0.3137]);
  hold on; % 在 nexttile 环境中，hold on 对当前 tile 有效
  topLim = max(h.Values);
  plot([invResults.model.optimal(i),invResults.model.optimal(i)],[0,topLim*1.1],'r-'); % 建议使用相对边距
  ylim([0 topLim*1.1]);
  title(invResults.model.parName(i));
  grid on;

% ▼▼▼ 根据循环变量 i 的值来设置 xlabel ▼▼▼
if i == 4 || i == 5
    xlabel('unit(degrees)');
else
    xlabel('unit(m)');
end
    
end



% 保存最终的精美图片
exportgraphics(gcf, 'Posterior_PDFs_Final_Compatible.png', 'Resolution', 300);
