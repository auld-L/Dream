function [const,ps,zs,sensitivity] = transget(apzfile)
%给定仪器响应文件，读取常数c0和零极点信息
pzfile=fopen(apzfile,'r');
row=0;
const=1.0;
while ~feof(pzfile)
    temp=fgetl(pzfile);
    row=row+1;
    if contains(temp,'ZEROS')
        temp2=temp(max(strfind(temp,'S'))+1:end);
        temp2=textscan(temp2,'%f');
        numz=temp2{1};
        zs=zeros(numz,1);
        for i=1:numz
            temp2=fgetl(pzfile);
            temp2=textscan(temp2,'%f');
            temp2=temp2{1};
            zs(i)=temp2(1)+1i*temp2(2);
        end
    end
    if contains(temp,'POLES')
        temp2=temp(max(strfind(temp,'S'))+1:end);
        temp2=textscan(temp2,'%f');
        nump=temp2{1};
        ps=zeros(nump,1);
        for i=1:nump
            temp2=fgetl(pzfile);
            temp2=textscan(temp2,'%f');
            temp2=temp2{1};
            ps(i)=temp2(1)+1i*temp2(2);
        end
    end       
    if contains(temp,'CONSTANT')
        temp2=temp(max(strfind(temp,'T'))+1:end);
        temp2=textscan(temp2,'%f');
        const=temp2{1};
    end
    if contains(temp,'SENSITIVITY')
        temp2=temp(max(strfind(temp,':'))+1:strfind(temp,'(')-1);
        temp2=textscan(temp2,'%f');
        sensitivity=temp2{1};
    end
end
fclose(pzfile);
end

