function [slipsar,Gsar,weit_sar,locasar,nsar,dr] = getobg_insar2d(weight,obfile,sumob,...
    locasub,locadep,fault,faultall,gridsize,trup_con,rakevar)
fault0 = fault;
fault=faultall(:,4:5);
fault(:,3)=fault0(3);
dr = [];
if weight
    load(obfile);
    locasar = insar(:,1:2);
    slipsar = insar(:,3);
    weit_sar = weight*sqrt(sumob)/sqrt(slipsar(:)'*slipsar(:));
    if rakevar==1
        Gsar = jt_sarG(insar,locasub,locadep,prod(grid),locasar,fault,gridsize,trup_con);
    elseif rakevar==0
        Gsar = jt_sarG2(insar,locasub,locadep,prod(grid),locasar,fault,gridsize,trup_con);
    end
    Gsar = Gsar/3e16/prod(gridsize);
else
    slipsar = [];
    Gsar = [];
    locasar = [];
    weit_sar = 0;
    nsar = [];
    dr = [];
end
end
