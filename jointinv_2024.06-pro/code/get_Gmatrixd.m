function [G,sGDT,hdata,meangreen,sumob,trup_con,locasub,locadep,trup] = get_Gmatrixd(ob,g,...
    loca,epi,biaoall,fault,faultall,gridsize,source,lensub,lenrup,vrup,srate,lam1,lam2,lam3,rakevar,joinpoint,difsrate)

fault0 = fault;
fault=faultall(:,4:5);
fault(:,3)=fault0(3);
lensub = lensub*srate;
lenrup = lenrup*srate;

if isempty(ob)
    loca = epi+[1,1];
end
% [delt,locasub,locadep] = ruptime_nfnew(fault(1,:),grid([2,1]),...
%      gridsize([2,1]),[1,source([2,1])],loca,epi,'P');

% locadep=locadep+depth-locadep(source(1));
locasub=faultall(:,1:2);
locadep=faultall(:,3);
delt = zeros(size(locasub,1),size(loca,1));
[trup,trup_con0] = get_trupd(faultall,source,gridsize,lensub,lenrup,vrup,srate,biaoall,joinpoint);
dex_out = stf2sub(1:length(trup_con0),[size(faultall,1),1],lensub);clear trup_con
trup_con(dex_out) = trup_con0; 
trup_con = trup_con(:);

if isempty(ob)
    G = [];sGDT = [];hdata = [];meangreen = 1;
    sumob = 1;
else
    [G,sGDT,hdata,meangreen] = jt_seisG_moregreend(fault,trup_con0(:),delt,...
    lensub/srate,lam1,lam2,lam3,ob,g,1,srate,rakevar,faultall,biaoall,difsrate);
    sumob = hdata(:)'*hdata(:);
end
end
