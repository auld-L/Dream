function [faultall,biaoall,faultbian]=convfault(locasub,locadep,grid,fault,ni)
dx=(locasub(1+grid(1),:)-locasub(1,:))/2;
dy=(locasub(2,:)-locasub(1,:))/2;
ddep=(locadep(2)-locadep(1))/2;
k=0;
for j=1:grid(2)
    for i=1:grid(1)
        k=k+1;
    faultall(k,1:2)=locasub(k,:);
    faultall(k,3)=locadep(k);
    faultall(k,4)=fault(1);
    faultall(k,5)=fault(2);
    biaoall(k,1)=ni;
    biaoall(k,2)=i;
    biaoall(k,3)=j;
    biaoall(k,4)=1;
    faultbian(k,1,1:3)=[locasub(k,:)-dx-dy,locadep(k)-ddep];
    faultbian(k,2,1:3)=[locasub(k,:)+dx-dy,locadep(k)-ddep];
    faultbian(k,3,1:3)=[locasub(k,:)-dx+dy,locadep(k)+ddep];
    faultbian(k,4,1:3)=[locasub(k,:)+dx+dy,locadep(k)+ddep];
    end
end