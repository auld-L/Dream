
function [Xsolve,ob,syn,astftele,synastf] = shift_obw2(tstele,tssm,tsw,Xsolve,ob,syn,obt,obsm,obw,hdata_use,...
    meangreen,G_jt,sGDT,srate,ifastf,Lenori)
   
    for k = 1:1
        if tstele
            syntele = syn(1:Lenori,1:size(obt,2));
            %syntele = reshape(syntele,size(obt));
            
            [obstele,dttele,~] = rup_obssyn(reshape(hdata_use(1:numel(syntele)),...
                size(syntele)),syntele,srate,5);
            save dttele.mat dttele
            ob(1:Lenori,1:size(obt,2)) = obstele*meangreen;
            hdata_use(1:numel(syntele)) = obstele(:);
            if ifastf==1
            load('astfneed.mat');
            obt=reshape(obstele,size(gtele,1),size(gtele,4));
            
            [astftele,synastf]=getastftele(obt*meangreen,gtele,source,grida,fault,lensub,band_tele,s1);
            astftele=astftele/srate;
            astftele=astftele(:)/mobstf;
          
            hdata_use(end-size(sGDT,1)+1:end-size(sGDT,1)+size(astftele,1))=astftele;
            else 
                synastf=[];
                astftele=[];
            end
            %mean(dttele)
        else
            synastf=[];
            astftele=[];
        end
        if tssm
            if isempty(obt)
                syntele=[];
            else
                syntele = syn(1:Lenori,1:size(obt,2));
            end
            synsm = syn(1:Lenori,size(obt,2)+1:size(obt,2)+size(obsm,2));
            %synsm = reshape(synsm,size(obsm,1),[]);
            [obssm,dtsm,~] = rup_obssyn_sm(reshape(hdata_use(numel(syntele)+1:...
                numel(syntele)+numel(synsm)),size(synsm)),synsm,srate);
            save dtsm.mat dtsm
            ob(1:Lenori,size(obt,2)+1:size(obt,2)+size(obsm,2)) = obssm*meangreen;
            hdata_use(numel(syntele)+1:numel(syntele)+numel(synsm)) = obssm(:);
            %mean(dtsm)
        end
        if tsw
            load dexw.mat
            if isempty(obt)
                syntele=[];
            else
                syntele = syn(1:Lenori,1:size(obt,2));
            end
            if isempty(obsm)
                synsm=[];
            else
                synsm = syn(1:Lenori,size(obt,2)+1:size(obt,2)+size(obsm,2));
            end
            synw0 = syn(:,size(obt,2)+size(obsm,2)+1:end);
            obw0=hdata_use(numel(syntele)+numel(synsm)+1:size(G_jt,1));
            obwc=zeros(size(obw));
            synw=reshape(synw0,size(obw));
            %synw=zeros(size(obw));
            k=0;
            for i =1:size(obw,2)
                %synw(1:dexw(i),i)=synw0(k+1:k+dexw(i));
                obwc(1:dexw(i),i)=obw0(k+1:k+dexw(i));
                synw(dexw(i)+1:end,i)=0;%add
                k=k+dexw(i);
            end
            [obsw,dtw,~] = rup_obssyn(obwc,synw,srate,10);
            save dtw.mat dtw
            ob(:,size(obt,2)+size(obsm,2)+1:end) = obsw*meangreen;
             k=0;
            for i =1:size(obw,2)
                hdata_use(numel(syntele)+numel(synsm)+k+1:numel(syntele)+numel(synsm)+k+dexw(i))=obsw(1:dexw(i),i);
                k=k+dexw(i);
            end
        end
        %save('dts.mat','dttele','dtsm');
        if tstele || tssm || tsw
            tic
            %[Xsolve,~] = cgls_xu_invt0(G_jt,sGDT,hdata_use,1e-170,1000);
            [Xsolve,rsq,~,~,~,~,~,~]=pl_vt_spar2(G_jt,sGDT,hdata_use(:),1e-15,500,'X(X<0)=0;');
            toc
            %syn = reshape(G_jt(1:numel(ob),:)*(Xsolve*meangreen),size(ob));
        else
            synastf=[];
            astftele=[];
        end
    end

end
