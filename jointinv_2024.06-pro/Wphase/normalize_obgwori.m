function [ob,g,mob] = normalize_obgwori(ob,g,obt,obsm,obw,weight_tele,weight_sm,weight_wphase)
mobt = sqrt(sum(obt.*obt));
if mobt == 0
    mobt = [];
end
mobsm = sqrt(sum(obsm.*obsm));
if mobsm == 0
    mobsm = [];
end
mobw = sqrt(sum(obw.*obw));
if mobw == 0
    mobw = [];
end
mob = [mobt/weight_tele,mobsm/weight_sm,mobw/weight_wphase];
for i = 1:size(ob,2)
    ob(:,i) = ob(:,i)/mob(i);
    g(:,:,:,i) = g(:,:,:,i)/mob(i);
end
end