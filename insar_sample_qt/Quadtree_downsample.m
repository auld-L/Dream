format long g
insar=load("insar.mat");
min=32;
max=256;
thresh=0.015;
down=qdt(insar,min,max,thresh);

dlmwrite('input.txt',down,'delimiter','\t');
function down_insar = qdt(insar, mindim, maxdim, thresh)
% Quadtree decomposition of insar_data
% insar : struct array that contain Lon Lat los(m) Inc 
% mindim : minimum size of the quadtree cell (32)
% maxdim : maximum size of the quadtree cell (256)
% thresh : variance threshold (0.04)
% modified after Diego Melgar, MudPy quadtree 
% h = waitbar(0,'Quadtree downsample');

debug_flag=1;
plot_lims=[-0.4,0.4];

%Load InSAR
lon=double(insar.Lon);
lat=double(insar.Lat);
los=double(insar.Phase);
inc=mean(insar.Inc);
fprintf('mean inc = %g \n',inc);

lon_i=linspace(min(lon),max(lon),2048);
lat_i=linspace(min(lat),max(lat),2048);

% Get the InSAR boundary polygon
fprintf('Getting the border of INSAR data\n')
border=boundary(lon,lat);
fprintf('Interpolating to grid\n')
[X,Y]=meshgrid(lon_i,lat_i);

los_interp_sharp = griddata(lon,lat,los,X,Y);
los_interp=los_interp_sharp;

display('QT decomp')
s=qtdecomp(los_interp,thresh,[mindim,maxdim]);
%Calculate maximum dimension
maxdim=max(max(full(s)));
%get power of 2 of possible block values
idim=(log(mindim)/log(2)):1:(log(maxdim)/log(2));
%Now loop through
los_out=[];
lon_out=[];
lat_out=[];

for k=1:length(idim)
    [vals, r, c] = qtgetblk(los_interp_sharp, s,2^idim(k));
    icurrent=find(s==2^idim(k));
    %Now get mean and cell center of each grid
    for kgrid=1:length(icurrent)
       %Get values
       new_los=mean(mean(vals(:,:,kgrid)));
       if ~isnan(new_los)  %Add to the list
           los_out=[los_out,mean(mean(vals(:,:,kgrid)))];
           %get indices of center as upepr left plus half the size of the
           %block
           r1=r(kgrid)+(2^idim(k))/2;
           r2=r(kgrid)+(2^idim(k))/2+1;
           c1=c(kgrid)+(2^idim(k))/2;
           c2=c(kgrid)+(2^idim(k))/2+1;
           %Now figure out coordiantes of the center
           lon_out=[lon_out,0.5*(X(r1,c1)+X(r2,c2))];
           lat_out=[lat_out,0.5*(Y(r1,c1)+Y(r2,c2))];
       end
    end
end

%find points withn the InSAR boundaries
index = inpolygon(lon_out,lat_out,lon(border),lat(border));
lon_out = lon_out(index);
lat_out = lat_out(index);
los_out = los_out(index);

if debug_flag==1
%Plot
qd_fig=figure;
subplot(1,2,1)
mesh(X,Y,los_interp_sharp)
caxis(plot_lims)
colorbar 
view([0,90])
hold on
axis tight
axis equal
title('LOS (m)','FontSize',16)

subplot(1,2,2)
scatter(lon_out,lat_out,40,los_out,'filled','s')
colorbar
axis tight
axis equal
view([0,90])
 caxis(plot_lims)
colormap('jet')
title('QuadTree Resampled LOS (m)','FontSize',16)
end
fprintf('Quadtree finished\n')
fprintf('Decrease the point sample size from %g to %g\n',length(lon),length(lon_out))
res_scope=0.001* ones(1,length(lon_out));
down_insar = [lat_out' lon_out' los_out' res_scope'];

end

