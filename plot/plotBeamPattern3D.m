function [] = plotBeamPattern3D(xPos, yPos, w)

displayStyle = '3D';
displayTheme = 'black';
maxDynamicRange = 50;

f = 3e3;
c = 340;

thetaSteeringAngle = 0;
phiSteeringAngle = 0;
thetaScanningAngles = -90:1:90;
phiScanningAngles = 0:1:180;
beamPattern = 0;
thetaScanningAnglesRadians = 0;
phiScanningAnglesRadians = 0;


%Plot the steered response
fig = figure;
ax = axes;
t = title(['Dynamic range: ' sprintf('%0.2f', maxDynamicRange) ...
    ' dB, \theta = ' sprintf('%0.0f', thetaSteeringAngle) ...
    ', \phi = ' sprintf('%0.0f', phiSteeringAngle) ...
    ', f = ' sprintf('%0.1f', f*1e-3) ' kHz'],'fontweight','normal');
ax.MinorGridLineStyle = '-';
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.ZMinorGrid = 'on';
ax.Box = 'on';
ax.XTickLabel = [];
ax.YTickLabel = [];
%ax.ZTickLabel = [];
ax.NextPlot = 'replacechildren';
axis(ax, 'equal')
hold(ax, 'on')
fColor = [1 1 1];
fAlpha = 0.25;



%Create context menu (for easy switching between orientation and theme)
cm = uicontextmenu;
topMenuOrientation = uimenu('Parent',cm,'Label','Orientation');
topMenuTheme = uimenu('Parent',cm,'Label','Theme');
uimenu('Parent',topMenuOrientation, 'Label', '2D', 'Callback',{ @setOrientation, '2D' });
uimenu('Parent',topMenuOrientation, 'Label', '3D', 'Callback',{ @setOrientation, '3D' });
uimenu('Parent',topMenuTheme, 'Label', 'Black', 'Callback',{ @setTheme, 'Black' });
uimenu('Parent',topMenuTheme, 'Label', 'White', 'Callback',{ @setTheme, 'White' });


[sx, sy, sz] = sphere(100);

%Plot the beampattern
calculateBeamPattern(fig, fig, 'init')


%Create sliders to change dynamic range, scanning angle and frequency
thetaAngleSlider = uicontrol('style', 'slider', ...
    'Units', 'normalized',...
    'position', [0.2 0.06 0.3 0.04],...
    'value', thetaSteeringAngle,...
    'min', -90,...
    'max', 90);
addlistener(thetaAngleSlider, 'ContinuousValueChange', @(obj,evt) calculateBeamPattern(obj, evt, 'thetaAngle') );
txtTheta = annotation('textbox', [0.16, 0.115, 0, 0], 'string', '\theta');

phiAngleSlider = uicontrol('style', 'slider', ...
    'Units', 'normalized',...
    'position', [0.2 0.01 0.3 0.04],...
    'value', phiSteeringAngle,...
    'min', -180,...
    'max', 180);
addlistener(phiAngleSlider, 'ContinuousValueChange', @(obj,evt) calculateBeamPattern(obj, evt, 'phiAngle') );
txtPhi = annotation('textbox', [0.16, 0.065, 0, 0], 'string', '\phi');

frequencySlider = uicontrol('style', 'slider', ...
    'Units', 'normalized',...
    'position', [0.55 0.06 0.3 0.04],...
    'value', f,...
    'min', 0.2e3,...
    'max', 10e3);
addlistener(frequencySlider, 'ContinuousValueChange', @(obj,evt) calculateBeamPattern(obj, evt, 'frequency') );
txtF = annotation('textbox', [0.52, 0.115, 0, 0], 'string', 'f');

dynamicRangeSlider = uicontrol('style', 'slider', ...
    'Units', 'normalized',...
    'position', [0.55 0.01 0.3 0.04],...
    'value', maxDynamicRange,...
    'min', 0.01,...
    'max', 80);
addlistener(dynamicRangeSlider, 'ContinuousValueChange', @(obj,evt) calculateBeamPattern(obj, evt, 'dynamicRange') );
txtdB = annotation('textbox', [0.5, 0.065, 0, 0], 'string', 'dB');

%Set color theme
if isequal(displayTheme,'black')
    setTheme(fig, fig, 'Black');
elseif isequal(displayTheme,'white')
    setTheme(fig, fig, 'White');
else
    error('Use black or white for displayStyle')
end


