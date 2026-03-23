function [ob,g,mob] = normalize_obgw(ob,g,obt,obsm,obw,weight_tele,weight_sm,weight_wphase)
load('difsrate.mat');
if weight_tele
mobt = sqrt(sum(obt.*obt)/difsrate(1));
else
    mobt = [];
end
if weight_sm
mobsm = sqrt(sum(obsm.*obsm)/difsrate(size(obt,2)+1));
else
    mobsm = [];
end
if weight_wphase
mobw = sqrt(sum(obw.*obw)/difsrate(size(obt,2)+size(obsm,2)+1));
else
    mobw = [];
end
mob = [mobt/weight_tele,mobsm/weight_sm,mobw/weight_wphase];
for i = 1:size(ob,2)
    ob(:,i) = ob(:,i)/mob(i);
    g(:,:,:,i) = g(:,:,:,i)/mob(i);
end
end