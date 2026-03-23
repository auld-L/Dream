function [Dcen,Tcen]=ccentral(slip,locasub,locadep,stf,srate,miun,Sall)
slip=slip(:);
%slip(slip<max(slip)/4)=0;
latcen=sum(locasub(:,1).*slip.*miun.*Sall)/sum(slip.*miun.*Sall);%空间矩心lat
loncen=sum(locasub(:,2).*slip.*miun.*Sall)/sum(slip.*miun.*Sall);%空间矩心lon
depcen=sum(locadep.*slip.*miun)/sum(slip.*miun);%空间矩心depth
Dcen=[latcen,loncen,depcen];
t=1:1:length(stf);
t=t*srate;
Tcen=sum(t'.*stf)/sum(stf);
end