function q_patch_3datasets()

clc; clear; close all;

%==============================
% 1. 读取数据
%==============================
load('invert_1_2_3_F.mat');   % 加载包含 3 个数据集的最新反演结果

origin = geo.referencePoint;   % [lon lat]
num_datasets = length(insar);  % 自动获取数据集数量

%==============================
% 2. 创建单个图形窗口
%==============================
% 加宽窗口 (宽度设为 1600)，以容纳 3 个子图并排显示
figure('Position', [100, 100, 1600, 500]);  
set(gcf, 'Name', 'InSAR LOS Displacement Comparison', 'NumberTitle', 'off');

%==============================
% 3. 预读取数据，确定统一的颜色范围
%==============================
% 推荐手动固定范围，这样 3 张图的颜色对比才具有绝对的物理意义
% 你可以根据实际最大形变量（比如 -0.2 到 0.2）在此处随时修改
cmin = -0.3; 
cmax = 0.3;

%==============================
% 4. 动态循环处理所有数据集
%==============================
for k = 1:num_datasets

    %--------------------------
    % 获取原始文件名 (例如 A, D, ALOS)
    %--------------------------
    [~, name, ~] = fileparts(insar{k}.dataPath);

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
    subplot(1, num_datasets, k);  % 1行 N列，第k个子图
    
    % 绘制散点图
    scatter(lon, lat, 15, dLos, 'filled');
    
    % 设置图形属性
    axis equal; axis tight;
    grid on;
    colormap(jet);
    caxis([cmin cmax]);   % 强制使用统一颜色范围
    hcb = colorbar;
    ylabel(hcb, 'LOS displacement (m)');
    
    xlabel('Longitude (°)');
    ylabel('Latitude (°)');
    
    % 标题自动使用 A, D, ALOS 等文件名
    title(sprintf('Data %d: %s', k, name), 'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'none');
    
    % 添加边界框和调整字体
    box on;
    set(gca, 'FontSize', 11, 'LineWidth', 1);
    
    % 在左上角添加数据点数标注 (可以直观检查降采样效果)
    text(0.02, 0.98, sprintf('N = %d', length(lon)), ...
         'Units', 'normalized', 'FontSize', 10, ...
         'VerticalAlignment', 'top', ...
         'BackgroundColor', 'white', 'Margin', 2, 'EdgeColor', 'k');
    
    % 在左下角添加极值统计信息
    stats_text = sprintf('Max: %.4f m\nMin: %.4f m', max(dLos), min(dLos));
    text(0.02, 0.02, stats_text, ...
         'Units', 'normalized', 'FontSize', 9, ...
         'VerticalAlignment', 'bottom', ...
         'BackgroundColor', 'white', 'Margin', 2, 'EdgeColor', 'k');

    %--------------------------
    % 6. 保存四叉树降采样结果到 txt
    %--------------------------
    N = length(lon);
    sigma = 0.001 * ones(N, 1); % 设定位移的标准差先验 (GBIS 默认占位)

    out = [lat, lon, dLos, sigma];

    % 文件名自动适配为 insar_A_los_ll.txt 等
    outfile = sprintf('insar_%s_los_ll.txt', name);
    fid = fopen(outfile, 'w');
    fprintf(fid, '%.6f %.6f %.6f %.4f\n', out.');
    fclose(fid);

    fprintf('已将 %d 个采样点保存至 -> %s\n', N, outfile);

end

%==============================
% 7. 添加全局主标题
%==============================
sgtitle('Quadtree Subsampled InSAR LOS Displacements', 'FontSize', 15, 'FontWeight', 'bold');

fprintf('\n=== 数据提取与图形显示完成 ===\n');
fprintf('• %d 个 InSAR 数据集的降采样结果已导出\n', num_datasets);
fprintf('• 图形使用统一颜色范围: [%.2f, %.2f]\n', cmin, cmax);

end