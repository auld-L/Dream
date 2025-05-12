clc;clear;
load("invert_1_2_F.mat");
% plotInSARDataModelResidual(insar, geo, invpar, invResults, modelInput, saveName, fidHTML, 'y')

% Create colormaps for plotting InSAR data (call third party colormap_cpt.m function and GMT *.cpt files)
cmap.seismo = colormap_cpt('GMT_seis.cpt', 100);    % GMT 'Seismo' colormap for wrapped data
cmap.redToBlue = colormap_cpt('polar.cpt', 100);    % Red to Blue colormap for unwrapped data
% 

    % Calculate MODEL
    constOffset = 0;
    xRamp = 0;
    yRamp = 0;
    
%     if i == 1
%         if insar{i}.constOffset == 'y'
%             constOffset = invResults.model.mIx(end);
%             invResults.model.mIx(end) = invResults.model.mIx(end)+1;
%         end
%         if insar{i}.rampFlag == 'y'
%             xRamp = invResults.model.mIx(end);
%             yRamp = invResults.model.mIx(end)+1;
%             invResults.model.mIx(end) = invResults.model.mIx(end)+2;
%         end
%     end
%     
%    if i > 1
%         if insar{i}.constOffset == 'y'
%             constOffset = invResults.model.mIx(end);
% 
%             invResults.model.mIx(end) = invResults.model.mIx(end)+1;
%         end
%         if insar{i}.rampFlag == 'y'
%             xRamp = invResults.model.mIx(end);
%             yRamp = invResults.model.mIx(end)+1;
%             invResults.model.mIx(end) = invResults.model.mIx(end)+2;
%         end
%     end

for i = 1:length(insar)
    loadedData = load(insar{i}.dataPath);     
    convertedPhase = (loadedData.Phase/(4*pi))*insar{i}.wavelength;    % Convert phase from radians to m
    los = -convertedPhase;  % Convert phase from cm to Line-of-sigth displacement in m
    Heading = loadedData.Heading;
    Inc = loadedData.Inc;
    ll = [single(loadedData.Lon) single(loadedData.Lat)];   % Create Longitude and Latitude matrix
    xy = llh2local(ll', geo.referencePoint);    % Transform from geographic to local coordinates
    nPointsThis = size(ll,1);   % Calculate length of current data vector
    xy = double([[1:nPointsThis]',xy'*1000]);   % Add ID number column to xy matrix with local coordinates
    wavelength = 0.056;

    color_max = 0.4;
    color_min = -0.4;
    if i == 1

        if i == 1
            if insar{i}.constOffset == 'y'
                constOffset = invResults.model.mIx(end);
                invResults.model.mIx(end) = invResults.model.mIx(end)+1;
            end
            if insar{i}.rampFlag == 'y'
                 xRamp = invResults.model.mIx(end);
                yRamp = invResults.model.mIx(end)+1;
                invResults.model.mIx(end) = invResults.model.mIx(end)+2;
            end
        end

        [path, name, ext] = fileparts(insar{i}.dataPath);
        modLos = forwardInsarModel(insar{i},xy,invpar,invResults,modelInput,geo,Heading,Inc,constOffset,xRamp,yRamp); 
        figure;
        lon = ll(:,1);
        lat =ll(:,2);
        %画第一个图   wrap图
        subplot(2, 3, 1);
        colormap(cmap.redToBlue);
%         scatter(xy(:,2), xy(:,3), 30, los, 'filled');
        scatter(lon, lat, 30, los, 'filled');
        axis equal; axis tight;
        colorbar;title(['Subplot 1: observe ',name]);caxis([color_min, color_max]); 

        %画第二个图  model
        subplot(2, 3, 2);
        colormap(cmap.redToBlue);
        % disp(class(los));    
        %disp(size(los));  
        % disp(any(isnan(los)));  % 检查NaN值
        scatter(lon, lat, 30, modLos', 'filled');
        axis equal; axis tight;
        colorbar;title(['Subplot 2:  model ',name]);caxis([color_min, color_max]); 
       
        
        %画第三张图    residual图
        residual = los-modLos';
        subplot(2, 3, 3);
        colormap(cmap.redToBlue);
        % disp(class(los));    
        %  disp(size(los));  
        % disp(any(isnan(los)));  % 检查NaN值
        scatter(lon, lat, 30, residual, 'filled');
        axis equal; axis tight;
        colorbar;title(['Subplot 3: residual ',name]);caxis([color_min, color_max]); 

    else

       if i > 1
            if insar{i}.constOffset == 'y'
                constOffset = invResults.model.mIx(end);
                invResults.model.mIx(end) = invResults.model.mIx(end)+1;
            end
            if insar{i}.rampFlag == 'y'
                xRamp = invResults.model.mIx(end);
                yRamp = invResults.model.mIx(end)+1;
                invResults.model.mIx(end) = invResults.model.mIx(end)+2;
            end
        end

        [path, name, ext] = fileparts(insar{i}.dataPath);
        modLos = forwardInsarModel(insar{i},xy,invpar,invResults,modelInput,geo,Heading,Inc,constOffset,xRamp,yRamp); 
        lon = ll(:,1);
        lat =ll(:,2);
        %第三张图   observe
        subplot(2, 3, 4);
        colormap(cmap.seismo);
        scatter(lon, lat, 30, los, 'filled');
        axis equal; axis tight;
        colorbar;title(['Subplot 4: observe ',name]);caxis([color_min, color_max]); 

        %画第二个图  model
        subplot(2, 3, 5);
        colormap(cmap.redToBlue);
        % disp(class(los));    
        %disp(size(los));  
        % disp(any(isnan(los)));  % 检查NaN值
        scatter(lon, lat, 30, modLos', 'filled');
        axis equal; axis tight;
        colorbar;title(['Subplot 5: model ',name]);caxis([color_min, color_max]); 
        
        %画第三张图    residual图
        residual = los-modLos';
        subplot(2, 3, 6);
        colormap(cmap.redToBlue);
        % disp(class(los));    
        %  disp(size(los));  
        % disp(any(isnan(los)));  % 检查NaN值
        scatter(lon, lat, 30, residual, 'filled');
        axis equal; axis tight;
        colorbar;title(['Subplot 6: residual ',name]);caxis([color_min, color_max]); 




    end

end
% exportgraphics(gcf, 'ob_mo_rs.png', 'Resolution', 300); 






% plotInSARDataModelResidual(insar, geo, invpar, invResults, modelInput, saveName, 'y')
