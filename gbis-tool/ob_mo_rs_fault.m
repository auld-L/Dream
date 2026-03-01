clear; close all;
% 1. 加载反演结果
load("invert_1_2_3_F.mat");

% =========================================================================
% 2. 提前计算断层线几何信息 (从 invResults 提取)
% =========================================================================
A = invResults.optimalmodel;
strike = A{1}(5,1); 
dip = A{1}(4,1); 
X = A{1}(6,1)/1000; 
Y = A{1}(7,1)/1000; 
xy_center = single([X; Y]);

% 利用参考点经纬度计算断层中点
point = geo.referencePoint; 
ll_center = local2llh(xy_center, point);
lon0 = ll_center(1,1); 
lat0 = ll_center(2,1); 
origin = [lon0, lat0];

% 线段总长度一半（单位：km）
L_km = 15; 
azimuth_deg = strike;
dx = L_km * sind(azimuth_deg); 
dy = L_km * cosd(azimuth_deg);

% 构造两端点的局部坐标并转换为经纬度
xy_ends = [ dx, -dx; dy, -dy ];   
llh_ends = local2llh(xy_ends, origin);  
lon1 = llh_ends(1,1); lat1 = llh_ends(2,1); 
lon2 = llh_ends(1,2); lat2 = llh_ends(2,2);

% =========================================================================
% 3. 加载色标配置
% =========================================================================
try
    cmap.seismo = colormap_cpt('GMT_seis.cpt', 100);    % GMT 'Seismo' colormap
    cmap.redToBlue = colormap_cpt('polar.cpt', 100);    % Red to Blue colormap
catch
    disp('未检测到 cpt 色标文件，自动应用 MATLAB 默认 jet 色标');
    cmap.seismo = jet(100);
    cmap.redToBlue = jet(100);
end

% =========================================================================
% 4. 动态循环读取 InSAR 数据、正演计算并绘图
% =========================================================================
num_datasets = length(insar); % 自动获取数据集数量 (例如 3 个)

% 根据数据集数量动态调整画布高度 (每个数据集给 350 像素高度)
fig_height = max(800, 350 * num_datasets); 
figure('Position', [100, 100, 1500, fig_height], 'Name', 'InSAR Obs vs Model vs Res');

for i = 1:num_datasets
    loadedData = load(insar{i}.dataPath);     
    convertedPhase = (loadedData.Phase/(4*pi))*insar{i}.wavelength;    
    los = -convertedPhase;  % Convert phase to LoS displacement
    
    Heading = loadedData.Heading;
    Inc = loadedData.Inc;
    
    ll = [single(loadedData.Lon) single(loadedData.Lat)];   
    xy = llh2local(ll', geo.referencePoint);    
    nPointsThis = size(ll,1);   
    xy = double([[1:nPointsThis]',xy'*1000]);   
    
    lon = ll(:,1);
    lat = ll(:,2);

    color_max = 0.4;
    color_min = -0.4;
    res_max = 0.15;   % 残差的极值范围
    res_min = -0.15;

    % 处理 Offset 和 Ramp
    constOffset = 0; xRamp = 0; yRamp = 0;
    if insar{i}.constOffset == 'y'
        constOffset = invResults.model.mIx(end);
        invResults.model.mIx(end) = invResults.model.mIx(end)+1;
    end
    if insar{i}.rampFlag == 'y'
         xRamp = invResults.model.mIx(end);
        yRamp = invResults.model.mIx(end)+1;
        invResults.model.mIx(end) = invResults.model.mIx(end)+2;
    end

    % 正演计算模拟值 (Model)
    [path, name, ext] = fileparts(insar{i}.dataPath);
    modLos = forwardInsarModel(insar{i},xy,invpar,invResults,modelInput,geo,Heading,Inc,constOffset,xRamp,yRamp); 
    residual = los - modLos';

    % --------- 动态计算各子图位置编号 ---------
    idx_obs = (i - 1) * 3 + 1;
    idx_mod = (i - 1) * 3 + 2;
    idx_res = (i - 1) * 3 + 3;

    % 1. 观测图 (Observe)
    subplot(num_datasets, 3, idx_obs);
    scatter(lon, lat, 30, los, 'filled');
    axis equal; axis tight; colormap(gca, cmap.redToBlue); caxis([color_min, color_max]); colorbar;
    title(sprintf('Subplot %d: observe %s', idx_obs, name), 'Interpreter', 'none'); 
    hold on; plot([lon1 lon2], [lat1 lat2], 'k-', 'LineWidth', 2.5); plot(lon0, lat0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6); hold off;

    % 2. 模拟图 (Model)
    subplot(num_datasets, 3, idx_mod);
    scatter(lon, lat, 30, modLos', 'filled');
    axis equal; axis tight; colormap(gca, cmap.redToBlue); caxis([color_min, color_max]); colorbar;
    title(sprintf('Subplot %d: model %s', idx_mod, name), 'Interpreter', 'none'); 
    hold on; plot([lon1 lon2], [lat1 lat2], 'k-', 'LineWidth', 2.5); plot(lon0, lat0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6); hold off;
   
    % 3. 残差图 (Residual)
    subplot(num_datasets, 3, idx_res);
    scatter(lon, lat, 30, residual, 'filled');
    axis equal; axis tight; colormap(gca, cmap.redToBlue); caxis([res_min, res_max]); colorbar;
    title(sprintf('Subplot %d: residual %s', idx_res, name), 'Interpreter', 'none'); 
    hold on; plot([lon1 lon2], [lat1 lat2], 'k-', 'LineWidth', 2.5); plot(lon0, lat0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6); hold off;

end

% 1. 强制 MATLAB 将所有图层渲染到屏幕上，不要偷懒
drawnow; 

% 2. 让程序暂停 2 秒钟，给电脑的显卡和 Java 引擎一点缓冲时间
pause(2); 

% 3. 使用最底层的 print 函数强制导出 300 dpi 的高清图
print(gcf, 'ob_mo_rs_with_fault.png', '-dpng', '-r300');

% =========================================================================
% 5. 命令行输出断层端点信息
% =========================================================================
fprintf('\n==================================================\n');
fprintf('Start Point:    lat = %.4f, lon = %.4f\n', lat1, lon1);
fprintf('End Point:      lat = %.4f, lon = %.4f\n', lat2, lon2);
fprintf('Middle Point:   lat = %.4f, lon = %.4f\n', lat0, lon0);
fprintf('Fault line distance = %.2f km, dip = %.2f°, Strike = %.2f°\n', L_km*2, dip, strike);
fprintf('==================================================\n');
disp('绘图完成！图片 ob_mo_rs_with_fault.png 已保存在当前文件夹。');