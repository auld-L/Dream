function [ux,R2] = WPI_detrend(u,n,o)
%对向量u前n个点做一个o阶多项式拟合，并从u中减去这个趋势
%对于o≥1的情况，R2是拟合优度，越接近1拟合越好；
%对于o=0的基线拟合，R2是残差范数的平方
ux=zeros(size(u));
R2=zeros(size(u,2));
for r=1:size(u,2)
    uu=u(1:n,r);
    [p,S]=polyfit((1:n)',uu,o);
    no=S.normr;
    if o==0
        R2(r)=no^2;
    else
        R2(r)=1-no^2/norm(uu-mean(uu))^2;
    end
    ux(:,r)=u(:,r)-polyval(p,(1:length(u(:,r)))');
end
end

