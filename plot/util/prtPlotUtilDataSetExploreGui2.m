function prtPlotUtilDataSetExploreGui2(ds,plotInds)
% Internal function,
% xxx Need Help xxx - see prtDataSetClass.explore


if strcmpi(get(gcf,'tag'),'prtDataSetExplorerControl')
    % Current figure is nav controls
    % so make a new one
    figure
end

% Current figure is new (made by gcf call above) or existed
plotAxes = gca; % Will make an axes if one isn't already there.

if ds.nObservations > 1
    plotInds = [1 2 0];
else
    plotInds = [1 1 0];
end

excludedClassInds = [];

% Make control panel figure
plotAxesFig = get(plotAxes,'parent');
plotAxesFigPos = get(plotAxesFig,'position');

navFigSize = [300 250];
navFigPad = [18 59];

navFigPosTop = plotAxesFigPos(2)+plotAxesFigPos(4);
navFigPosLeft = plotAxesFigPos(1)+plotAxesFigPos(3);

navFigPos = cat(2,navFigPosLeft+navFigPad(1), navFigPosTop-navFigSize(2)+navFigPad(2), navFigSize(1), navFigSize(2));

navFigH = figure('Number','Off',...
    'Name','PRT Dataset Explorer Controls',...
    'Menu','none',...
    'Toolbar','none',...
    'Units','pixels',...
    'Position',navFigPos,...
    'NextPlot','new',...
    'tag','prtDataSetExplorerControl',...
    'DockControls','off');

% Just in case anyone tries to plot in this window (which is rather
% difficult) we will plot that inside an invisible axes
invisibleAxes = axes('parent',navFigH,...
    'units','pixels',...
    'position',[1 1 1 1],...
    'visible','off');

tabGroupH = createTabGroup(ds);

PlotHandles = []; % Add to all workspaces
remakePlot();

    function setAxesDeleteFunction()
        set(plotAxes,'deleteFcn',@plotAxesDeleteFunction)
    end
    function plotAxesDeleteFunction(myHandle, evenData) %#ok<INUSD>
        try %#ok<TRYNC>
            close(navFigH)
        end
    end
    function uitableEditFun(source, eventData) %#ok<INUSD>
        updateVisibleClasses();
    end

    function featureSelectPopupCallback(myHandle, eventData, varargin)  %#ok<INUSL>
        cVal = get(myHandle,'value');
        axisInd = varargin{1};
        if axisInd == 3
            % Z-axis we have a None option
            cVal = cVal - 1;
        end
        plotInds(axisInd) = cVal;
        
        remakePlot();
    end

    function updateVisibleClasses()
        cData = get(tabGroupH.uitable,'data');
        displayLogical = cat(1,cData{:,2});
        
        for iClass = 1:length(PlotHandles)
            if displayLogical(iClass)
                set(PlotHandles(iClass),'visible','on');
            else
                set(PlotHandles(iClass),'visible','off');
            end
        end
        
    end

    function remakePlot()
        
        actualPlotDims = plotInds(plotInds>=1);
        axes(plotAxes); %#ok<MAXES>
        PlotHandles = plot(ds,actualPlotDims);
        % Set the plotAxes delete function so that we delete the controls
        % when necessary.
        % We have to reset this each time
        setAxesDeleteFunction()
        
        updateVisibleClasses()
    end

    function H = createTabGroup(ds)
        % Make control panel uitabs and uipanels
        H.navTabGroup = prtUtilUitabgroup('parent',navFigH);
        H.navTab(1) = prtUtilUitab(H.navTabGroup, 'title', 'Features');
        H.navTab(2) = prtUtilUitab(H.navTabGroup, 'title', 'Classes');
        
        H.navPanel(1) = uipanel(H.navTab(1));
        H.navPanel(2) = uipanel(H.navTab(2));
        
        % Make Feature Selection panel
        featureNames = ds.getFeatureNames;
        H.xAxesLabel = uicontrol(H.navTab(1),'style','text',...
            'units','normalized',...
            'position',[0.025 0.875 0.95 0.1],...
            'string','X Axis',...
            'FontWeight','bold',...
            'horizontalAlignment','left',...
            'FontUnits','normalized',...
            'FontSize',0.75);
        
        H.xPopUp = uicontrol(H.navTab(1),'style','popup',...
            'units','normalized',...
            'position',[0.025 0.675 0.95 0.2],...
            'string',featureNames,...
            'FontUnits','normalized',...
            'FontSize',0.5,...
            'callback',{@featureSelectPopupCallback 1});
        
        H.yAxesLabel = uicontrol(H.navTab(1),'style','text',...
            'units','normalized',...
            'position',[0.025 0.55 0.95 0.1],...
            'string','Y Axis',...
            'FontWeight','bold',...
            'horizontalAlignment','left',...
            'FontUnits','normalized',...
            'FontSize',0.75);
        
        H.yPopUp = uicontrol(H.navTab(1),'style','popup',...
            'units','normalized',...
            'position',[0.025 0.35 0.95 0.2],...
            'string',featureNames,...
            'FontUnits','normalized',...
            'FontSize',0.5,...
            'callback',{@featureSelectPopupCallback 2});
        
        
        H.zAxesLabel = uicontrol(H.navTab(1),'style','text',...
            'units','normalized',...
            'position',[0.025 0.225 0.95 0.1],...
            'string','Z Axis',...
            'FontWeight','bold',...
            'horizontalAlignment','left',...
            'FontUnits','normalized',...
            'FontSize',0.75);
        
        H.zPopUp = uicontrol(H.navTab(1),'style','popup',...
            'units','normalized',...
            'position',[0.025 0.025 0.95 0.2],...
            'string',cat(1,{'None'}, featureNames),...
            'FontUnits','normalized',...
            'FontSize',0.5,...
            'callback',{@featureSelectPopupCallback 3});
        
        
        set(H.xPopUp,'value',plotInds(1))
        set(H.yPopUp,'value',plotInds(2))
        if plotInds(3) > 0
            set(H.zPopUp,'value',plotInds(3))
        else
            set(H.zPopUp,'value',plotInds(1)) % None;
        end
        
        
        % Make classes uitable with tick boxes
        H.uitable = uitable('parent',H.navPanel(2),...
            'units','Normalized',...
            'position',[0.025 0.025 0.95 0.95],...
            'columnFormat',{'char','logical'},...
            'ColumnEditable',[false true],...
            'RowName',[],...
            'ColumnName',{'Class' 'Plot'},...
            'FontUnits','normalized',...
            'FontSize',0.1,...
            'SelectionHighlight','off',...
            'CellEditCallback',@uitableEditFun,...
            'data',cat(2,ds.getClassNames,num2cell(true(ds.nClasses,1))));
        
        % Column widths must be specified in pixels
        set(H.uitable,'units','pixels')
        uitablePos = floor(get(H.uitable,'position'));
        leftColumnWidth = floor(uitablePos(3)*0.7);
        set(H.uitable,'ColumnWidth', {leftColumnWidth uitablePos(3)-leftColumnWidth-22});
        set(H.uitable,'units','normalized')
    end

