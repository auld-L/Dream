function [] = faultslip_pcolor3d(faultall,faultbian,gridsize,epidex,zslip,numth)
nj=12;
njt=5;
w1=1.5;
w2=0.5;
cj=[0.3,0.3,0.3];
bili=1.5;
dlat=-0.4;
dlon=1;
slip=sqrt(zslip(:,1).^2+zslip(:,2).^2);
slipmax=max(slip);
slip(slip>10)=9.99;
n=numth;
color=jet_zh(n,2);
colormap(color);
c=colorbar();
set(c,'ytick',0:0.1:1);
set(c,'yticklabel',{'0','1','2','3','4','5','6','7','8','9','10 m'});
drawcolor=(floor(slip/10*n))+1;
hold on
for i=1:size(faultall,1)
    lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)];
    lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)];
    dep=[faultbian(i,1,3),faultbian(i,2,3),faultbian(i,4,3),faultbian(i,3,3),faultbian(i,1,3)];
    fill3(lon,lat,dep,color(drawcolor(i),:));
    %plot3(faultall(i,2),faultall(i,1),faultall(i,3),'ro');
end



grid on
set(gca,'Zdir','reverse');
set(gca,'dataaspectratio',[1,cosd(30),(pi/180*6371)]);
epi=faultall(epidex,1:3);
plot3(epi(2),epi(1),epi(3),'h','markerfacecolor','r','markersize',10,'markeredge','k');
for i=1:size(faultall,1)
    if slip(i)>=2
    rdot=faultall(i,1:3);
    rdot=rdot+[0.01,-0.01,-0.1];
    strike=faultall(i,4);
    dip=faultall(i,5);
    [~,dd]=cedge([0,0,rdot(3)],gridsize,strike,dip);
    deltr=min(gridsize)*(slip(i)/10)*2;
    rend0(1)=dd(1)/min(gridsize)*deltr*zslip(i,1)/slip(i)-dd(3)/min(gridsize)*deltr*zslip(i,2)/slip(i);
    rend0(2)=dd(2)/min(gridsize)*deltr*zslip(i,1)/slip(i)-dd(4)/min(gridsize)*deltr*zslip(i,2)/slip(i);
    rend0(3)=0.5*sind(dip)*deltr*zslip(i,2)/slip(i);
    rend0=rend0*bili;
    rend(1)=rdot(1)+rend0(1)/111.2;
    rend(2)=rdot(2)+rend0(2)/111.2/cosd(faultall(i,1));
    rend(3)=rdot(3)+rend0(3);
    plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'color',cj,'linewidth',w1);
    %plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'color',color(drawcolor(i),:),'linewidth',w2);
    rtmp=rend;
    ddd=[rend0(1)/111.2,rend0(2)/111.2/cosd(faultall(i,1)),rend0(3)]/nj;
    for j=1:njt
        plot3([rtmp(2),rtmp(2)-ddd(2)],[rtmp(1),rtmp(1)-ddd(1)],[rtmp(3),rtmp(3)-ddd(3)],'linewidth',w1*(1.5*(j-1)+njt)/njt,'color',cj);
        %plot3([rtmp(2),rtmp(2)-ddd(2)],[rtmp(1),rtmp(1)-ddd(1)],[rtmp(3),rtmp(3)-ddd(3)],'linewidth',w2*(1.5*(j-1)+njt)/njt,'color',color(drawcolor(i),:));
        rtmp=rtmp-ddd;
    end
    %quiver3(rdot(2),rdot(1),rdot(3)+0.1,rend0(2)/111.2/cosd(faultall(i,1)),rend0(1)/111.2,rend0(3),'linewidth',2,'color','k','MaxHeadSize',0.06,'Autoscalefactor',0.6);
    %quiver3(rdot(2),rdot(1),rdot(3)+0.1,rend0(2)/111.2/cosd(faultall(i,1)),rend0(1)/111.2,rend0(3),'linewidth',0.7,'color',color(drawcolor(i),:),'MaxHeadSize',0.6,'Autoscalefactor',0.05);
    %arrow3([rdot(2),rdot(1),rdot(3)],[rend(2),rend(1),rend(3)],'Headlength',0.1,'Headwidth',0.1);
    end
