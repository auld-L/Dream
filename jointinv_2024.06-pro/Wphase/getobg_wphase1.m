function [ob,g,loca,mm,srate,leng,ga] = getobg_wphase1(weight,ifrecal,obfile,epi,depth,fault,grid,gridsize,source,gpath,miu,band,isdis)
%(weight,ifrecal,obfile,depth,grid,gpath,miu,band,isdis)
% 获得远震记录的观测波形，计算格林函数，并进行滤波
if weight
    if ifrecal
        load(obfile);
        
%         nsta = size(ob,2);
%         dda=[repmat(depth,[size(loca,1),1]),da];
        [locasub,dep] = get_subloca(fault,grid([2,1]),gridsize([2,1]),[1,source([2,1])],loca,epi);
        dep=dep+depth-dep(source(1));
        nsta = size(loca,1);
        nsub = size(locasub,1);
        locasuba = repmat(locasub,[nsta,1]);
        depa = repmat(dep,[nsta,1]);
        locaa = repmat_zh(loca,nsub);
        daa = da_zh(locaa,locasuba,2);
        dda = [depa,daa];
        gt=zeros(size(ob,1),6,nsub*nsta);
        tic
        for i=1:6
            M=zeros(6,1);M(i)=1;
            gtm = seekg_wang(gpath,dda,M,srate);
            t=round(get_time_new(daa(:,1)/111.19492664455875,depth,'P')*srate);
            for j=1:size(gtm,3)
                %gt(:,i,j)=gtm(round(t(j)-leng_before*srate):round(t(j)+(leng-leng_before)*srate-1),1,j);
                %gt(:,i,j)=gtm(round(t(j)-leng_before*srate):round(t(j)+(leng-leng_before)*srate),1,j);
                gt(:,i,j)=gtm(round(t(j)-leng_before*srate):round(t(j)-leng_before*srate)+size(ob,1)-1,1,j);
                ttt=round((leng_before+15*daa(j,1)/111.19492664455875)*srate);
                gt(ttt+1:end,i,j)=0;
%                 tap=sind(90:90/(50*srate):1);
%                 gt(ttt-50*srate:end,i,j)=gt(ttt-50*srate:end,i,j).*tap;
            end
        end
        gt=reshape(gt,size(ob,1),6,nsub,nsta);
        for i=1:nsub
            gt(:,:,i,:)=gt(:,:,i,:)*miu(i)/3e10;
        end
        g=gt;
        
%         if depth<100
%             t=round(get_time_new(da(:,1)/111.1949,depth,'P')*srate);
%         else
%             t=round(dbgrn_get_time(da(:,1)/111.1949,depth,'P')*srate);
%         end
%         g=zeros(650*srate,6,nsta);
%         for i=1:nsta
%             g0=gt(t(i)-leng_before*srate:t(i)+(650-leng_before)*srate-1,:,i);
% %             g0=gt(t(i)-10*srate:t(i)+640*srate-1,:,i);
%             g(1:size(g0,1),:,i)=g0;
%         end
%         g=g*miu/3e10;
%         g(size(ob,1)+1:end,:,:)=[];
        
%         gt = g;
%         for i = 1:prod(grid)-1
%             gt = cat(4,gt,g);
%         end
%         g = permute(gt,[1,2,4,3]);
        toc
        if isdis
            g = cumsum(g)/srate;
            ob = cumsum(ob)/srate;
        end
        mm = mm(:,1:4);
        disp('Wave and Green''s function of wphase record have been calculated!');

    [bb,aa] = butter(4,band*2/srate);
    ob = filter(bb,aa,ob);
    g = filter(bb,aa,g);
    dist_daa=reshape(daa(:,1),nsub,nsta);
    for j=1:nsta
        for k=1:nsub
                
                ttt=round((leng_before+15*dist_daa(k,j)/111.19492664455875)*srate);
                g(ttt+1:end,:,k,j)=0;
%                 tap=sind(90:90/(50*srate):1);
%                 gt(ttt-50*srate:end,i,j)=gt(ttt-50*srate:end,i,j).*tap;
        end
    end
    
    for j=1:size(ob,2)
        ttt=round((leng_before+15*da(j,1)/111.19492664455875)*srate);
        ob(ttt+1:end,j)=0;
    end
            save obg_wphase.mat ob g loca mm srate leng
    else
        load('obg_wphase.mat');
        disp('Wave and Green''s function of wphase record have been loaded!');
    end
else
    ob = [];g = [];loca = [];mm = [];srate = 0;leng = 0;
end
end
