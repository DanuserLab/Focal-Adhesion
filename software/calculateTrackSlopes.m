function tracksNA = calculateTrackSlopes(tracksNA,tInterval)
% tracksG1 = calculateTrackSlopes(tracksG1) calculates slopes of force and
% amplitude from first minute or half lifetime.
% Sangyoon Han, December, 2015
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

tIntervalMin = tInterval/60;
prePeriodFrame = ceil(10/tInterval); %pre-10 sec
for k=1:numel(tracksNA)
    sF=max(tracksNA(k).startingFrameExtra-prePeriodFrame,tracksNA(k).startingFrameExtraExtra);
    
%     eF=tracksNA(k).endingFrameExtra;
    curLT = tracksNA(k).lifeTime;
    halfLT = ceil(curLT/2);
    earlyPeriod = min(halfLT,floor(60/tInterval)); % frames per a minute or half life time

    lastFrame = min(tracksNA(k).endingFrameExtraExtra,sF+earlyPeriod+prePeriodFrame-1);
    lastFrameFromOne = lastFrame - sF+1;
    
    [~,curM] = regression(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).amp(sF:lastFrame));
    tracksNA(k).earlyAmpSlope = curM; % in a.u./min
    [curForceR,curForceM] = regression(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).forceMag(sF:lastFrame));
%         figure, plot(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).forceMag(sF:lastFrame))
%         figure, plotregression(tIntervalMin*(1:lastFrameFromOne),tracksNA(k).forceMag(sF:lastFrame))
    tracksNA(k).forceSlope = curForceM; % in Pa/min
    tracksNA(k).forceSlopeR = curForceR; % Pearson's correlation coefficient
end