%Enable the context menu regardless of right clicking on figure, axes or plot
ax.UIContextMenu = cm;
fig.UIContextMenu = cm;
spherePlot.UIContextMenu = cm;
circlePlot.UIContextMenu = cm;
bpPlot.UIContextMenu = cm;

    function calculateBeamPattern(obj, evt, type)
        
        if ~strcmp(type, 'init')
            delete(bpPlot)
        else
            spherePlot = surf(ax, sx*maxDynamicRange,sy*maxDynamicRange,sz*maxDynamicRange, ...
                'edgecolor','none', 'FaceColor', fColor, 'FaceAlpha', fAlpha);
            circlePlot = plot(ax, cos(0:pi/50:2*pi)*maxDynamicRange, sin(0:pi/50:2*pi)*maxDynamicRange, ...
                'Color', fColor);
        end
        
        if ~strcmp(type, 'dynamicRange')
            if strcmp(type, 'frequency')
                f = obj.Value;
            elseif strcmp(type, 'thetaAngle')
                thetaSteeringAngle = obj.Value;
            elseif strcmp(type, 'phiAngle')
                phiSteeringAngle = obj.Value;
            end
            
            [beamPattern, thetaScanningAnglesRadians, phiScanningAnglesRadians] = arrayFactor(xPos, yPos, w, f, c, thetaScanningAngles, ...
                phiScanningAngles, thetaSteeringAngle, phiSteeringAngle);
            [phiScanningAnglesRadians, thetaScanningAnglesRadians] = meshgrid(phiScanningAnglesRadians, thetaScanningAnglesRadians);
            beamPattern = 20*log10(beamPattern);
            
        else
            maxDynamicRange = obj.Value;
            delete(spherePlot)
            delete(circlePlot)
            spherePlot = surf(ax, sx*maxDynamicRange,sy*maxDynamicRange,sz*maxDynamicRange, ...
                'edgecolor','none', 'FaceColor', fColor, 'FaceAlpha', fAlpha);
            circlePlot = plot(ax, cos(0:pi/50:2*pi)*maxDynamicRange, sin(0:pi/50:2*pi)*maxDynamicRange, ...
                'Color', fColor);
        end
        
        
        
        beamPatternDynamicRange = beamPattern + maxDynamicRange;
        
        xx = (beamPatternDynamicRange) .* sin(thetaScanningAnglesRadians) .* cos(phiScanningAnglesRadians);
        yy = (beamPatternDynamicRange) .* sin(thetaScanningAnglesRadians) .* sin(phiScanningAnglesRadians);
        zz = (beamPatternDynamicRange) .* cos(thetaScanningAnglesRadians);
        
        interpolationFactor = 2;
        interpolationMethod = 'spline';
        
        xx = interp2(xx, interpolationFactor, interpolationMethod);
        yy = interp2(yy, interpolationFactor, interpolationMethod);
        zz = interp2(zz, interpolationFactor, interpolationMethod);
        
        
        maxHeight = max(max(zz));
        bpPlot = surf(ax, xx, yy, zz, 'edgecolor', 'none');

        
        
        spherePlot.UIContextMenu = cm;
        circlePlot.UIContextMenu = cm;
        bpPlot.UIContextMenu = cm;
        
        caxis(ax, [0 maxHeight])
        ax.ZLim = [0 maxDynamicRange];
        ax.XLim = [-maxDynamicRange maxDynamicRange];
        ax.YLim = [-maxDynamicRange maxDynamicRange];
        
        setOrientation(fig, fig, displayStyle)
        
        t = title(ax, ['Dynamic range: ' sprintf('%0.1f', maxDynamicRange) ...
            ' dB, \theta = ' sprintf('%0.0f', thetaSteeringAngle) ...
            ', \phi = ' sprintf('%0.0f', phiSteeringAngle) ...
            ', f = ' sprintf('%0.1f', f*1e-3) ' kHz'],'fontweight','normal');
    end




    %Function to change between 2D and 3D in plot
    function setOrientation(~, ~, selectedOrientation)
        displayStyle = selectedOrientation;
        if strcmp(selectedOrientation, '2D')
            view(ax, 0, 90)
        elseif strcmp(selectedOrientation, '3D')
            view(ax, 30, 20)
        else
            error('Use 2D or 3D for displayStyle')
        end
        
    end


    %Function to change between black and white theme
    function setTheme(~, ~, selectedTheme)
        cmap = colormap;
        if strcmp(selectedTheme,'Black')
            fig.Color = 'k';
            t.Color = 'w';
            txtTheta.Color = 'w';
            txtPhi.Color = 'w';
            txtF.Color = 'w';
            txtdB.Color = 'w';
            cmap(1,:) = [1 1 1]*0.2;
            ax.Color = [0 0 0];
            ax.XColor = [1 1 1];
            ax.YColor = [1 1 1];
            ax.ZColor = [1 1 1];
            ax.MinorGridColor = [1 1 1];
            fColor = [1 1 1];
            fAlpha = 0.25;
            spherePlot.FaceColor = fColor;
            spherePlot.FaceAlpha = fAlpha;
            circlePlot.Color = fColor;
        elseif strcmp(selectedTheme,'White')
            fig.Color = 'w';
            t.Color = 'k';
            txtTheta.Color = 'k';
            txtPhi.Color = 'k';
            txtF.Color = 'k';
            txtdB.Color = 'k';
            cmap(1,:) = [1 1 1]*0.9;
            ax.Color = [1 1 1];
            ax.XColor = [0 0 0];
            ax.YColor = [0 0 0];
            ax.ZColor = [0 0 0];
            ax.MinorGridColor = [0 0 0];
            fColor = [0 0 0];
            fAlpha = 0.1;
            spherePlot.FaceColor = fColor;
            spherePlot.FaceAlpha = fAlpha;
            circlePlot.Color = fColor;
        else
            error('Use black or white for displayStyle')
        end
        colormap(ax, cmap);
    end

end