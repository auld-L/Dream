clc; clear; close all;

% =========================================================================
% 1. 设置与数据加载
% =========================================================================
invResFile = 'invert_1_2_F.mat';   % 反演结果文件
burning = 15000;                   % 预热期迭代次数
load(invResFile);

nParam = length(invResults.mKeep(:,1));

% 提取真实的有效迭代末端，弃用原始脚本中固定减去 blankCells 的脆弱逻辑
end_iter = find(invResults.mKeep(1,:) ~= 0, 1, 'last');
if isempty(end_iter)
    end_iter = length(invResults.mKeep(1,:));
end

% =========================================================================
% 2. 核心统计量计算 (提取自 generateFinalReport.m)
% =========================================================================
colNames = {'Parameter', 'Optimal', 'Mean', 'Median', '2.5%', '97.5%'};
rowData = cell(nParam-1, 6);

for i = 1:nParam-1
    param_chain = invResults.mKeep(i, burning:end_iter);
    
    % 格式化参数名及计算数值 (保留两位小数)
    rowData{i, 1} = char(strrep(string(invResults.model.parName(i)), 'FAUL', 'Fault'));
    rowData{i, 2} = sprintf('%.2f', invResults.model.optimal(i));
    rowData{i, 3} = sprintf('%.2f', mean(param_chain));
    rowData{i, 4} = sprintf('%.2f', median(param_chain));
    rowData{i, 5} = sprintf('%.2f', prctile(param_chain, 2.5));
    rowData{i, 6} = sprintf('%.2f', prctile(param_chain, 97.5));
end

% =========================================================================
% 3. 纯图形化表格绘制 (Bypass UI Component Export Bug)
% =========================================================================
% 动态计算图形窗口高度
figHeight = max(400, (nParam)*30 + 180);
f = figure('Position', [100, 100, 850, figHeight], 'Color', 'w', 'MenuBar', 'none', 'Name', 'Statistical Report');

% 创建隐形坐标轴用于绘图
ax = axes('Position', [0.05, 0.05, 0.9, 0.85], 'XLim', [0 1], 'YLim', [0 nParam+2], 'Visible', 'off');
set(ax, 'YDir', 'reverse'); % Y轴反向，实现从上向下绘制文字

% --- 绘制报告页眉 ---
text(0, -1.0, ['GBIS Final report for ', saveName(1:end-4)], 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'none');
text(0, -0.2, ['Results file: ', fullfile(pwd, saveName)], 'FontSize', 10, 'Interpreter', 'none', 'FontAngle', 'italic');
text(0,  0.4, ['Number of iterations: ', num2str(invpar.nRuns)], 'FontSize', 10);
text(0,  0.9, ['Burning time (n. of iterations from start): ', num2str(burning)], 'FontSize', 10);
line([0 1], [1.3 1.3], 'Color', 'k', 'LineWidth', 1.0); % 分割线

text(0,  2.0, 'Model parameters', 'FontSize', 13, 'FontWeight', 'bold');

% --- 定义表格列坐标系 ---
% 根据参考图布局设定每列的 X 坐标起始点
x_pos = [0.02, 0.25, 0.40, 0.55, 0.70, 0.85];
y_start = 2.8;     % 表头 Y 坐标
row_height = 0.8;  % 行高

% --- 绘制表头 ---
for j = 1:6
    text(x_pos(j), y_start, colNames{j}, 'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', 'left');
end
line([0 1], [y_start+0.2 y_start+0.2], 'Color', 'k', 'LineWidth', 0.5);

% --- 循环绘制数据行与交替背景 ---
for i = 1:nParam-1
    y_current = y_start + i * row_height;
    
    % 绘制交替条纹背景 (奇数行浅灰色)
    if mod(i, 2) == 1
        patch([0 1 1 0], [y_current-0.5, y_current-0.5, y_current+0.3, y_current+0.3], ...
              [0.92 0.92 0.92], 'EdgeColor', 'none');
    end
    
    % 写入各列数据文本
    for j = 1:6
        text(x_pos(j), y_current, rowData{i, j}, 'FontSize', 11, 'HorizontalAlignment', 'left', 'Interpreter', 'none');
    end
end
% 表格底部封口线
line([0 1], [y_start + (nParam-1)*row_height + 0.3, y_start + (nParam-1)*row_height + 0.3], 'Color', 'k', 'LineWidth', 1.0);

% =========================================================================
% 4. 图像导出
% =========================================================================
drawnow;

% 导出为 PNG 高清格式
exportgraphics(f, 'inversion_statistics_report.png', 'Resolution', 300);
disp('图片已安全导出为: inversion_statistics_report.png');


% 导出为 PDF 矢量格式
% exportgraphics(f, 'inversion_statistics_report.pdf', 'ContentType', 'vector');
% disp('图片已安全导出为:  inversion_statistics_report.pdf');

disp('数据处理与绘图完成。');