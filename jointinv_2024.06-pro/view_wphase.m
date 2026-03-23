
% Depth of the epicenter in km
%depth = 18.8;
depth=14.34;
% Length of the wave before initial P in s
leng_before = 50;

% Length of the wave after initial P in s
leng_after = 1480;

% Sample rate in s^-1
srate = 0.5;
tyan=100*srate;
%Lpoly=round(450*srate);%xianxingdianshu
% Location of the epicenter, epi = [latitude,longitude]
%epi= [37.174,37.032];
%epi = [31.018,103.365];
epi = [31.0636,103.3718];
% Range of epicentral distance (in degree) within which the stations could
% be selected, as teleseismic distances 
range_distance = [10,90];

% Minimum take-off angle interval (in degree) between each stations could be 
% selected
azim_inter = 10;

% Minimum epicentral distance interval (in degree) between each stations
% could be selected
dist_inter = 10;

% Minimum signal-to-noise-ratio (in %) under which the wave would not be 
% selected
snr_level = 5;
iffilter=1;
% Path of teleseismic records downloaded from IRIS 
datafolder = 'D:\matlab2021\codes\jtinew2022.09\2008-05-12-mw79-sichuan-chinaLH2';
%deldex=[6,8,16,17,24,25];
%deldex=[8,16,17,18,24,25,28,30,31,32,39,45,46,50];
%deldex=[8,15,17,24,25,27,28,31,34,37,45];
%deldex=[5,11,21,31,35,39,40,41,43,44];
deldex=[6,9,13,17,18,21,35,36,37,44];
%deldex=[];
band=[0.0017,0.01];
taper=1:1:round(leng_before*srate);
taper=1./(round(leng_before*srate)-taper+1);
leng = leng_before + leng_after;
%[accs,mm,loca,chnl,finalpath,reftime,da,btlist,otlist,cmpaz,badfittingpath]=WPI_getdata(datafolder,'Z',1,srate,range_distance,epi);
[accs,mm,loca,chnl,finalpath,reftime,da,btlist,otlist,cmpaz,badfittingpath]=WPI_getdata(datafolder,'Z',0,srate,range_distance,epi);
Ltmp=length(cell2mat(accs(1)));
obs=zeros(Ltmp,size(loca,1));
for i=1:size(loca,1)
    obtmp=cell2mat(accs(i));
    if length(obtmp)<Ltmp
        continue
    elseif length(obtmp)>Ltmp
        obtmp(Ltmp+1:end)=[];
    end
    if otlist(i)<0
        obtmp=[zeros(abs(round(otlist(i)*srate)),1);obtmp];
%         obtmp(1:leng_before*srate)=obtmp(1:leng_before*srate).*taper.^2;
%         obtmp=cumsum(obtmp);
        obs(:,i)=obtmp(1:Ltmp);
    else
        obtmp=obtmp(round(otlist(i)*srate)+1:length(obtmp));
%         obtmp(1:leng_before*srate)=obtmp(1:leng_before*srate).*taper.^2;
%         obtmp=cumsum(obtmp);
        obs(1:length(obtmp),i)=obtmp;
    end
end

if max(depth(:))<100
	t = round(get_time(da(:,1)/111.19492664455875,depth,'P')*srate);
else
	t = round(dbgrn_get_time(da(:,1)/111.19492664455875,depth,'P')*srate);
end
nsta = length(t);
Ltmp=Ltmp/srate;
ob0 = zeros(Ltmp*srate,nsta);
for i = 1:nsta
	obs0 = obs(max(round(t(i)-leng_before*srate),1):t(i)+round(15*da(i,1)/111.19492664455875*srate+tyan),i);
    %obs0(1:round(leng_before*srate))=obs0(1:round(leng_before*srate)).*taper'.^2;
    obs0=cumsum(obs0)/srate;
    Lpoly=round(leng_before*srate)+round(15*da(i,1)/111.19492664455875*srate)+tyan;
    x=1:1:Lpoly;
    y=obs0(1:Lpoly);
    p=polyfit(x(:),y(:),2);
    q=polyval(p,x);
    obs0(1:Lpoly)=obs0(1:Lpoly)-q';
	obs0(Lpoly+1:end)=0;
    obs0(1:round(leng_before*srate))=obs0(1:round(leng_before*srate)).*taper'.^2;
    ob0(1:size(obs0,1),i) = obs0;
end
ob = ob0;
snr = mean(abs(ob0(round(leng_before*srate)+1:round((leng_before+50)*srate),:))).^2./mean(abs(ob0(1:round(leng_before*srate),:))).^2;
xx = snr<snr_level;
ob(:,xx) = [];loca(xx,:) = [];da(xx,:) = [];mm(xx,:) = [];snr(xx) = [];chnl(xx,:) = [];finalpath(xx) = [];
xx = isinf(snr);
ob(:,xx) = [];loca(xx,:) = [];da(xx,:) = [];mm(xx,:) = [];snr(xx) = [];chnl(xx,:) = [];finalpath(xx) = [];
xx = isnan(snr);
ob(:,xx) = [];loca(xx,:) = [];da(xx,:) = [];mm(xx,:) = [];snr(xx) = [];chnl(xx,:) = [];finalpath(xx) = [];
% ob(1:40*srate,:) = [];

% mob = max(abs(ob));
% xx = find(mob>mean(mob)*5);
% ob(:,xx) = [];loca(xx,:) = [];da(xx,:) = [];mm(xx,:) = [];chnl(xx,:) = [];finalpath(xx) = [];snr(xx) = [];

[dex] = da_del(da,[dist_inter,azim_inter],'P');
ob = ob(:,dex);loca = loca(dex,:);da = da(dex,:);mm = mm(dex,:);chnl = chnl(dex,:);
finalpath = finalpath(dex);snr = snr(dex);final_snr = snr;

ob(round(leng*srate)+1:end,:) = [];

ob(:,deldex) = [];loca(deldex,:) = [];da(deldex,:) = [];mm(deldex,:) = [];
snr(deldex) = [];chnl(deldex,:) = [];finalpath(deldex) = [];

obf = ob;
if iffilter
    [bb,aa] = butter(4,band*2/srate);
    obf = filter(bb,aa,ob);
end

nsta = size(ob,2);
disp([num2str(nsta),' stations have been reselected!']);

figure
h = epi_sta00(epi,loca,mm,100);

figure
xx = 0:1/srate:length(obf(:,1))/srate;
ss = size(obf);
astf = obf;
astf = [astf;zeros(1,ss(2))];
for i = 1:ss(2)
    astf(:,i) = astf(:,i)./max(abs(astf(:,i)))+i*2;
end
nplt = ceil(nsta/10);
mda = num2str(round([da(:,1)/6371/pi*180,da(:,2)]));
mda = [repmat('(',ss(2),1),mda(:,1:2),repmat('/',ss(2),1),mda(:,4:end),repmat(')',ss(2),1)];
zzchar = [mm,mda];
for i = 1:size(zzchar,1)
    zz0 = zzchar(i,:);
    zz0(zz0 == ' ') = [];
    yl{i} = zz0;
end
for i = 1:nplt
    subplot(1,nplt,i)
    plot(xx,astf(:,(i-1)*10+1:min([i*10,nsta])),'color',ones(1,3)*0.0,'linewidth',1)
    axis tight
    xlabel('Time(s)')
    grid on
    set(gca,'ytick',2:2:ss(2)*2);
    set(gca,'yticklabel',yl,'fontsize',8);
end

save ob_WphasewenchuanLHnews0.5.mat ob loca da mm srate leng leng_before
