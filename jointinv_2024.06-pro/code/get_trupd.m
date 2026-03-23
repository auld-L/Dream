function [trup,trup_con]=get_trupd(faultall,source,gridsize,lensub,lenrup,vrup,srate,biaoall,joinpoint)
%-------------------
trup=zeros(size(faultall,1),1);
trup_con=ones([lensub,size(faultall,1)]);
nmax=max(biaoall(:,1));
for k=1:nmax
    tshift=joinpoint(k,3);
    source=joinpoint(k,(1:2));
for i=1:size(faultall,1) 
    if biaoall(i,1)==k 
        x=biaoall(i,2);
        y=biaoall(i,3);
%         trup(i,j)=sqrt((abs((i-source(1))-0.5).*gridsize(1)).^2+...
%             (abs((j-source(2))-0.5).*gridsize(2)).^2)./vrup.*srate;
        trup(i)=round(tshift+sqrt((abs((x-source(1))).*gridsize(1)).^2+...
            (abs((y-source(2))).*gridsize(2)).^2)./vrup)*srate;
        trup_con(1:min(round(trup(i))+1,lensub),i)=0;
%         if i==sizemat(1)||i==1||j==1||j==sizemat(2)
%             trup_con(:,i,j)=0;%  edge to 0
%         end
        if biaoall(i,4)==0
            trup_con(:,i)=0;
        end
        trup_con(min(round(trup(i))+lenrup+2,lensub):end,i)=0;
    else
        continue
    end
end
end
trup_con=trup_con(:);