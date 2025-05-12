clear
%读取lltn文件
data = dlmread("dem_sample1.lltn");
%取得lltn文件内第三列第四列的值

E = data(:,4);
N = data(:,5);
U = data(:,6);
%计算arctan（E/N）
atan_values = atan2(E,N);
%弧度转角度，这是los向与北方向的夹角，顺时针为正，逆时针为负
%加90度是换成飞行方向与北方向的夹角
Heading = rad2deg(atan_values)+90;
%求平均值
% average_azi = mean(azimuth)

%求入射角
result = zeros(size(data,1),1);
for i = 1:size(data, 1)
    sum_of_squares = sqrt(E(i)^2 + N(i)^2);
    result(i) = atan2(U(i),sum_of_squares);
end

Inc =  90-rad2deg(result);
L = length(Inc);
wavelength = 0.056* ones(L, 1);
% average_inc = mean(incidence)
load('qt_pre.txt');
Lon=qt_pre(:,1);
Lat=qt_pre(:,2);
los=qt_pre(:,3)/1000;
save('insar', 'Lon','Lat','los', 'Inc');
