function [accs,mm,loca,chnl,finalpath,reftime,da,btlist,otlist,cmpaz,badfittingpath]=WPI_getdata(path,com,way,srate,d_range,epi)
%  get acc.s from SAC_ASC data files in 'datapath'
% Input:
%        path:   data folder
%        com:    such as 'Z' for vertical component, and 'A' for all components
%        way:    1 only get the data with the sampling rate of srate
%                0 get data with sampling rate more than srate   
%        srate:  sampling rate
% Output:
%        accs:   observed accelerations
%        mm:     station codes
%        loca:   location of stations
%        chnl:   channel of stations
%        finalpath: paths of the records preserved
%        reftime:   reference time of each record
%        da:     distance and azimuth
%        btlist: beginning time of each record relative to the reftime
%        otlist: origin time of the event relative to the reftime
%        cmpaz:  component azimuth (e.g. 0 for NS component,90 for EW )
%        badfittingpath: paths of records with bad results when removing instrument responses 

if isunix
    file=dir([path,'/*.SAC_ASC']);
else
    file1=dir([path,'\*.SAC_ASC']);
    file2=dir([path,'\*.SACA']);
    if length(file1)>length(file2)
        file=file1;
    else
        file=file2;
    end
end

nsta=length(file);
loca_ini=zeros(nsta,2);
num=0;
%---------------------------------------------------------------------
for n=1:nsta
    a=file(n).name;
    [apzfile,ifclose]=pzforsaca(a,path);
    if ifclose
        continue
    end
    afile=[path,'/',a];
    filen=fopen(afile,'r');
    
    headn=zeros(110,1);
    for j=1:22
        heada=str2num(fgets(filen));
        headn((j-1)*5+1:j*5)=heada;
    end    
    
        % way==1, only process the data with a sampling rate equals srate:
    rate=round(1/headn(1));
    if rate<srate
        fclose(filen);
        continue
    end
    
%     if headn(4)==-12345
    if headn(4)<=0
        fclose(filen);
        continue
    end
    
    axx=repmat(' ',1e3,8);
    for i=1:8
        zaxx=fgets(filen);
        axx(1:length(zaxx),i)=zaxx;
    end

     if strcmp(axx(17,7),'S')
        fclose(filen);
        continue
    end
     
    if axx(19,7)=='1'
        if headn(59)~=90
            fclose(filen);
            continue
        end
    end
    if axx(19,7)=='2'
        if headn(59)~=90
            fclose(filen);
            continue
        end
    end
    
%     if ~strcmp(axx(1,2),'0')%use only 00 channel
%         fclose(filen);
%         continue
%     end
    
    if strcmpi(com,'A')
    elseif ~strcmpi(com,axx(19,7))
        fclose(filen);
        continue
    end

    num=num+1;
    loca_ini(num,:)=[headn(32),headn(33)];
    usepath{num}=afile;
    usepathpz{num}=apzfile;
    
    fclose(filen);
end

if num==0
    error('Data sets wrong, can not read any data!!');
    return
end


loca_ini(num+1:end,:)=[];


da=distazim_zh(loca_ini,epi);
d_deg=da(:,1)./111.19492664455875;


x1=find(d_deg<d_range(1));d_deg(x1)=[];loca_ini(x1,:)=[];usepath(x1')=[];usepathpz(x1')=[];
x2=find(d_deg>d_range(2));d_deg(x2)=[];loca_ini(x2,:)=[];usepath(x2')=[];usepathpz(x2')=[];


%------------------------------------------------------------------------


nsta=length(usepath);
leng=srate*5e3;


accs=cell(nsta,1);
mm=repmat(' ',nsta,5);
chnl=repmat(' ',nsta,6);
loca=zeros(nsta,2);
reftime=zeros(nsta,6);
btlist=zeros(nsta,1);
otlist=zeros(nsta,1);
cmpaz=zeros(nsta,1);

num=0;
n_badfitting=0;
badfittingpath={};
for n=1:nsta
    filen=fopen(usepath{n},'r');
    headn=zeros(110,1);
    for j=1:22
        heada=str2num(fgets(filen));
        headn((j-1)*5+1:j*5)=heada;
    end

    % way==1, only process the data with a sampling rate equals srate:
    rate=round(1/headn(1));
    if way==1
        if rate~=srate
            fclose(filen);
            continue
        end
        % otherwise, the sampling rate should be more than required
    elseif rate<srate
        fclose(filen);
        continue
    end

    axx=repmat(' ',1e3,8);
    for i=1:8
        zaxx=fgets(filen);
        axx(1:length(zaxx),i)=zaxx;
    end

    ob=fscanf(filen,'%f');
    fclose(filen);
    ob=ob(:);
    if length(ob)<1800*rate % the records should start at 1800s before P
        continue
    end
    [~,r2]=WPI_detrend(ob,ceil(1200*rate),1);
    if r2>0.1
        continue % remove records with a linear trend
    end

    [c0,ps,zs]=transget(usepathpz{n});
    [acc,~,~,~,badfitting]=transfertd(WPI_detrend(ob,ceil(1200*rate),0),c0,ps,zs,rate); %deconvolve to acc.
    if way~=1 && rate>srate
        acc=resample(acc,1000*srate,1000*rate);
    end
    if badfitting
        n_badfitting=n_badfitting+1;
        badfittingpath{n_badfitting}=usepath{n};
        continue
    end
    if max(abs(ob(1:min(leng,end))))==0
        continue
    end
    
    num=num+1;
    accs{num}=acc;
    % locations of stations
    loca(num,:)=[headn(32),headn(33)];
    mm(num,:)=axx(1:5,1)';
    chnl(num,:)=[axx(17:19,7)','_',axx(1:2,2)'];
  
    finalpath{num}=usepath{n};
    btlist(num)=headn(6);
    otlist(num)=headn(8);
    reftime(num,:)=headn(71:76);
    cmpaz(num)=headn(58);
end

if num<nsta
    accs(num+1:end)=[];
    mm(num+1:end,:)=[];
    loca(num+1:end,:)=[];
    chnl(num+1:end,:)=[];
    btlist(num+1:end)=[];
    otlist(num+1:end)=[];
    reftime(num+1:end,:)=[];
end
reftime(:,5)=reftime(:,5)+reftime(:,6)./1e3;
da=distazim_zh(loca,epi);
disp([num2str(num) ' stations were selected successfully!!']);
return