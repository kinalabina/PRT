function Yout = prtUtilEvalCAPtree(tree,X,nClasses)
%Yout = evalCAPtree(tree,X)
%   Evaluate a CAP tree on a 1xN data point X
% Internal 
% xxx Need Help xxx

% Copyright (c) 2014 CoVar Applied Technologies
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.





if nargin < 3 || isempty(nClasses)
    nClasses = 2;
end

index = 1;
voted = false;
while ~voted
    if any(isfinite(tree.W(:,index)))
        %disp(((tree.W(:,index)'*X(:,tree.featureIndices(:,index))')') - tree.threshold(:,index))
        Yout = double(((tree.W(:,index)'*X(:,tree.featureIndices(:,index))')' - tree.threshold(:,index)) >= 0);
        if Yout == 0
            index = find(tree.treeIndices(:) == index,1,'first');
        elseif Yout > 0
            index = find(tree.treeIndices(:) == index,1,'last');
        end
    else
        Yout = zeros(1,nClasses);
        Yout(tree.terminalVote(index)) = 1;
        voted = true;
    end
end
