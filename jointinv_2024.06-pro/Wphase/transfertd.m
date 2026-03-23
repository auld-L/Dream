function [acce,G,w0,h,badfitting] = transfertd(ob,const,ps,zs,fs)
%给定波形ob [L*Nrecords]，SACPZ文件（位移响应）常数const，极点ps，零点zs和采样率fs，用时域递归滤波去除仪器响应得到加速度
N=10;%计算10个频点用于拟合响应振幅谱
f=zeros(N,1);
Fmax=1e-2;%拟合段的最高频
Fmin=1e-5;%拟合段的最低频
for i=1:N
    f(i)=(log10(Fmax)-log10(Fmin))/(N-1)*(i-1)+log10(Fmin);
    f(i)=10^f(i);
end
A=zeros(N,3);
Ha=zeros(N,1);
[L,nr]=size(ob);
acce=zeros(L+2,nr);
dt=1./fs;
for i=1:N
    s=sqrt(-1).*2.*pi.*f(i);
    Ha(i)=const./s.^2;
    for j=1:length(zs)
        Ha(i)=Ha(i).*(s-zs(j));
    end
    for j=1:length(ps)
        Ha(i)=Ha(i)./(s-ps(j));
    end
    A(i,:)=[abs(Ha(i)).^2,(abs(Ha(i)).*f(i)).^2,(abs(Ha(i))./f(i)).^2];
end
cs=lsqminnorm(A,ones(N,1));
if norm(ones(N,1)-A*cs)/norm(ones(N,1))>0.1
    badfitting=1;
else
    badfitting=0;
end
G=2*pi./sqrt(cs(2));
w0=2*pi.*(cs(3)./cs(2)).^(1/4);
h=sqrt((cs(1)./sqrt(cs(2).*cs(3))+2)/4);
c0=1/G/dt;
c1=-2*(1+h*w0*dt)/G/dt;
c2=(1+2*h*w0*dt+dt^2*w0^2)/G/dt;

ob=[zeros(2,nr);ob]; % 在信号前加2个零以提高稳定性
for i=3:L+2
    acce(i,:)=acce(i-1,:)+c2.*ob(i,:)+c1.*ob(i-1,:)+c0.*ob(i-2,:);
end
acce=acce(3:end,:);
if ~isreal(acce)
    badfitting=1;
end
end

