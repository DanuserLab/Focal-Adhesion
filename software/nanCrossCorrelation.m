function [xCorr,bounds,lags,pVal] = nanCrossCorrelation(x,y,varargin)
% This function calculates 3 measures of correlation between two vectors x and y.
% Measures: Pearson, Kendall and Spearman cross-correlation
%
%Usage:
%       [xCorr,bounds,lags,pVal] = nanCrossCorrelation(x,y,varargin)
%
%Inputs:
%       x and y  - vectors of the same size
%       corrType - correlation type: 'Pearson', 'Kendall' or 'Spearman'
%       maxLag   - number of lag shifts
%       local    - only used for Kendall type. Under development
%       robust   - logical. Only used for the Pearson type. If true, uses robust regression and estimation of variance to calculate the
%                  coefficient. Default is false.
%
%Output:
%       xCorr  - correlation coefficients
%       bounds - Two-element vector indicating the approximate upper and lower
%                confidence bounds, assuming the input series are uncorrelated.
%       lags   -
%       pVal   - pValue for each coefficient
%
%
%
%Marco Vilela, 2012
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

ip = inputParser;
ip.addRequired('x',@isvector);
ip.addRequired('y',@isvector);
ip.addParamValue('corrType','Pearson', @ischar)
ip.addParamValue('maxLag',0,@isscalar);
ip.addParamValue('local',numel(x)-1,@isscalar);
ip.addParamValue('robust',false,@islogical);

ip.parse(x,y,varargin{:});
local    = ip.Results.local;
maxLag   = ip.Results.maxLag;
corrT    = ip.Results.corrType;
robustOn = ip.Results.robust;

x = x(:);
y = y(:);

lags = -maxLag:maxLag;
nObsX = length(x);
nObsY = length(y);

if nObsY ~= nObsX
    error('X and Y have different number of observations');
else
    nObs = nObsY;
end

numSTD = 2;



pVal = [];
switch corrT
    
    case 'Pearson'
        bounds          = [numSTD;-numSTD]/sqrt(nObs);
        
        if robustOn
            %NaN and outliers have no influence. Well, not too much.
            SX = flipud(buffer(x,nObs,nObs - 1));%delay x(t-n)
            SY = flipud(buffer(y,nObs,nObs - 1));%delay y(t-n)
            
            SX(maxLag+2:end,:) = [];
            SY(maxLag+2:end,:) = [];
            SX = SX + tril(nan(size(SX)));
            SY = SY + tril(nan(size(SY)));
            Y  = repmat(y,1,maxLag+1)+ tril(nan(size(SY)))';
            X  = repmat(x,1,maxLag+1)+ tril(nan(size(SX)))';
            
            lagX = num2cell(SX',1);
            lagY = num2cell(SY',1);
            Y    = num2cell(Y,1);
            X    = num2cell(X,1);
            
            posLag = cell2mat(cellfun(@(x,y) robustfit(x,y,'bisquare'),lagX,Y,'Unif',0));
            negLag = cell2mat(cellfun(@(x,y) robustfit(x,y,'bisquare'),X,lagY,'Unif',0));
            posLag(1,:) = [];
            negLag(1,:) = [];
            
            normalizationR = cell2mat(cellfun(@(x,y) nanstd(x)/nanstd(y),lagX,Y,'Unif',0));
            normalizationL = cell2mat(cellfun(@(x,y) nanstd(x)/nanstd(y),X,lagY,'Unif',0));
            
            CCL   = normalizationR.*posLag;
            CCR   = normalizationL.*negLag;
            
        else
            %NaN have no influence
            nObs            = min(sum(isfinite(x)),sum(isfinite(y)));
            normalization   = ( (nObs - 1)*nanstd(x)*nanstd(y) )^-1;
            
            x = x - nanmean(x);
            y = y - nanmean(y);
            
            x(isnan(x)) = 0;
            y(isnan(y)) = 0;
                        
            
            SX = flipud(buffer(x,nObs,nObs - 1));%delay x(t-n)
            SY = flipud(buffer(y,nObs,nObs - 1));%delay y(t-n)
            
            SX(maxLag+2:end,:) = [];
            SY(maxLag+2:end,:) = [];
            
            CCR   = normalization*x'*SY';
            CCL   = normalization*y'*SX';
            xCorr = [fliplr(CCR) CCL(2:end)];
            pVal  = pvalPearson('b',xCorr,nObs);
            
        end
        
        
        xCorr = [fliplr(CCR) CCL(2:end)];
        %xCorr = crosscorr(x,y,maxLag);
        pVal  = pvalPearson('b',xCorr,nObs);
    case 'Kendall'
        
        [xCorr(:,1)] = modifiedKendallCorr(x,y,'local',local,'maxLag',maxLag);
        
    case 'Spearman'
        
end
xCorr = xCorr(:);

end %ENd of main function

function p = pvalPearson(tail, xCorr, nObs)
%
t = xCorr.*sqrt((nObs-2)./(1-xCorr.^2)); %
switch tail
    case 'b'
        
        p = 2*tcdf(-abs(t),nObs-2);
        
    case 'r'
        
        p = tcdf(-t,nObs-2);
        
    case 'l'
        
        p = tcdf(t,nObs-2);
        
end

end