%
%这个脚本是调用local2llh.m
%先获取搜索得到的X，Y距离，再利用参考点经纬度计算搜索到的断层中点的经纬度
%之后以该点为中心，在走向的方向上向两端各延伸一定的距离（L_km）
%最后求取这条线段的首尾的经纬度
%

clc;clear;

data = load("invert_1_2_F.mat");

A = data.invResults.optimalmodel;

strike = A{1}(5,1);
dip = A{1}(4,1);
X = A{1}(6,1)/1000;
Y = A{1}(7,1)/1000;
XY=[X;Y];
xy = single(XY);

point = data.geo.referencePoint;
ll = local2llh(xy,point);



% 起点经纬度（单位：度）
lon0 = ll(1,1);
lat0 = ll(2,1);
origin = [lon0, lat0];

% 线段总长度一半（单位：km）
L_km = 15;

% 方位角（顺时针从正北起，单位：度）
azimuth_deg = strike;

% 将方位角转换为平面坐标方向（正北为y轴正方向）
% MATLAB中，x为东西向，y为南北向
% 所以，局部坐标为（东西，南北）
dx = L_km * sind(azimuth_deg);
dy = L_km * cosd(azimuth_deg);

% 构造两端点的局部坐标（单位km）
xy = [ dx, -dx;
       dy, -dy ];   % 每列是一个点

% 调用 local2llh 进行转换
llh = local2llh(xy, origin);  % 返回 [lon; lat]

% 提取经纬度
lon1 = llh(1,1); lat1 = llh(2,1);
lon2 = llh(1,2); lat2 = llh(2,2);

% 绘图
figure;
plot([lon1 lon2], [lat1 lat2], 'b-', 'LineWidth', 2); hold on;
plot(lon0, lat0, 'ko', 'MarkerFaceColor', 'k');  % 中心点
grid on;
xlabel('Longitude');
ylabel('Latitude');
title_str = sprintf('Line %.2f km, Strike = %.2f°', L_km*2, strike);
title(title_str);
axis equal;

% 显示两端点经纬度（保留四位小数）
fprintf('Start Point:  lat = %.4f, lon = %.4f\n', lat1, lon1);
fprintf('End Point:    lat = %.4f, lon = %.4f\n', lat2, lon2);
fprintf('middle Point:    lat = %.4f, lon = %.4f\n', lat0, lon0);
fprintf('fualt line distance = %.2fkm,dip = %.2f°, Strike = %.2f°\n', L_km*2,dip, strike);