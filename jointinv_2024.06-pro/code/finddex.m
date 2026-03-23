function dex=finddex(trup_con,grid,lensub)
x=zeros(grid(1)*grid(2),lensub);
y=zeros(size(x));
k=1;
for i=1:grid(1)
    for j=1:grid(2)
        x(k,:)=i;
        y(k,:)=j;
        k=k+1;
    end
end
x=x(:);
y=y(:);
dexx=find(trup_con==0);
x(dexx(end:-1:1))=[];
y(dexx(end:-1:1))=[];
dex=[x,y];
end