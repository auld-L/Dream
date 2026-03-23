function [pzname,ifclose] = pzforsaca(a,path)
%给定windows环境下的路径path和数据文件名，返回对应的PZ文件名
aa=strsplit(a,'.M.');
if strcmp(aa,a)
    aa=strsplit(a,'.Q.');
    if strcmp(aa,a)
        aa=strsplit(a,'.D.');
        if strcmp(aa,a)
            aa=strsplit(a,'.R.');
        end
    end
end
aa=aa{1};
aa=strrep(aa,'..','.--.');
pzfile=dir([path,'/*/','SACPZ.',aa]);
% pzfile=dir([path,'/IRISDMC/','SACPZ.',aa]);
if isempty(pzfile)
    ifclose=1;
    pzname='';
else
    ifclose=0;
    pzname=[pzfile(1).folder,'\',pzfile(1).name];
end
end

