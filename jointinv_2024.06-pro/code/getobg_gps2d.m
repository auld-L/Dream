function [slipg,Ggps,weit_gps,locagps] = getobg_gps2d(weight,obfile,sumob,...
    locasub,locadep,fault,faultall,gridsize,trup_con,rakevar,typ)

fault0 = fault;
fault=faultall(:,4:5);
fault(:,3)=fault0(3);

if weight
    load(obfile);
    locagps = gps(:,1:2);
    if typ==0
       slipg = gps(:,3:4); 
    else
    slipg = gps(:,3:5);
    end
    weit_gps = weight*sqrt(sumob)/sqrt(slipg(:)'*slipg(:));
    if rakevar==1
        [Ggps,~] = jt_gpsG3d(locagps,locasub,locadep,fault,gridsize,trup_con);
    elseif rakevar==0
        [Ggps,~] = jt_gpsG2(locagps,locasub,locadep,fault,gridsize,trup_con);
    end
    if typ==0
        Ggps(end-size(slipg,1)+1:end,:)=[];
    end
    Ggps = Ggps/3e16/prod(gridsize);
else
    slipg = [];
    Ggps = [];
    weit_gps = 0;
    locagps = [];
end
end