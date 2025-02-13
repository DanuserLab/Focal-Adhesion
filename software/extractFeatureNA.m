function [dataTable,allData,meas] = extractFeatureNA(tracksNA,idGroupSelected, normalizationMethods, MD,useOldSet)
if nargin<3
    normalizationMethods=2;
    MD=[];
    useOldSet=false;
elseif nargin<4
    MD=[];
    useOldSet=false;
elseif nargin<5
    useOldSet=false;
end
if isempty(MD)
    pixSize=72; %nm/pix
    timeInterval = 5; %sec
else
    pixSize=MD.pixelSize_; %nm/pix
    timeInterval = MD.timeInterval_; %sec
end
    
% normalizationMethods=1 means no-normalization
% normalizationMethods=2 means normalization with maxIntensity and speed with computer units
% normalizationMethods=3 means normalization with maxIntensity and speed with physical distance and time units
% normalizationMethods=4 means normalization with maxIntensity and maxEdgeAdvance*pixSize and lifeTime in sec (using tInterval).
% normalizationMethods=5 means normalizationMethods=5 means normalization per each feature min and max
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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

%#1
maxIntensityNAs = arrayfun(@(x) nanmax(x.ampTotal),tracksNA); %this should be high for group 2

% startingIntensityNAs = arrayfun(@(x) x.ampTotal(x.startingFrameExtra),tracksNA); %this should be high for group 2 and low for both g1 and g2
endingIntensityNAs = arrayfun(@(x) x.ampTotal(x.endingFrameExtra),tracksNA); %this should be high for group 2

decayingIntensityNAs = maxIntensityNAs-endingIntensityNAs; % this will differentiate group 1 vs group 2.
%#2
edgeAdvanceDistNAs = arrayfun(@(x) x.edgeAdvanceDist(x.endingFrameExtra),tracksNA); %this should be also low for group 3
%#3
advanceDistNAs = arrayfun(@(x) x.advanceDist(x.endingFrameExtra),tracksNA); %this should be also low for group 3
%#4
lifeTimeNAs = arrayfun(@(x) x.lifeTime,tracksNA); %this should be low for group 6
%#5
meanIntensityNAs = arrayfun(@(x) nanmean(x.amp),tracksNA); %this should be high for group 2
%#6
distToEdgeFirstNAs = arrayfun(@(x) x.distToEdge(x.startingFrameExtra),tracksNA); %this should be low for group 3
%#7
startingIntensityNAs = arrayfun(@(x) x.ampTotal(x.startingFrameExtra),tracksNA); %this should be high for group 5 and low for both g1 and g2
%#8
distToEdgeChangeNAs = arrayfun(@(x) x.distToEdgeChange,tracksNA); %this should be low for group 3 and group 5
%#9
distToEdgeLastNAs = arrayfun(@(x) x.distToEdge(x.endingFrameExtra),tracksNA); %this should be low for group 3 and group 7
%#10
edgeAdvanceDistFirstChangeNAs =  arrayfun(@(x) x.advanceDistChange2min(min(x.startingFrameExtra+30,x.endingFrameExtra)),tracksNA); %this should be negative for group 5 and for group 7
%#11
edgeAdvanceDistLastChangeNAs =  arrayfun(@(x) x.advanceDistChange2min(x.endingFrameExtra),tracksNA); %this should be negative for group 5 and for group 7
%#12
maxEdgeAdvanceDistChangeNAs =  arrayfun(@(x) x.maxEdgeAdvanceDistChange,tracksNA); %This is to see if 
%#13
% maxIntensityNAs % This should be higher in g2 than g1
%#14 time to maximum: This should be long for maturing adhesion G2
splineParam=0.1;
% sd=ppval(csaps(x.iFrame,x.ampTotal,splineParam),x.iFrame);
if ~useOldSet
    timeToMaxInten=zeros(numel(tracksNA),1);
    for ii=1:numel(tracksNA)
        d = tracksNA(ii).ampTotal;
        tRange = tracksNA(ii).iFrame;
        warning('off','SPLINES:CHCKXYWP:NaNs')
        d(d==0)=NaN;
        try
            sd_spline= csaps(tRange,d,splineParam);
        catch
            d = tracksNA(ii).amp;
            d(tracksNA(ii).startingFrameExtraExtra:tracksNA(ii).endingFrameExtraExtra) = ...
                tracksNA(ii).ampTotal(tracksNA(ii).startingFrameExtraExtra:tracksNA(ii).endingFrameExtraExtra);
            sd_spline= csaps(tRange,d,splineParam);
        end
        sd=ppval(sd_spline,tRange);
        %         tRange = [NaN(1,numNan) tRange];
    %     sd = [NaN(1,numNan) sd];
        sd(isnan(d))=NaN;
        %         sd(isnan(d)) = NaN;
        % Find the maximum
        [~,curFrameMaxAmp]=nanmax(sd);
        timeToMaxInten(ii) = curFrameMaxAmp-tracksNA(ii).startingFrameExtra;
    end
    % timeToMaxInten = arrayfun(@(x) find(x.ampTotal==nanmax(x.ampTotal),1),tracksNA); %in frame, this should be high for group 2 
    %#15
    edgeVariation = arrayfun(@(x) min(nanstd(x.closestBdPoint(:,1)),nanstd(x.closestBdPoint(:,2))),tracksNA);
