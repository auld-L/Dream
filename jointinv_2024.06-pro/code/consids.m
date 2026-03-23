function Sall=consids(faultbian,faultall,gridsize)
sz=size(faultbian);
for i=1:sz(1)
    A0(:,:)=faultbian(i,[1,2,4,3,1],1:2);
    Sall(i)=polyarea(A0(:,1),A0(:,2))*111.1949^2*cosd(faultall(i,1))/cosd(faultall(i,5))/(gridsize(1)*gridsize(2));
end

end