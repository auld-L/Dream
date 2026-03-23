function [X_out,misfit,t0,t_isrevise,Xall,misfite,it,ega]=pl_vt_spar2(G,sparG,ob,X0t0l,iter,evalchar)
%==========================================================================
% using projected Landweber method with variable relaxations t0 accelerate
% converging
% solving [G;sparG]*X=ob, where G is a dense matrix and sparG is a sparse matrix
% X0t0l: st0pping X0t0lerance of misfit, if X0t0l>=1, it would not be used
% iter: iteration number
% evalchar: projection of X in each iteration, such as positivity: 'X(X<0)=0;'
% X_out: solution with the minimum residual
% misfit: normalized misfit
% t0: relaxation fact0rs, it is determined by minimizing abs{กว[(1-eg*t(k))]}
% Note: if the residual increases in an iteration, then use the relaxation
% 2/(max(eg)+min(eg)) t0 replace it, where eg is a vect0r consisting of all eigenvalues of (G'*G)
%              Zhang Yong, Peking University, 2022-10-27
%==========================================================================

sg=size(G);
GG=G'*G+sparG'*sparG;egmax=eigs(GG,1,'largestabs');
% ensure egmax is no less than its ture value
egmax=egmax*(1+eps*100);

% prepare of relaxations for iterations
t0=load('t0_5e4.mat');%5e4
t0=t0.t0/egmax;
tmax=2/egmax;
t0def=tmax;% close to 2/(egmax+egmin)
repnum=ceil(iter/numel(t0));
t0=repmat(t0,[repnum,1]);

%tic;GG=G'*G+sparG'*sparG;eg=eig(GG);eg(eg<=0)=[];egmax=max(eg);t0c
Gob=G'*ob(1:sg(1))+sparG'*ob(1+sg(1):end);
GobE=Gob'*Gob;

% prepare for iterative calculations
sg=size(G);
Xall=zeros(sg(2),iter);% solutions in all iterations
if numel(X0t0l)>1
    X=X0t0l;
else
    X=zeros(sg(2),1); % initial solution
end
misfit=zeros(iter,1); % relative misfit
misfite=zeros(iter,1); % relative misfit
obE=ob'*ob; % energy of data
numstop=0;
it=zeros(iter,1);
% calculate the residual and gradient
ex=ob-[G*X;sparG*X];% sg(1)*sg(2)
Xe=G'*ex(1:sg(1))+sparG'*ex(sg(1)+1:end);% sg(1)*sg(2)
t_isrevise=zeros(iter,1);
for i=1:iter
    X0=X;    
    X=X+Xe*t0(i);    
    eval(evalchar);% Projection, e.g., positivity
    
    % calculate the residual and gradient
    ex=ob-[G*X;sparG*X];% sg(1)*sg(2)
    misfit(i)=ex'*ex/obE;
    % if t0(i) exceeds tmax, misfit(i) needs t0 be smaller than misfit(i-1)
    if t0(i)>tmax
        if i>1&&misfit(i)-misfit(i-1)>eps
            t0(i)=t0def;
            X=X0+Xe*t0(i);
            eval(evalchar);
            ex=ob-[G*X;sparG*X];% sg(1)*sg(2)
            misfit(i)=ex'*ex/obE;
            t_isrevise(i)=1;
        end
    end
%     % if t0(i) exceeds tmax, misfit(i) needs t0 be smaller than misfit(i-1)
%     if t0(i)>tmax
%         while i>1&&misfit(i)-misfit(i-1)>eps
%             t0(i)=[];
%             X=X0+Xe*t0(i);
%             if t0(i)>tmax;disp(num2str([t0(i) tmax]));end
%             eval(evalchar);
%             ex=ob-[G*X;sparG*X];% sg(1)*sg(2)
%             misfit(i)=ex'*ex/obE;
%             t_isrevise(i)=t_isrevise(i)+1;
%         end
%     end
    Xe=G'*ex(1:sg(1))+sparG'*ex(sg(1)+1:end);% sg(1)*sg(2)  
    
    misfite(i)=Xe'*Xe/GobE;%(X-X0)'*(X-X0);
     
    Xall(:,i)=X;
    
    % st0p the iteration if the deepest misfit reduction (t0>tmax) has been stably small
    if i>1&&numel(X0t0l)==1&&X0t0l<1
        if (misfit(i-1)-misfit(i)<X0t0l)&&(t0(i)>tmax)
            numstop=numstop+1;
        end
        if numstop>20
            misfit(i+1:end)=NaN;
            Xall(:,i+1:end)=[];
            t_isrevise(i+1:end)=[];
            break;
        end
    end
end

% % calculate all EG1 for revised relaxations
ega=[];

% get the solution with the minimum misfit
[~,n]=min(misfit);
X_out=Xall(:,n);