end


% windowSize = [754 600];
% pos = prtPlotUtilCenterFigure(windowSize);
%
% % Create the figure an UIControls
% figH = figure('Number','Off',...
%               'Name','PRT Data Set Explorer',...
%               'Menu','none',...
%               'toolbar','figure',...
%               'units','pixels',...
%               'position',pos,...
%               'DockControls','off');
%
% % Trim the toolbar down to just the zooming controls
% Toolbar.handle = findall(figH,'Type','uitoolbar');
% Toolbar.Children = findall(figH,'Parent',Toolbar.handle,'HandleVisibility','off');
%
% % Delete a bunch of things we dont need
% delete(findobj(Toolbar.Children,'TooltipString','New Figure',...
%     '-or','TooltipString','Open File','-or','TooltipString','Save Figure',...
%     '-or','TooltipString','Print Figure','-or','TooltipString','Edit Plot',...
%     '-or','TooltipString','Data Cursor','-or','TooltipString','Brush/Select Data',...
%     '-or','TooltipString','Link Plot','-or','TooltipString','Insert Colorbar',...
%     '-or','TooltipString','Insert Legend','-or','TooltipString','Show Plot Tools and Dock Figure',...
%     '-or','TooltipString','Hide Plot Tools'))
%
% popUpStrs = theObject.getFeatureNames;
%
% bgc = get(figH,'Color');
% popX = uicontrol(figH,'Style','popup','units','normalized','FontUnits','Normalized','FontSize',0.6,'position',[0.15 0.01 0.19 0.04],'string',popUpStrs,'callback',{@plotSelectPopupCallback 1});
% popXHead = uicontrol(figH,'Style','text','units','normalized','FontUnits','Normalized','FontSize',0.75,'position',[0.05 0.01 0.09 0.04],'string','X-Axis:','BackgroundColor',bgc,'HorizontalAlignment','Right'); %#ok
%
% popY = uicontrol(figH,'Style','popup','units','normalized','FontUnits','Normalized','FontSize',0.6,'position',[0.45 0.01 0.19 0.04],'string',popUpStrs,'callback',{@plotSelectPopupCallback 2});
% popYHead = uicontrol(figH,'Style','text','units','normalized','FontUnits','Normalized','FontSize',0.75,'position',[0.35 0.01 0.09 0.04],'string','Y-Axis:','BackgroundColor',bgc,'HorizontalAlignment','Right'); %#ok
%
% popZ = uicontrol(figH,'Style','popup','units','normalized','FontUnits','Normalized','FontSize',0.6,'position',[0.75 0.01 0.19 0.04],'string',[{'None'}; popUpStrs],'callback',{@plotSelectPopupCallback 3});
% popZHead = uicontrol(figH,'Style','text','units','normalized','FontUnits','Normalized','FontSize',0.75,'position',[0.65 0.01 0.09 0.04],'string','Z-Axis:','BackgroundColor',bgc,'HorizontalAlignment','Right'); %#ok
%
% axisH = axes('Units','Normalized','outerPosition',[0.05 0.07 0.9 0.9]);
%
% % Setup the PopOut Option
% hcmenu = uicontextmenu;
% hcmenuPopoutItem = uimenu(hcmenu, 'Label', 'Popout', 'Callback', @explorerPopOut); %#ok
% set(axisH,'UIContextMenu',hcmenu);
%
% if theObject.nFeatures > 1
%     plotDims = [1 2 0];
%
%     set(popX,'value',1); % Becase we have dont have a none;
%     set(popY,'value',2); % Becase we have dont have a none;
%     set(popZ,'value',1); % Becase we have a none;
% else
%     plotDims = [1 1 0];
%
%     set(popX,'value',1); % Becase we have dont hvae a none;
%     set(popY,'value',1); % Becase we have a none;
%     set(popZ,'value',1); % Becase we have a none;
% end
% updatePlot;
%
%     function plotSelectPopupCallback(myHandle, eventData, varargin) %#ok
%         cVal = get(myHandle,'value');
%         axisInd = varargin{1};
%         if axisInd == 3
%             % Z-axis we have a None option
%             cVal = cVal - 1;
%         end
%         plotDims(axisInd) = cVal;
%         updatePlot;
%     end
%
%     function updatePlot
%         actualPlotDims = plotDims(plotDims>=1);
%         axes(axisH); %#ok
%         h = plot(theObject,actualPlotDims);
%         set(h,'HitTest','off');
%         set(axisH,'ButtonDownFcn',@axisOnClick);
%     end
%     function explorerPopOut(myHandle,eventData) %#ok
%         figure;
%         actualPlotDims = plotDims(plotDims>=1);
%         plot(theObject,actualPlotDims);
%     end
%     function axisOnClick(myHandle,eventData)
%         actualPlotDims = plotDims(plotDims>=1);
%         data = theObject.getFeatures(actualPlotDims);
%
%         [rP,rD] = rotateDataAndClick(data);
%
%         dist = prtDistanceEuclidean(rP,rD);
%         [~,i] = min(dist);
%         obsName = theObject.getObservationNames(i);
%         title(sprintf('Observation Closest To Last Click: %s',obsName{1}));
%
%         debug = false;
%         if debug
%             hold on;
%             d = theObject.getObservations(i);
%             switch length(actualPlotDims)
%                 case 2
%                     plot(d(1),d(2),'kx');
%                 case 3
%                     plot3(d(1),d(2),d(3),'kx');
%             end
%             hold off;
%         end
%     end
%
%     function [rotatedData,rotatedClick] = rotateDataAndClick(data)
%         %[rotatedData,rotatedClick] = rotateDataAndClick(data)
%         % Used internally; from Click3dPoint from matlab central; need
%         % copyright here.
%
%         point = get(gca, 'CurrentPoint'); % mouse click position
%         camPos = get(gca, 'CameraPosition'); % camera position
%         camTgt = get(gca, 'CameraTarget'); % where the camera is pointing to
%
%         camDir = camPos - camTgt; % camera direction
%         camUpVect = get(gca, 'CameraUpVector'); % camera 'up' vector
%
%         % build an orthonormal frame based on the viewing direction and the
%         % up vector (the "view frame")
%         zAxis = camDir/norm(camDir);
%         upAxis = camUpVect/norm(camUpVect);
%         xAxis = cross(upAxis, zAxis);
%         yAxis = cross(zAxis, xAxis);
%
%         rot = [xAxis; yAxis; zAxis]; % view rotation
%
%         if size(data,2) < 3
%             data = cat(2,data,zeros(size(data,1),1));
%         end
%
%         % the point cloud represented in the view frame
%         rotatedData = (rot * data')';
%         rotatedData = rotatedData(:,1:2);
%         % the clicked point represented in the view frame
%         rotatedClick = rot * point' ;
%         rotatedClick = rotatedClick(1:2,1)';
%     end
% end