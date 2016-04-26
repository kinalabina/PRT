function FileStruct = prtPlotUtilGraphVizRun(connectivity)
% Internal function, 
% xxx Need Help xxx
% FileInfo = prtPlotUtilGraphVizRun(connectivity)
%   Calls the GraphViz binary neato on the graph specified by 
%   connectivity matrix.
% 
%   This requires that GraphViz is installed and available from the command
%   prompt





% Write file for graphviz
tempDotFileName = fullfile(tempdir,'_tempPrtGraphVizGraph.dot');
prtPlotUtilGraphVizWriteDot(connectivity, tempDotFileName);

% Create graphviz command 
% -Gsplines=true -Gsep=0.1
% -Glevelsgap=100
% -Gratio="expand" 
% -Goverlap=true
% -Gminlen=5 
% -Gdiredgeconstraints= 
% -Gnojustify=true
% -Gpack=true
% -Gratio="expand"
%commandStr = 'neato -Tdot -Gminlen=2 -Gnormalize=true  -Gmaxiter=25000 -Gmode=hier -Glevelsgap=10 -Grankdir="LR" -y';
%commandStr = 'sfdp -Tdot -Gnormalize=true -Gratio="expand" -Gmaxiter=25000 -Gquadtree=true -Glevels=6 -y';

exName = 'mwdot';
if ispc
    exName = cat(2,exName,'.exe');
end
mwdot = fullfile(matlabroot,'bin',lower(computer('arch')),exName);

if ispc
    commandStr = cat(2,'"',mwdot,'"', ' -Tplain');
else
    commandStr = cat(2, mwdot, ' -Tplain');
end
commandStr = cat(2,commandStr,' "',tempDotFileName,'"');

% Call graphviz
[systemStatus, systemResult] = system(commandStr); %#ok<NASGU>
%%
if systemStatus
    error('prtPlotUtilGraphVizRun:graphvizIssue','Problem running mwdot. The MATLAB install of mwdot was not succesfully run. Please report this issue to the developers.')
    % Do you have it installed and on the system path? Try >>system(''dot -V'') to see.
    % You may need to restart.
end

%%

%%%%%%

%split file content into individual lines using the REGEXP function
fileContent=regexp(systemResult,'\n','split')';

graphLine=[fileContent{~cellfun('isempty',regexp(fileContent,'^graph'))}];

%split the line into individual words
tokens=regexp(graphLine,'\s+','split');

scale=str2double(tokens{2});

%Start parsing node line entries out of the file
nodeLines=fileContent(~cellfun('isempty',regexp(fileContent,'^node')));

% wow this hurts my head!
tokens=regexp(nodeLines,...
    ['node\s+(?<nodeID>"[^"]+"|[\w\d]+)\s+(?<x>[\d\.\+e]+)\s' ...
    '+(?<y>[\d\.\+e]+)\s+(?<w>[\d\.\+e]+)\s+(?<h>[\d\.\+e]+)' ...
    '\s+(?<label>".*"|[\w\d]+)\s+(?<style>\w+)\s+(?<shape>' ...
    '[\w\d]+)\s+(?<edgeColour>(?:[#\w][\w\d]+)|[\d\.]+\s+[\d\.]' ...
    '+\s+[\d\.]+)\s+(?<bgColour>(?:[#\w][\w\d]+)|[\d\.]' ...
    '+\s+[\d\.]+\s+[\d\.]+)'],'tokens');

% transform the cell array
tokens=[tokens{:}]';

% transform the cell array, again
tokens=[tokens{:}]';

% reshape the cell array
tokens=reshape(tokens,10,[])';

%get the node names
nodeIDs=regexprep(tokens(:,1),'"','');

%get the node's X-Y location, height, and width
x=cellfun(@str2double,tokens(:,2))*scale;
y=cellfun(@str2double,tokens(:,3))*scale;
w=cellfun(@str2double,tokens(:,4))*scale;
h=cellfun(@str2double,tokens(:,5))*scale;

%get the shapes of each node
shapes=tokens(:,8);

%Parse in edge commands
edgeLines=fileContent(~cellfun('isempty',regexp(fileContent,'^edge')));

% wow this hurts my head!
tokens=regexp(edgeLines,['edge\s+(?<tail>(?:"[^"]+")|(?:[\w\d]+))'...
    '\s+(?<tip>(?:"[^"]+")|([\w\d]+))\s+(?<numSpline>\d+)\s'...
    '+([\d\.\+e\s]+)\s+((".*"|[\w\d]+)\s+([\d\.\+e]+)\s+([\d\.\+e]'...
    '+)\s+)?(\w+)\s+(?<bgColour>(?:[#\w][#\w\d:]+)|[\d\.]+\s'...
    '+[\d\.]+\s+[\d\.]+)'],'tokens');

% transform cell array
tokens=[tokens{:}]';

% transform cell array, again
tokens=[tokens{:}]';

% reshape the cell array
tokens=reshape(tokens,7,[])';

for iEdge = 1:size(tokens,1)
    
    FileStruct.Edges(iEdge).startId = tokens(iEdge,1);
    FileStruct.Edges(iEdge).stopId = tokens(iEdge,2);
        
    FileStruct.Edges(iEdge).startIndex = str2double(tokens(iEdge,1));
    FileStruct.Edges(iEdge).stopIndex = str2double(tokens(iEdge,2));
        
    FileStruct.Edges(iEdge).isDirected = true; % New system only has directed nodes

end

y = max(y)-y; % Make it go right to left instead of top to bottom turned 90 degrees. 

nNodes = length(nodeIDs);
for iNode = 1:nNodes
    FileStruct.Nodes(iNode).id = nodeIDs{iNode};
    FileStruct.Nodes(iNode).x = x(iNode);
    FileStruct.Nodes(iNode).y = y(iNode);
    FileStruct.Nodes(iNode).w = w(iNode);
    FileStruct.Nodes(iNode).h = h(iNode);
    %FileStruct.Nodes(iNode).pos = [x(iNode) y(iNode) w(iNode) h(iNode)];
    FileStruct.Nodes(iNode).pos = [y(iNode) x(iNode)];
    FileStruct.Nodes(iNode).shape = shapes{iNode};
end


% Clean up temporary files 
delete(tempDotFileName);
