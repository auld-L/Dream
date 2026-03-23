function meangreen = get_Gmatrixmeangreen(ob,g,fault)

%fault = repmat(fault,[prod(grid),1]);
% lensub = lensub*srate;
% lenrup = lenrup*srate;
% 
% if isempty(ob)
%     loca = epi+[1,1];
% end
% [delt,locasub,locadep] = ruptime_nfnew(fault(1,:),grid([2,1]),...
%     gridsize([2,1]),[1,source([2,1])],loca,epi,'P');
% delt = zeros(size(delt));
% locadep=locadep+depth-locadep(source(1));
% [trup,trup_con0] = get_trup(grid,source,gridsize,lensub,lenrup,vrup,srate,set_edge0);
% dex_out = stf2sub(1:length(trup_con0),grid,lensub);clear trup_con
% trup_con(dex_out) = trup_con0; 
% trup_con = trup_con(:);

if isempty(ob)
    G = [];sGDT = [];hdata = [];meangreen = 1;
    sumob = 1;
else
%     [G,sGDT,hdata,meangreen] = jt_seisG_moregreen(fault,trup_con0(:),delt,...
%     lensub/srate,lam1,lam2,lam3,ob,g,1,srate,rakevar,grid);
%     sumob = hdata(:)'*hdata(:);
   % lensub=round(lensub*srate/inter);
%lenrup=round(lenrup./inter); % lenrup is unneccesary here because it has been
% used in the generation of trup_con0, and trup_con0 has been given for input parameters

meangreen=(max(abs(green2g(g,mean(fault)))));
%meangreen=(max(abs(green2g(green(:,:,:,1:42),mean(fault)))));
meangreen=mean(meangreen(:));
end
end
