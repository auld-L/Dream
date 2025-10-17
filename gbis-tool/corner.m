clc; clear;

% --- 1. 数据加载 ---
% ！！！注意：请确保您在这里加载了 "另一个数据" 的 .mat 文件
load('invert_1_2_F.mat', 'invResults'); % ！！！请替换为您的文件名

% 将9个参数的数据加载到元胞数组中
data = invResults.mKeep';
num_models = size(data, 1);
param_count = 9; % 总共有9个参数
all_data = cell(1, param_count);
for i = 1:param_count
    all_data{i} = data(2:num_models, i);
end

% --- 2. 数据稀疏化 ---
n_total = length(all_data{1});
n_target = 10000; % 保持10000个点用于绘图

if n_total <= n_target
    idx = 1:n_total;
else
    step = floor(n_total / n_target);
    idx = 1:step:n_total;
end

% 将稀疏化后的数据存储在新的元胞数组中
thinned_data = cell(1, param_count);
for i = 1:param_count
    thinned_data{i} = all_data{i}(idx);
end

% --- 3. 定义元数据（名称和绘图限制） ---
% ！！！注意：请根据您新图像的坐标轴范围，更新下面的 'limits' 数组
param_names = {'Length', 'Width', 'Depth', 'Dip', 'Strike', 'X', 'Y', 'SS', 'DS'};

% ！！！这里的 limits 是根据您上一张图估算的，请务必修改
limits = [
    4300, 5000;    % 1: Length
    9500, 11000;   % 2: Width
    2500, 2800;    % 3: Depth (Z)
    -68, -64;      % 4: Dip
    231, 234;      % 5: Strike
    1900, 2300;    % 6: X
    500, 800;      % 7: Y
    -0.15, 0.1;    % 8: SS
    -0.9, -0.7    % 9: DS
];

% --- 4. 循环绘图 (9x9 网格) ---
fig = figure('Position', [100, 100, 1600, 1200]);

n_grid = 9; % 9个参数，9x9网格

for r = 1:n_grid % 循环行
    for c = 1:r  % 循环列
        
        subplot_idx = (r-1) * n_grid + c;
        ax = subplot(n_grid, n_grid, subplot_idx);
        
        ax.FontSize = 8; 

        % --- 核心绘图逻辑 ---
        if r == c
            plot_histogram(thinned_data{r}, limits(r, :));
        else
            x_idx = c;
            y_idx = r;
            plot_kde_scatter(thinned_data{x_idx}, thinned_data{y_idx});
            xlim(ax, limits(x_idx, :));
            ylim(ax, limits(y_idx, :));
        end
        
        box on;

        % --- 设置标签和刻度 ---
        if c == 1
            if r == 1 
                ylabel('Frequency', 'FontSize', 10);
            else
                ylabel(param_names{r}, 'FontSize', 10);
                yticks(ax, limits(r, :));
            end
        else
            yticks(ax, []); 
        end
        
        if r == n_grid
            xlabel(param_names{c}, 'FontSize', 10);
            xticks(ax, limits(c, :));
        else
            xticks(ax, []);
        end
    end
end

% --- 5. 保存图像 ---
disp('正在保存图像...');
exportgraphics(gcf, 'Corner_Plot_Fixed_v3.png', 'Resolution', 300);
disp('图像已成功保存为 Corner_Plot_Fixed_v3.png');


% --- 6. 本地辅助函数 ---

function plot_histogram(data, limits)
    if any(~isfinite(data))
        return; 
    end
    
    num_bins = 50;
    
    padding = (limits(2) - limits(1)) * 0.01;
    if padding == 0
        padding = 1e-6;
    end
    padded_limits = [limits(1) - padding, limits(2) + padding];
    
    bin_edges = linspace(padded_limits(1), padded_limits(2), num_bins + 1);

    histogram(data, bin_edges, ...
        'FaceColor', [0.529, 0.808, 0.922], ... 
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.7);

    hold on;
    
    % ======================================================
    % **修正 1：只计算落在 'limits' 范围内数据的均值**
    % ======================================================
    % 
    filtered_data = data(data >= limits(1) & data <= limits(2) & isfinite(data));
    
    if ~isempty(filtered_data)
        mean_val = mean(filtered_data);
    else
        mean_val = mean(data, 'omitnan'); % 
    end
    
    y_limits = ylim; 
    
    plot([mean_val, mean_val], y_limits, 'r-', 'LineWidth', 1.5);
    
    hold off;
    
    xlim(limits);
    ylim([0, y_limits(2)]);
end

function plot_kde_scatter(x_data, y_data)
    if any(~isfinite(x_data)) || any(~isfinite(y_data))
        return; 
    end

    data_xy = [x_data, y_data]; 
    [f, ~] = ksdensity(data_xy, data_xy, 'Function', 'pdf');
    [f_sorted, sort_idx] = sort(f);
    x_sorted = x_data(sort_idx);
    y_sorted = y_data(sort_idx);
    
    % ======================================================
    % **修正 2：减小散点图的点大小 (从 10 改为 5)**
    % ======================================================
    scatter(x_sorted, y_sorted, 7, f_sorted, 'filled');
end