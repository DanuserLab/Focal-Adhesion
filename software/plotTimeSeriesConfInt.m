function plotTimeSeriesConfInt(xSeries,curArray, varargin)
ip = inputParser;
ip.addParamValue('Color',[0.5 0.5 0.5],@isnumeric);
% ip.addParamValue('YLim',[],@isnumeric || @isempty);
% ip.addParamValue('tInterval',1,@isnumeric);
%
% Copyright (C) 2024, Danuser Lab - UTSouthwestern 
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

ip.parse(varargin{:});

colorUsed = ip.Results.Color;
% YLim = ip.Results.YLim;
% tInterval = ip.Results.tInterval;

ciColor = colorUsed*1.5;%[153/255 255/255 51/255];
% Saturate
for ii=1:3
    if ciColor(ii)>1
        ciColor(ii)=1;
    end
end
meanColor = colorUsed*0.5;%[0/255 102/255 0];
curLT =length(xSeries);
tInterval = xSeries(2)-xSeries(1);
normalizedXseries=xSeries/tInterval;

curMeanSig = nanmean(curArray,1);
curSEM = nanstd(curArray,1)/sqrt(size(curArray,1));
curTScore = tinv([0.025 0.975],size(curArray,1)-1);
curCI_upper = curMeanSig + curTScore*curSEM;
curCI_lower = curMeanSig - curTScore*curSEM;
fill([normalizedXseries(1):normalizedXseries(end) normalizedXseries(end):-1:normalizedXseries(1)]*tInterval,[curCI_upper fliplr(curCI_lower)],ciColor,'EdgeColor',ciColor),hold on
plot((normalizedXseries(1):normalizedXseries(end))*tInterval,curMeanSig,'Linewidth',2,'Color',meanColor)





