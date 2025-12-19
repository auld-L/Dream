function q_patch()

clc; clear;

%==============================
% 1. 读取数据
%==============================
load('invert_1_2_F.mat');   % insar, geo, invResults

origin = geo.referencePoint;   % [lon lat]

%==============================
% 2. 创建单个图形窗口
%==============================
figure('Position', [100, 100, 1200, 500]);  % 宽窗口，便于并排显示
set(gcf, 'Name', 'InSAR LOS Displacement Comparison', 'NumberTitle', 'off');

%==============================
% 3. 预读取数据，确定统一的颜色范围
%==============================
all_dLos = [];  % 收集所有dLos值，用于统一颜色范围

for k = 1:2
    dLos = insar{k}.dLos(:);
    all_dLos = [all_dLos; dLos];
end

% 确定统一的颜色范围（可以选择自动或手动）
% 方法1：自动根据数据范围
% cmin = min(all_dLos);
% cmax = max(all_dLos);

% 方法2：手动设置（推荐，确保可比性）
cmin = -0.3;
cmax = 0.3;

%==============================
% 4. 循环处理 insar{1}, insar{2} - 使用subplot
%==============================
for k = 1:2

    %--------------------------
    % 局部坐标 → 经纬度
    %--------------------------
    x = insar{k}.obs(:,1) / 1000;   % m → km (East)
    y = insar{k}.obs(:,2) / 1000;   % m → km (North)

    xy = single([x'; y']);
    llh = local2llh(xy, origin);

    lon = llh(1,:)';
    lat = llh(2,:)';

    dLos = insar{k}.dLos(:);

    %--------------------------
    % 5. 创建子图
    %--------------------------
    subplot(1, 2, k);  % 1行2列，第k个子图
    
    % 绘制散点图
    scatter(lon, lat, 8, dLos, 'filled');
    
    % 设置图形属性
    axis equal;
    grid on;
    colormap(jet);
    caxis([cmin cmax]);   % 使用统一的颜色范围
    hcb = colorbar;
    ylabel(hcb, 'LOS displacement (m)');
    
    xlabel('Longitude (°)');
    ylabel('Latitude (°)');
    title(sprintf('InSAR %d: LOS displacement', k), 'FontSize', 12, 'FontWeight', 'bold');
    
    % 添加边界框和调整字体
    box on;
    set(gca, 'FontSize', 11, 'LineWidth', 1);
    
    % 可选：添加数据点数标注
    text(0.02, 0.98, sprintf('N = %d', length(lon)), ...
         'Units', 'normalized', 'FontSize', 10, ...
         'VerticalAlignment', 'top', ...
         'BackgroundColor', 'white', 'Margin', 2);
    
    % 可选：添加统计信息
    stats_text = sprintf('Mean: %.4f m\nStd: %.4f m', mean(dLos), std(dLos));
    text(0.02, 0.02, stats_text, ...
         'Units', 'normalized', 'FontSize', 9, ...
         'VerticalAlignment', 'bottom', ...
         'BackgroundColor', 'white', 'Margin', 2);

    %--------------------------
    % 6. 保存 txt
    %--------------------------
    N = length(lon);
    sigma = 0.001 * ones(N, 1);

    out = [lat, lon, dLos, sigma];

    outfile = sprintf('insar%d_los_ll.txt', k);
    fid = fopen(outfile, 'w');
    fprintf(fid, '%.6f %.6f %.6f %.4f\n', out.');
    fclose(fid);

    fprintf('Saved %d points to %s\n', N, outfile);

end

%==============================
% 7. 添加主标题和调整布局
%==============================
% 添加主标题
sgtitle('InSAR LOS Displacement Comparison', 'FontSize', 14, 'FontWeight', 'bold');

% 调整子图位置和间距
h = gcf;
for k = 1:2
    subplot(1, 2, k);
    pos = get(gca, 'Position');
    % 调整位置：左侧子图靠左，右侧子图靠右
    if k == 1
        set(gca, 'Position', [0.07, 0.15, 0.38, 0.75]);
    else
        set(gca, 'Position', [0.55, 0.15, 0.38, 0.75]);
    end
end

fprintf('\n=== 图形显示完成 ===\n');
fprintf('• 两个InSAR图像显示在同一窗口\n');
fprintf('• 使用统一的颜色范围: [%.2f, %.2f]\n', cmin, cmax);
fprintf('• 数据已保存为 insar1_los_ll.txt 和 insar2_los_ll.txt\n');

end