function faultbian=changefaultbian(faultbian,gridpai)
sz=size(faultbian);
dex=1;
for k=1:size(gridpai,1)
    
gridc=gridpai(k,:);
faultbianc=faultbian(dex:dex+gridc(1)*gridc(2)-1,:,:);
faultbianc=reshape(faultbianc,gridc(1),gridc(2),sz(2),sz(3));
for j=1:gridc(2)
    if j==1
        for i=1:gridc(1)-1
            faultbianc(i,j,3,:)=(faultbianc(i,j,3,:)+faultbianc(i+1,j,1,:))/2;
            faultbianc(i+1,j,1,:)=faultbianc(i,j,3,:);
        end
    else
    for i=1:gridc(1)
       if i==1
           faultbianc(i,j,1,:)=(faultbianc(i,j,1,:)+faultbianc(i,j-1,2,:))/2;
           faultbianc(i,j-1,2,:)=faultbianc(i,j,1,:);
       else
           faultbianc(i,j,1,:)=(faultbianc(i,j,1,:)+faultbianc(i,j-1,2,:)+faultbianc(i-1,j,3,:)+faultbianc(i-1,j-1,4,:))/4;
           faultbianc(i,j-1,2,:)=faultbianc(i,j,1,:);
           faultbianc(i-1,j,3,:)=faultbianc(i,j,1,:);
           faultbianc(i-1,j-1,4,:)=faultbianc(i,j,1,:);
       end
    end
    faultbianc(gridc(1),j,3,:)=(faultbianc(gridc(1),j-1,4,:)+faultbianc(gridc(1),j,3,:))/2;
    faultbianc(gridc(1),j-1,4,:)=faultbianc(gridc(1),j,3,:);
    end
end
 for i=1:gridc(1)-1
     faultbianc(i,gridc(2),4,:)=(faultbianc(i,gridc(2),4,:)+faultbianc(i+1,gridc(2),2,:))/2;
     faultbianc(i+1,gridc(2),2,:)=faultbianc(i,gridc(2),4,:);
 end
faultbianc=reshape(faultbianc,gridc(1)*gridc(2),sz(2),sz(3));
faultbian(dex:dex+gridc(1)*gridc(2)-1,:,:)=faultbianc;
dex=dex+gridc(1)*gridc(2);
end
end