function [edge,dd]=cedge(rdot,gridsize,strike,dip)
edge=zeros(4,3);
edge(1:2,3)=edge(1:2,3)+rdot(3)-gridsize(2)/2*sind(dip);
edge(3:4,3)=edge(3:4,3)+rdot(3)+gridsize(2)/2*sind(dip);
dy1=gridsize(1)/2*sind(strike);
dx1=gridsize(1)/2*cosd(strike);
dy2=gridsize(2)/2*cosd(dip)*sind(strike-90);
dx2=gridsize(2)/2*cosd(dip)*cosd(strike-90);
dd=[dx1,dy1,dx2,dy2];
edge(1,1)=rdot(1)-dx1+dx2;
edge(1,2)=rdot(2)-dy1+dy2;
edge(2,1)=rdot(1)+dx1+dx2;
edge(2,2)=rdot(2)+dy1+dy2;
edge(3,1)=rdot(1)-dx1-dx2;
edge(3,2)=rdot(2)-dy1-dy2;
edge(4,1)=rdot(1)+dx1-dx2;
edge(4,2)=rdot(2)+dy1-dy2;
end