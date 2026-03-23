function Sall=considsplus(faultbian,faultall,gridsize)
sz=size(faultbian);
for i=1:sz(1)
    A0(:,:)=faultbian(i,[1,2,3,4],1:3);
    A0(:,1)=A0(:,1)*111.1949;
    A0(:,2)=A0(:,2)*111.1949*cosd(faultall(i,1));
    %Sall(i)=polyarea(A0(:,1),A0(:,2))*111.1949^2*cosd(faultall(i,1))/cosd(faultall(i,5))/(gridsize(1)*gridsize(2));
    a=sqrt((A0(1,1)-A0(2,1))^2+(A0(1,2)-A0(2,2))^2+(A0(1,3)-A0(2,3))^2);
    b=sqrt((A0(1,1)-A0(3,1))^2+(A0(1,2)-A0(3,2))^2+(A0(1,3)-A0(3,3))^2);
    c=sqrt((A0(3,1)-A0(2,1))^2+(A0(3,2)-A0(2,2))^2+(A0(3,3)-A0(2,3))^2);
    p=0.5*(a+b+c);
    S1=sqrt(p*(p-a)*(p-b)*(p-c));
    a=sqrt((A0(4,1)-A0(2,1))^2+(A0(4,2)-A0(2,2))^2+(A0(4,3)-A0(2,3))^2);
    b=sqrt((A0(4,1)-A0(3,1))^2+(A0(4,2)-A0(3,2))^2+(A0(4,3)-A0(3,3))^2);
    c=sqrt((A0(3,1)-A0(2,1))^2+(A0(3,2)-A0(2,2))^2+(A0(3,3)-A0(2,3))^2);
    p=0.5*(a+b+c);
    S2=sqrt(p*(p-a)*(p-b)*(p-c));
    Sall(i)=(S1+S2)/(gridsize(1)*gridsize(2));
end

end