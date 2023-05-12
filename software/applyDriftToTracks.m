function tracksNA = applyDriftToTracks(tracksNA, T, efficientSDC) 
% function tracksNA = applyDriftToTracks(tracksNA, T, efficientSDC) applied
% translation transformation from SDC Process to the tracksNA.
% Sangyoon Han, 2016.
%
% Copyright (C) 2023, Danuser Lab - UTSouthwestern 
%
% This file is part of FocalAdhesionPackage.
% 
% FocalAdhesionPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% FocalAdhesionPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with FocalAdhesionPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 
if nargin<3
    efficientSDC=true;
end

nFrames = length(T);

if efficientSDC
    maxX = 0;
    maxY = 0; % this is to account for zero-padding 
else
    % Get limits of transformation array
    maxX = ceil(max(abs(T(:, 2))));
    maxY = ceil(max(abs(T(:, 1)))); % this is to account for zero-padding 
end

progressText(0,'Apply stage drift correction to tracksNA:')
for i = 1:numel(tracksNA)
    for  j = 1 : nFrames
        tracksNA(i).xCoord(j) = tracksNA(i).xCoord(j)+T(j,2)+maxX;
        tracksNA(i).yCoord(j) = tracksNA(i).yCoord(j)+T(j,1)+maxY;
        tracksNA(i).closestBdPoint(:,1) = tracksNA(i).closestBdPoint(:,1)+T(j,2)+maxX;
        tracksNA(i).closestBdPoint(:,2) = tracksNA(i).closestBdPoint(:,2)+T(j,1)+maxY;
        
        % look at every aspects in the feature and shift them
        % Also, labelTif should be also shifted.
        
%         try
%             tracksNA(i).adhBoundary{j} = [tracksNA(i).adhBoundary{j}(:,2)+T(j,2)+maxX tracksNA(i).adhBoundary{j}(:,1)+T(j,1)+maxY];
%             tracksNA(i).FApixelList{j} = [tracksNA(i).FApixelList{j}(:,2)+T(j,2)+maxX tracksNA(i).FApixelList{j}(:,1)+T(j,1)+maxY];
%         catch
%             tracksNA(i).adhBoundary{j} = [];
%             tracksNA(i).FApixelList{j} = [];
%         end
    end
    tracksNA(i).SDC_applied = true;
    progressText(i/numel(tracksNA),'Apply stage drift correction to tracksNA:')
end

end