end
% this adhesion once had fast protruding edge, thus crucial for
% distinguishing group 3 vs 7. For example, group 7 will show low value for
% this quantity because edge has been stalling for entire life time.

% Some additional features - will be commented out eventually
% asymTracks=arrayfun(@(x) asymDetermination([x.xCoord(logical(x.presence))', x.yCoord(logical(x.presence))']),tracksNA);
% MSDall=arrayfun(@(x) sum((x.xCoord(logical(x.presence))'-mean(x.xCoord(logical(x.presence)))).^2+...
%     (x.yCoord(logical(x.presence))'-mean(x.yCoord(logical(x.presence)))).^2),tracksNA());
%% All the maxima
maxIntensity = max(maxIntensityNAs(:)); %Now I started to normalize these things SH 16/07/06
maxEdgeAdvance = max(edgeAdvanceDistNAs(:))*pixSize;

% MSDrate = MSDall./lifeTimeNAs;
advanceSpeedNAs = advanceDistNAs./lifeTimeNAs; %this should be also low for group 3
% relMovWRTEdge = distToEdgeChangeNAs./lifeTimeNAs;
minVal=1e-5;

switch normalizationMethods
    case 1
        disp('Use unnormalized')
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeNAs; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeNAs; %this should be also low for group 3
    case 2 % normalizationMethods=2 means normalization with maxIntensity and speed with computer units
        decayingIntensityNAs = decayingIntensityNAs/maxIntensity;      %#1
        meanIntensityNAs = meanIntensityNAs/maxIntensity;                %#5
        startingIntensityNAs = startingIntensityNAs/maxIntensity;           %#7
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeNAs; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeNAs; %this should be also low for group 3
        maxIntensityNAs=maxIntensityNAs/maxIntensity; % This should be higher in g2 than g1
    case 3 % normalizationMethods=3 means normalization with maxIntensity and speed with physical distance and time units
        decayingIntensityNAs = decayingIntensityNAs/maxIntensity;      %#1
        meanIntensityNAs = meanIntensityNAs/maxIntensity;                %#5
        startingIntensityNAs = startingIntensityNAs/maxIntensity;           %#7
        
        lifeTimeSec = lifeTimeNAs*timeInterval;
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3

        tIntervalMin = timeInterval/60; % in min
        frames2min = floor(2/tIntervalMin); % early period in frames

        timeFirstChangeNAs =  arrayfun(@(x) min(30,x.endingFrameExtra-x.startingFrameExtra),tracksNA); 
        timeLastChangeNAs =  arrayfun(@(x) min(frames2min, (x.endingFrameExtra-x.startingFrameExtra)),tracksNA); 
        timeFirstChangeSec = timeFirstChangeNAs*timeInterval;
        timeLastChangeSec = timeLastChangeNAs*timeInterval;
        edgeAdvanceDistFirstChangeNAs = edgeAdvanceDistFirstChangeNAs./timeFirstChangeSec*pixSize;
        edgeAdvanceDistLastChangeNAs = edgeAdvanceDistLastChangeNAs./timeLastChangeSec*pixSize;
        distToEdgeFirstNAs = distToEdgeFirstNAs*pixSize;
        distToEdgeChangeNAs= distToEdgeChangeNAs*pixSize;
        distToEdgeLastNAs= distToEdgeLastNAs*pixSize;
        maxEdgeAdvanceDistChangeNAs= maxEdgeAdvanceDistChangeNAs*pixSize;
        maxIntensityNAs=maxIntensityNAs/maxIntensity; % This should be higher in g2 than g1
        if ~useOldSet
            edgeVariation= edgeVariation*pixSize;
        end
    case 4 % normalizationMethods=4 means normalization with maxIntensity and maxEdgeAdvance*pixSize and lifeTime in sec (using tInterval).
        decayingIntensityNAs = decayingIntensityNAs/maxIntensity;      %#1
        meanIntensityNAs = meanIntensityNAs/maxIntensity;                %#5
        startingIntensityNAs = startingIntensityNAs/maxIntensity;           %#7
        
        lifeTimeSec = lifeTimeNAs*timeInterval;
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3

        tIntervalMin = timeInterval/60; % in min
        frames2min = floor(2/tIntervalMin); % early period in frames

        timeFirstChangeNAs =  arrayfun(@(x) min(30,x.endingFrameExtra-x.startingFrameExtra),tracksNA); 
        timeLastChangeNAs =  arrayfun(@(x) min(frames2min, (x.endingFrameExtra-x.startingFrameExtra)),tracksNA); 
        timeFirstChangeSec = timeFirstChangeNAs*timeInterval;
        timeLastChangeSec = timeLastChangeNAs*timeInterval;
        edgeAdvanceDistFirstChangeNAs = edgeAdvanceDistFirstChangeNAs./timeFirstChangeSec*pixSize;
        edgeAdvanceDistLastChangeNAs = edgeAdvanceDistLastChangeNAs./timeLastChangeSec*pixSize;
        distToEdgeFirstNAs = distToEdgeFirstNAs*pixSize;
        distToEdgeChangeNAs= distToEdgeChangeNAs*pixSize;
        distToEdgeLastNAs= distToEdgeLastNAs*pixSize;
        maxEdgeAdvanceDistChangeNAs= maxEdgeAdvanceDistChangeNAs*pixSize;
        maxIntensityNAs=maxIntensityNAs/maxIntensity; % This should be higher in g2 than g1
        if ~useOldSet
            edgeVariation= edgeVariation*pixSize;
            timeToMaxInten = timeToMaxInten*timeInterval;
        end    
        lifeTimeNAs = lifeTimeSec;
    case 5 % normalizationMethods=4 means normalization with maxIntensity and maxEdgeAdvance*pixSize and lifeTime in sec 
        % (using tInterval) then normalization again with maximum only for
        % intensity
        decayingIntensityNAs = decayingIntensityNAs/maxIntensity;      %#1
        meanIntensityNAs = meanIntensityNAs/maxIntensity;                %#5
        startingIntensityNAs = startingIntensityNAs/maxIntensity;           %#7
        lifeTimeSec = lifeTimeNAs*timeInterval;
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3

        tIntervalMin = timeInterval/60; % in min
        frames2min = floor(2/tIntervalMin); % early period in frames
        timeFirstChangeNAs =  arrayfun(@(x) min(30,x.endingFrameExtra-x.startingFrameExtra),tracksNA); 
        timeLastChangeNAs =  arrayfun(@(x) min(frames2min, (x.endingFrameExtra-x.startingFrameExtra)),tracksNA); 
        timeFirstChangeSec = timeFirstChangeNAs*timeInterval;
        timeLastChangeSec = timeLastChangeNAs*timeInterval;
        edgeAdvanceDistFirstChangeNAs = edgeAdvanceDistFirstChangeNAs./timeFirstChangeSec*pixSize;
        edgeAdvanceDistLastChangeNAs = edgeAdvanceDistLastChangeNAs./timeLastChangeSec*pixSize;
        distToEdgeFirstNAs = distToEdgeFirstNAs*pixSize;
        distToEdgeChangeNAs= distToEdgeChangeNAs*pixSize;
        distToEdgeLastNAs= distToEdgeLastNAs*pixSize;
        maxEdgeAdvanceDistChangeNAs= maxEdgeAdvanceDistChangeNAs*pixSize;
        lifeTimeNAs = lifeTimeSec;
        
        % normalization with maximum AND MINIMA
        decayingIntensityNAs = (decayingIntensityNAs-min(decayingIntensityNAs))/(max(decayingIntensityNAs)-min(decayingIntensityNAs));
        edgeAdvanceSpeedNAs = edgeAdvanceSpeedNAs/maxEdgeAdvance;
        advanceSpeedNAs = advanceSpeedNAs/maxEdgeAdvance;
        lifeTimeNAs = lifeTimeNAs/max(lifeTimeNAs);
        meanIntensityNAs = (meanIntensityNAs-min(meanIntensityNAs))/(max(meanIntensityNAs)-min(meanIntensityNAs));
        distToEdgeFirstNAs = distToEdgeFirstNAs/maxEdgeAdvance;
        startingIntensityNAs = (startingIntensityNAs-min(startingIntensityNAs))/(max(startingIntensityNAs)-min(startingIntensityNAs));
        distToEdgeChangeNAs = distToEdgeChangeNAs/maxEdgeAdvance;
        distToEdgeLastNAs = distToEdgeLastNAs/maxEdgeAdvance;
        edgeAdvanceDistFirstChangeNAs = edgeAdvanceDistFirstChangeNAs/maxEdgeAdvance;
        edgeAdvanceDistLastChangeNAs =  edgeAdvanceDistLastChangeNAs/maxEdgeAdvance;
        maxEdgeAdvanceDistChangeNAs = maxEdgeAdvanceDistChangeNAs/maxEdgeAdvance;
        
        maxIntensityNAs=maxIntensityNAs/maxIntensity; % This should be higher in g2 than g1
        if ~useOldSet
            edgeVariation= edgeVariation/max(edgeVariation);
            timeToMaxInten = timeToMaxInten*timeInterval;
        end
    case 6 % normalizationMethods=4 means normalization with maxIntensity and maxEdgeAdvance*pixSize and lifeTime in sec 
        % (using tInterval) then normalization again with maximum
        decayingIntensityNAs = decayingIntensityNAs/maxIntensity;      %#1
        meanIntensityNAs = meanIntensityNAs/maxIntensity;                %#5
        startingIntensityNAs = startingIntensityNAs/maxIntensity;           %#7
        lifeTimeSec = lifeTimeNAs*timeInterval;
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeSec*pixSize; %this should be also low for group 3

        tIntervalMin = timeInterval/60; % in min
        frames2min = floor(2/tIntervalMin); % early period in frames
        timeFirstChangeNAs =  arrayfun(@(x) min(30,x.endingFrameExtra-x.startingFrameExtra),tracksNA); 
        timeLastChangeNAs =  arrayfun(@(x) min(frames2min, (x.endingFrameExtra-x.startingFrameExtra)),tracksNA); 
        timeFirstChangeSec = timeFirstChangeNAs*timeInterval;
        timeLastChangeSec = timeLastChangeNAs*timeInterval;
        edgeAdvanceDistFirstChangeNAs = edgeAdvanceDistFirstChangeNAs./timeFirstChangeSec*pixSize;
        edgeAdvanceDistLastChangeNAs = edgeAdvanceDistLastChangeNAs./timeLastChangeSec*pixSize;
        distToEdgeFirstNAs = distToEdgeFirstNAs*pixSize;
        distToEdgeChangeNAs= distToEdgeChangeNAs*pixSize;
        distToEdgeLastNAs= distToEdgeLastNAs*pixSize;
        maxEdgeAdvanceDistChangeNAs= maxEdgeAdvanceDistChangeNAs*pixSize;
        lifeTimeNAs = lifeTimeSec;
        
        % normalization with maximum AND MINIMA
        decayingIntensityNAs = (decayingIntensityNAs-min(decayingIntensityNAs))/(max(decayingIntensityNAs)-min(decayingIntensityNAs));
        edgeAdvanceSpeedNAs = (edgeAdvanceSpeedNAs-min(edgeAdvanceSpeedNAs))/max(minVal,(max(edgeAdvanceSpeedNAs)-min(edgeAdvanceSpeedNAs)));
        advanceSpeedNAs = (advanceSpeedNAs-min(advanceSpeedNAs))/max(minVal,(max(advanceSpeedNAs)-min(advanceSpeedNAs)));
        lifeTimeNAs = (lifeTimeNAs-min(lifeTimeNAs))/max(minVal,(max(lifeTimeNAs)-min(lifeTimeNAs)));
        meanIntensityNAs = (meanIntensityNAs-min(meanIntensityNAs))/(max(meanIntensityNAs)-min(meanIntensityNAs));
        distToEdgeFirstNAs = (distToEdgeFirstNAs-min(distToEdgeFirstNAs))/max(minVal,(max(distToEdgeFirstNAs)-min(distToEdgeFirstNAs)));
        startingIntensityNAs = (startingIntensityNAs-min(startingIntensityNAs))/(max(startingIntensityNAs)-min(startingIntensityNAs));
        distToEdgeChangeNAs = (distToEdgeChangeNAs-min(distToEdgeChangeNAs))/max(minVal,(max(distToEdgeChangeNAs)-min(distToEdgeChangeNAs)));
        distToEdgeLastNAs = (distToEdgeLastNAs-min(distToEdgeLastNAs))/max(minVal,(max(distToEdgeLastNAs)-min(distToEdgeLastNAs)));
        edgeAdvanceDistFirstChangeNAs = (edgeAdvanceDistFirstChangeNAs-min(edgeAdvanceDistFirstChangeNAs))/max(minVal,(max(edgeAdvanceDistFirstChangeNAs)-min(edgeAdvanceDistFirstChangeNAs)));
        edgeAdvanceDistLastChangeNAs =  (edgeAdvanceDistLastChangeNAs-min(edgeAdvanceDistLastChangeNAs))/max(minVal,(max(edgeAdvanceDistLastChangeNAs)-min(edgeAdvanceDistLastChangeNAs)));
        maxEdgeAdvanceDistChangeNAs = (maxEdgeAdvanceDistChangeNAs-max(maxEdgeAdvanceDistChangeNAs))/max(minVal,(max(maxEdgeAdvanceDistChangeNAs)-max(maxEdgeAdvanceDistChangeNAs)));
        maxIntensityNAs = (maxIntensityNAs-min(maxIntensityNAs))/max(minVal,(max(maxIntensityNAs)-min(maxIntensityNAs)));
        if ~useOldSet
            edgeVariation = (edgeVariation-min(edgeVariation))/max(minVal,(max(edgeVariation)-min(edgeVariation)));
            timeToMaxInten = (timeToMaxInten-min(timeToMaxInten))/max(minVal,(max(timeToMaxInten)-min(timeToMaxInten)));
        end
    case 7 % normalizationMethods=5 means normalization per each feature min and max
        decayingIntensityNAs = decayingIntensityNAs/max(decayingIntensityNAs);
        edgeAdvanceDistNAs = edgeAdvanceDistNAs/max(edgeAdvanceDistNAs);
        advanceDistNAs = advanceDistNAs/max(advanceDistNAs);
        edgeAdvanceSpeedNAs = edgeAdvanceDistNAs./lifeTimeNAs; %this should be also low for group 3
        advanceSpeedNAs = advanceDistNAs./lifeTimeNAs; %this should be also low for group 3
        lifeTimeNAs = lifeTimeNAs/max(lifeTimeNAs);
        meanIntensityNAs = meanIntensityNAs/max(meanIntensityNAs);
        distToEdgeFirstNAs = distToEdgeFirstNAs/max(distToEdgeFirstNAs);
        startingIntensityNAs = startingIntensityNAs/max(startingIntensityNAs);
        distToEdgeChangeNAs = distToEdgeChangeNAs/max(distToEdgeChangeNAs);
        distToEdgeLastNAs = distToEdgeLastNAs/max(distToEdgeLastNAs);
        edgeAdvanceDistFirstChangeNAs = edgeAdvanceDistFirstChangeNAs/max(edgeAdvanceDistFirstChangeNAs);
        edgeAdvanceDistLastChangeNAs =  edgeAdvanceDistLastChangeNAs/max(edgeAdvanceDistLastChangeNAs);
        maxEdgeAdvanceDistChangeNAs = maxEdgeAdvanceDistChangeNAs/max(maxEdgeAdvanceDistChangeNAs);
        maxIntensityNAs = (maxIntensityNAs-min(maxIntensityNAs))/max(minVal,(max(maxIntensityNAs)));
        if ~useOldSet
            edgeVariation = (edgeVariation-min(edgeVariation))/max(minVal,(max(edgeVariation)));
            timeToMaxInten = (timeToMaxInten-min(timeToMaxInten))/max(minVal,(max(timeToMaxInten)));
        end
end
%% Building classifier...
if nargin>1 && ~isempty(idGroupSelected)
    nGroups = numel(idGroupSelected);
    meas = [];
    nTotalG = 0;
    nG = zeros(nGroups,1);
    for ii=1:nGroups
%         if numel(idGroupSelected{ii})>=5
            meas = [meas; decayingIntensityNAs(idGroupSelected{ii}) edgeAdvanceSpeedNAs(idGroupSelected{ii}) advanceSpeedNAs(idGroupSelected{ii}) ...
                 lifeTimeNAs(idGroupSelected{ii}) meanIntensityNAs(idGroupSelected{ii}) distToEdgeFirstNAs(idGroupSelected{ii}) ...
                 startingIntensityNAs(idGroupSelected{ii}) distToEdgeChangeNAs(idGroupSelected{ii}) distToEdgeLastNAs(idGroupSelected{ii}) ...
                 edgeAdvanceDistFirstChangeNAs(idGroupSelected{ii}) edgeAdvanceDistLastChangeNAs(idGroupSelected{ii}) ...
                 maxEdgeAdvanceDistChangeNAs(idGroupSelected{ii}) maxIntensityNAs(idGroupSelected{ii}) ...
                 timeToMaxInten(idGroupSelected{ii}) edgeVariation(idGroupSelected{ii})];
            if length(idGroupSelected{1})==length(idGroupSelected{2}) || isempty(idGroupSelected{ii}) || numel(idGroupSelected{ii})==1
                nCurG=sum(idGroupSelected{ii}>0); %
            else
                nCurG=length(idGroupSelected{ii}); %sum(idGroupSelected{ii}); %
            end
            nG(ii)=nCurG;
            nTotalG = nTotalG+nCurG;
%         else
%             disp(['The quantity of the labels for group ' num2str(ii) ' is less than 5. Skipping this group for training...'])
%             nG(ii)=0;
%         end
    end
    % meas = [decayingIntensityNAs(idGroup1Selected) edgeAdvanceSpeedNAs(idGroup1Selected) advanceSpeedNAs(idGroup1Selected) ...
    %      lifeTimeNAs(idGroup1Selected) meanIntensityNAs(idGroup1Selected) distToEdgeFirstNAs(idGroup1Selected) ...
    %      startingIntensityNAs(idGroup1Selected) distToEdgeChangeNAs(idGroup1Selected) distToEdgeLastNAs(idGroup1Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup1Selected) maxEdgeAdvanceDistChangeNAs(idGroup1Selected);
    %      decayingIntensityNAs(idGroup2Selected) edgeAdvanceSpeedNAs(idGroup2Selected) advanceSpeedNAs(idGroup2Selected) ...
    %      lifeTimeNAs(idGroup2Selected) meanIntensityNAs(idGroup2Selected) distToEdgeFirstNAs(idGroup2Selected) ...
    %      startingIntensityNAs(idGroup2Selected) distToEdgeChangeNAs(idGroup2Selected) distToEdgeLastNAs(idGroup2Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup2Selected) maxEdgeAdvanceDistChangeNAs(idGroup2Selected);
    %      decayingIntensityNAs(idGroup3Selected) edgeAdvanceSpeedNAs(idGroup3Selected) advanceSpeedNAs(idGroup3Selected) ...
    %      lifeTimeNAs(idGroup3Selected) meanIntensityNAs(idGroup3Selected) distToEdgeFirstNAs(idGroup3Selected) ...
    %      startingIntensityNAs(idGroup3Selected) distToEdgeChangeNAs(idGroup3Selected) distToEdgeLastNAs(idGroup3Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup3Selected) maxEdgeAdvanceDistChangeNAs(idGroup3Selected);
    %      decayingIntensityNAs(idGroup4Selected) edgeAdvanceSpeedNAs(idGroup4Selected) advanceSpeedNAs(idGroup4Selected) ...
    %      lifeTimeNAs(idGroup4Selected) meanIntensityNAs(idGroup4Selected) distToEdgeFirstNAs(idGroup4Selected) ...
    %      startingIntensityNAs(idGroup4Selected) distToEdgeChangeNAs(idGroup4Selected) distToEdgeLastNAs(idGroup4Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup4Selected) maxEdgeAdvanceDistChangeNAs(idGroup4Selected);
    %      decayingIntensityNAs(idGroup5Selected) edgeAdvanceSpeedNAs(idGroup5Selected) advanceSpeedNAs(idGroup5Selected) ...
    %      lifeTimeNAs(idGroup5Selected) meanIntensityNAs(idGroup5Selected) distToEdgeFirstNAs(idGroup5Selected) ...
    %      startingIntensityNAs(idGroup5Selected) distToEdgeChangeNAs(idGroup5Selected) distToEdgeLastNAs(idGroup5Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup5Selected) maxEdgeAdvanceDistChangeNAs(idGroup5Selected);
    %      decayingIntensityNAs(idGroup6Selected) edgeAdvanceSpeedNAs(idGroup6Selected) advanceSpeedNAs(idGroup6Selected) ...
    %      lifeTimeNAs(idGroup6Selected) meanIntensityNAs(idGroup6Selected) distToEdgeFirstNAs(idGroup6Selected) ...
    %      startingIntensityNAs(idGroup6Selected) distToEdgeChangeNAs(idGroup6Selected) distToEdgeLastNAs(idGroup6Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup6Selected) maxEdgeAdvanceDistChangeNAs(idGroup6Selected);
    %      decayingIntensityNAs(idGroup7Selected) edgeAdvanceSpeedNAs(idGroup7Selected) advanceSpeedNAs(idGroup7Selected) ...
    %      lifeTimeNAs(idGroup7Selected) meanIntensityNAs(idGroup7Selected) distToEdgeFirstNAs(idGroup7Selected) ...
    %      startingIntensityNAs(idGroup7Selected) distToEdgeChangeNAs(idGroup7Selected) distToEdgeLastNAs(idGroup7Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup7Selected) maxEdgeAdvanceDistChangeNAs(idGroup7Selected);
    %      decayingIntensityNAs(idGroup8Selected) edgeAdvanceSpeedNAs(idGroup8Selected) advanceSpeedNAs(idGroup8Selected) ...
    %      lifeTimeNAs(idGroup8Selected) meanIntensityNAs(idGroup8Selected) distToEdgeFirstNAs(idGroup8Selected) ...
    %      startingIntensityNAs(idGroup8Selected) distToEdgeChangeNAs(idGroup8Selected) distToEdgeLastNAs(idGroup8Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup8Selected) maxEdgeAdvanceDistChangeNAs(idGroup8Selected);
    %      decayingIntensityNAs(idGroup9Selected) edgeAdvanceSpeedNAs(idGroup9Selected) advanceSpeedNAs(idGroup9Selected) ...
    %      lifeTimeNAs(idGroup9Selected) meanIntensityNAs(idGroup9Selected) distToEdgeFirstNAs(idGroup9Selected) ...
    %      startingIntensityNAs(idGroup9Selected) distToEdgeChangeNAs(idGroup9Selected) distToEdgeLastNAs(idGroup9Selected) ...
    %      edgeAdvanceDistLastChangeNAs(idGroup9Selected) maxEdgeAdvanceDistChangeNAs(idGroup9Selected)];
    % meas = [advanceDistNAs(idGroup4Selected) edgeAdvanceDistNAs(idGroup4Selected);
    %     advanceDistNAs(nonGroup24Selected) edgeAdvanceDistNAs(nonGroup24Selected)];
    species = cell(nTotalG,1);
    for ii=1:nTotalG
        if ii<=nG(1)
            species{ii} = 'Group1';
        elseif ii<=sum(nG(1:2))
            species{ii} = 'Group2';
        elseif ii<=sum(nG(1:3))
            species{ii} = 'Group3';
        elseif ii<=sum(nG(1:4))
            species{ii} = 'Group4';
        elseif ii<=sum(nG(1:5))
            species{ii} = 'Group5';
        elseif ii<=sum(nG(1:6))
            species{ii} = 'Group6';
        elseif ii<=sum(nG(1:7))
            species{ii} = 'Group7';
        elseif ii<=sum(nG(1:8))
            species{ii} = 'Group8';
        elseif ii<=nTotalG
            species{ii} = 'Group9';
        end
    end
    dataTable = table(meas(:,1),meas(:,2),meas(:,3),meas(:,4),meas(:,5),meas(:,6),meas(:,7),meas(:,8),meas(:,9),meas(:,10),meas(:,11),meas(:,12),...
        meas(:,13),meas(:,14),meas(:,15),species,...
        'VariableNames',{'decayingIntensityNAs', 'edgeAdvanceSpeedNAs', 'advanceSpeedNAs', ...
        'lifeTimeNAs', 'meanIntensityNAs', 'distToEdgeFirstNAs', ...
        'startingIntensityNAs', 'distToEdgeChangeNAs', 'distToEdgeLastNAs', 'edgeAdvanceDistFirstChangeNAs',...
        'edgeAdvanceDistLastChangeNAs','maxEdgeAdvanceDistChangeNAs',...
        'maxIntensityNAs', 'timeToMaxInten', 'edgeVariation', 'Group'});
else
    dataTable = [];
    meas=[];
end

if ~useOldSet
    allData = [decayingIntensityNAs edgeAdvanceSpeedNAs advanceSpeedNAs ...
         lifeTimeNAs meanIntensityNAs distToEdgeFirstNAs ...
         startingIntensityNAs distToEdgeChangeNAs distToEdgeLastNAs ...
        edgeAdvanceDistFirstChangeNAs edgeAdvanceDistLastChangeNAs maxEdgeAdvanceDistChangeNAs ...
         maxIntensityNAs timeToMaxInten edgeVariation];
else
    allData = [decayingIntensityNAs edgeAdvanceSpeedNAs advanceSpeedNAs ...
         lifeTimeNAs meanIntensityNAs distToEdgeFirstNAs ...
         startingIntensityNAs distToEdgeChangeNAs distToEdgeLastNAs ...
         edgeAdvanceDistLastChangeNAs maxEdgeAdvanceDistChangeNAs ...
         ];
end

    