end
% for i=size(faultall,1)-16+1:size(faultall,1)
%     
%     lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)]+dlat;
%     lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)]+dlon;
%     dep=[faultbian(i,1,3),faultbian(i,2,3),faultbian(i,4,3),faultbian(i,3,3),faultbian(i,1,3)];
%     fill3(lon,lat,dep,color(drawcolor(i),:));
%     if slip(i)>=2
%     rdot=faultall(i,1:3)+[dlat,dlon,0];
%     rdot=rdot+[0.01,-0.01,-0.1];
%     strike=faultall(i,4);
%     dip=faultall(i,5);
%     [~,dd]=cedge([0,0,rdot(3)],gridsize,strike,dip);
%     deltr=min(gridsize)*(slip(i)/10)*2;
%     rend0(1)=dd(1)/min(gridsize)*deltr*zslip(i,1)/slip(i)-dd(3)/min(gridsize)*deltr*zslip(i,2)/slip(i);
%     rend0(2)=dd(2)/min(gridsize)*deltr*zslip(i,1)/slip(i)-dd(4)/min(gridsize)*deltr*zslip(i,2)/slip(i);
%     rend0(3)=0.5*sind(dip)*deltr*zslip(i,2)/slip(i)+0.1*sqrt(sum(rend0.^2));
%     rend0=rend0*bili;
%     rend(1)=rdot(1)+rend0(1)/111.2;
%     rend(2)=rdot(2)+rend0(2)/111.2/cosd(faultall(i,1));
%     rend(3)=rdot(3)+rend0(3);
%     plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'color',cj,'linewidth',w1);
%     %plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'color',color(drawcolor(i),:),'linewidth',w2);
%     rtmp=rend;
%     ddd=[rend0(1)/111.2,rend0(2)/111.2/cosd(faultall(i,1)),rend0(3)]/nj;
%     for j=1:njt
%         plot3([rtmp(2),rtmp(2)-ddd(2)],[rtmp(1),rtmp(1)-ddd(1)],[rtmp(3),rtmp(3)-ddd(3)],'linewidth',w1*(1.5*(j-1)+njt)/njt,'color',cj);
%         %plot3([rtmp(2),rtmp(2)-ddd(2)],[rtmp(1),rtmp(1)-ddd(1)],[rtmp(3),rtmp(3)-ddd(3)],'linewidth',w2*(1.5*(j-1)+njt)/njt,'color',color(drawcolor(i),:));
%         rtmp=rtmp-ddd;
%     end
%     
%     
%     %plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'b','linewidth',1.5);
%     %quiver3(rdot(2),rdot(1),rdot(3)+0.1,rend0(2)/111.2/cosd(faultall(i,1)),rend0(1)/111.2,rend0(3),'linewidth',1.5,'color','k','MaxHeadSize',0.6,'Autoscalefactor',0.5);
%     %quiver3(rdot(2),rdot(1),rdot(3)+0.1,rend0(2)/111.2/cosd(faultall(i,1)),rend0(1)/111.2,rend0(3),'linewidth',0.7,'color',color(drawcolor(i),:),'MaxHeadSize',0.6,'Autoscalefactor',0.5);
%     %arrow3([rdot(2),rdot(1),rdot(3)],[rend(2),rend(1),rend(3)],'Headlength',0.1,'Headwidth',0.1);
%     end
% end
% for i=size(faultall,1)-16+1:2:size(faultall,1)-1
%     
%     lat=[faultbian(i,1,1),faultbian(i,2,1),faultbian(i,4,1),faultbian(i,3,1),faultbian(i,1,1)];
%     lon=[faultbian(i,1,2),faultbian(i,2,2),faultbian(i,4,2),faultbian(i,3,2),faultbian(i,1,2)];
%     dep=[faultbian(i,1,3),faultbian(i,2,3),faultbian(i,4,3),faultbian(i,3,3),faultbian(i,1,3)];
%     fill3(lon,lat,dep,color(drawcolor(i),:));
%     if slip(i)>=2
%     rdot=faultall(i,1:3);
%     rdot=rdot+[0.01,-0.01,-0.1];
%     strike=faultall(i,4);
%     dip=faultall(i,5);
%     [~,dd]=cedge([0,0,rdot(3)],gridsize,strike,dip);
%     deltr=min(gridsize)*(slip(i)/10)*2;
%     rend0(1)=dd(1)/min(gridsize)*deltr*zslip(i,1)/slip(i)-dd(3)/min(gridsize)*deltr*zslip(i,2)/slip(i);
%     rend0(2)=dd(2)/min(gridsize)*deltr*zslip(i,1)/slip(i)-dd(4)/min(gridsize)*deltr*zslip(i,2)/slip(i);
%     rend0(3)=0.5*sind(dip)*deltr*zslip(i,2)/slip(i)+0.1*sqrt(sum(rend0.^2));
%     rend0=rend0*bili;
%     rend(1)=rdot(1)+rend0(1)/111.2;
%     rend(2)=rdot(2)+rend0(2)/111.2/cosd(faultall(i,1));
%     rend(3)=rdot(3)+rend0(3);
%     plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'color',cj,'linewidth',w1);
%     %plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'color',color(drawcolor(i),:),'linewidth',w2);
%     rtmp=rend;
%     ddd=[rend0(1)/111.2,rend0(2)/111.2/cosd(faultall(i,1)),rend0(3)]/nj;
%     for j=1:njt
%         plot3([rtmp(2),rtmp(2)-ddd(2)],[rtmp(1),rtmp(1)-ddd(1)],[rtmp(3),rtmp(3)-ddd(3)],'linewidth',w1*(1.5*(j-1)+njt)/njt,'color',cj);
%         %plot3([rtmp(2),rtmp(2)-ddd(2)],[rtmp(1),rtmp(1)-ddd(1)],[rtmp(3),rtmp(3)-ddd(3)],'linewidth',w2*(1.5*(j-1)+njt)/njt,'color',color(drawcolor(i),:));
%         rtmp=rtmp-ddd;
%     end
%     
%     
%     %plot3([rdot(2),rend(2)],[rdot(1),rend(1)],[rdot(3),rend(3)],'b','linewidth',1.5);
%     %quiver3(rdot(2),rdot(1),rdot(3)+0.1,rend0(2)/111.2/cosd(faultall(i,1)),rend0(1)/111.2,rend0(3),'linewidth',1.5,'color','k','MaxHeadSize',0.6,'Autoscalefactor',0.5);
%     %quiver3(rdot(2),rdot(1),rdot(3)+0.1,rend0(2)/111.2/cosd(faultall(i,1)),rend0(1)/111.2,rend0(3),'linewidth',0.7,'color',color(drawcolor(i),:),'MaxHeadSize',0.6,'Autoscalefactor',0.5);
%     %arrow3([rdot(2),rdot(1),rdot(3)],[rend(2),rend(1),rend(3)],'Headlength',0.1,'Headwidth',0.1);
%     end
% end
% dot1(:)=faultbian(156,1,:);
% dot2(:)=faultbian(170,2,:);
% plot3([dot1(2),dot1(2)+dlon],[dot1(1),dot1(1)+dlat],[0,0],'k--');
% plot3([dot2(2),dot2(2)+dlon],[dot2(1),dot2(1)+dlat],[0,0],'k--');
% %plot3([rdot(2),rdot(2)+dlon],[rdot(1),rdot(1)+dlat],[0,0],'b');
% %quiver3(rdot(2),rdot(1),0,dlon,dlat,0,'linewidth',1,'color','k');
% 
% 
% slip01=[];
% latr=[30.5,33];
% lonr=[102.5,106];
%  load city.mat
% % % loca_shi=loca_xian;
% % % shi=xian;
% % dexshi1=intersect(find(loca_shi(:,1)<lonr(2)),find(loca_shi(:,1)>lonr(1)));
% % dexshi2=intersect(find(loca_shi(:,2)<latr(2)),find(loca_shi(:,2)>latr(1)));
% % dexshi=intersect(dexshi1,dexshi2);
% % locad=loca_shi(dexshi,:);
% % depshi=zeros(size(locad,1),1);
% % mmshi=shi(dexshi,4:15);
% % locad=locad(:,[]);
% % mmshi=mmshi([],:);
% % plot3(locad(:,1),locad(:,2),depshi,'ko');
% % text(locad(:,1),locad(:,2),mmshi);
% 
% loca_shi=loca_xian;
% shi=xian;
% dexshi1=intersect(find(loca_shi(:,1)<lonr(2)),find(loca_shi(:,1)>lonr(1)));
% dexshi2=intersect(find(loca_shi(:,2)<latr(2)),find(loca_shi(:,2)>latr(1)));
% dexshi=intersect(dexshi1,dexshi2);
% dexshi=dexshi([3,4,5,8,9,11,12,15,16,17,22,25,33]);
% dexshi([1,5,12,13],:)=[];
% locad=loca_shi(dexshi,:);
% depshi=zeros(size(locad,1),1);
% mmshi=shi(dexshi,4:15);
% dtext=[[0.2,0];[0,0.25];[0.4,0.1];[-0.05,0.45];[0,0];[0.02,0.3];[-0.3,0.2];[0,0];[0.05,-0.05]];
% deptext=([-5,-1,-1,-1,-1,-1,-1,-1,-1]);
% plot3(locad(:,1),locad(:,2),depshi,'ko','linewidth',1.2,'markersize',5);
% text(locad(:,1)+dtext(:,1),locad(:,2)+dtext(:,2),deptext,mmshi);
% %title(['maxslip ',num2str(slipmax),'m']);
% %aniseStar( [0,(source(1)-0.5)*gridsize(1)], gridsize(1)/2, 1, 'w');
% %pltstar(8,[0,(source(1)-0.5)*gridsize(1)],gridsize(1)/3,0.48,'w','k',1);
% view(-128,21);
% set(gca,'xtick',[103:1:106],'linewidth',1);
% set(gca,'ytick',[31:1:33]);
% set(gca,'xTickLabel',[num2str(get(gca,'xTick')'),['°';'°';'°';'°']]);
% set(gca,'yTickLabel',[num2str(get(gca,'yTick')'),['°';'°';'°']]);
% xlabel('lon.');
% ylabel('lat.');
%zlabel('depth(km)');
%zlim([-1 41]);
% xlim([102.99,106]);
set(gca,'fontsize',10);
set(gca,'ticklength',[0.015,0.015]);

end