function matching_gpsd(lon_gps,lat_gps,locagps,numth,epi,faultall,zslip,slipg,syng,faultbian)
if isempty(lon_gps) || isempty(lat_gps)
    plt_lon = [min(locagps(:,2)),max(locagps(:,2))] + [-0.5,0.5];
    plt_lat = [min(locagps(:,1)),max(locagps(:,1))] + [-0.5,0.5];
else
    plt_lon = lon_gps;
    plt_lat = lat_gps;
end

figure
plt_area(plt_lat,plt_lon);
slip=sqrt(zslip(:,1).^2+zslip(:,2).^2);
slipmax=max(slip);
slipmax0=max(slip);
% slipmax=70;
% numth=7;
% slip(slip>slipmax)=slipmax-0.001;
% n=numth;
% color=jet_zh(n,2);
% colormap(color);
% c=colorbar();
% set(c,'ytick',0:1/7:1);
% set(c,'yticklabel',{'0','10','20','30','40','50','60','70 m'});
%drawcolor=(floor(slip/(slipmax+0.001)*n))+1;
slipmax=10;
slip(slip>10)=9.99;
n=numth;
color=jet_zh(n,2);
colormap(color);
c=colorbar();
set(c,'ytick',0:0.1:1);
set(c,'yticklabel',{'0','1','2','3','4','5','6','7','8','9','10 m'});
drawcolor=(floor(slip/10*n))+1;
hold on
for i=size(faultall,1)-16+1:size(faultall,1)
    
    lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)];
    lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)];

    fill(lon,lat,color(drawcolor(i),:));
    %plot3(faultall(i,2),faultall(i,1),faultall(i,3),'ro');
end

for i=1:size(faultall,1)-16
    lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)];
    lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)];

    fill(lon,lat,color(drawcolor(i),:));
    %plot3(faultall(i,2),faultall(i,1),faultall(i,3),'ro');
end






hold on
quiver(locagps(:,2),locagps(:,1),slipg(:,1),slipg(:,2),1,'k');
syng = reshape(syng,size(slipg));
quiver(locagps(:,2),locagps(:,1),syng(:,1),syng(:,2),1,'r');
load coasts_large.mat
plot(ncst(:,1),ncst(:,2),'k');
%plot(epi(2),epi(1),'kp','markersize',20,'markerfacecolor','w');
set(gca,'dataaspectratio',[1,cosd(epi(1)),1]);

lontick = ceil(plt_lon(1)):2:floor(plt_lon(2));
lattick = ceil(plt_lat(1)):2:floor(plt_lat(2));
[lonlabel,latlabel] = tick2label(lontick,lattick);
set(gca,'xtick',lontick);set(gca,'xticklabel',lonlabel);
set(gca,'ytick',lattick);set(gca,'yticklabel',latlabel);
set(gca,'fontsize',10);

figure;
plt_area(plt_lat,plt_lon);
color=jet_zh(n,2);
colormap(color);
c=colorbar();
set(c,'ytick',0:0.1:1);
set(c,'yticklabel',{'0','1','2','3','4','5','6','7','8','9','10 m'});
% set(c,'ytick',0:1/7:1);
% set(c,'yticklabel',{'0','10','20','30','40','50','60','70 m'});
drawcolor=(floor(slip/(slipmax+0.001)*n))+1;
hold on
for i=size(faultall,1)-16+1:size(faultall,1)
    lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)];
    lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)];

    fill(lon,lat,color(drawcolor(i),:));
    %plot3(faultall(i,2),faultall(i,1),faultall(i,3),'ro');
end
for i=1:size(faultall,1)-16
    lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)];
    lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)];

    fill(lon,lat,color(drawcolor(i),:));
    %plot3(faultall(i,2),faultall(i,1),faultall(i,3),'ro');
end
quiver(locagps(:,2),locagps(:,1),zeros(size(slipg,1),1),slipg(:,3),1,'k');
quiver(locagps(:,2),locagps(:,1),zeros(size(slipg,1),1),syng(:,3),1,'r');
plot(ncst(:,1),ncst(:,2),'k');
%plot(epi(2),epi(1),'kp','markersize',20,'markerfacecolor','w');
set(gca,'dataaspectratio',[1,cosd(epi(1)),1]);
lontick = ceil(plt_lon(1)):2:floor(plt_lon(2));
lattick = ceil(plt_lat(1)):2:floor(plt_lat(2));
[lonlabel,latlabel] = tick2label(lontick,lattick);
set(gca,'xtick',lontick);set(gca,'xticklabel',lonlabel);
set(gca,'ytick',lattick);set(gca,'yticklabel',latlabel);
set(gca,'fontsize',10);
end
