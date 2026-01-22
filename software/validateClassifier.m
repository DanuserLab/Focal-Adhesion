function  [validationAccuracy,C,order] = validateClassifier(trainedClassifier,datasetTable)
% Extract predictors and response
%
% Copyright (C) 2026, Danuser Lab - UTSouthwestern 
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
predictorNames = {'decayingIntensityNAs', 'edgeAdvanceSpeedNAs', 'advanceSpeedNAs', 'lifeTimeNAs', 'meanIntensityNAs', 'distToEdgeFirstNAs',...
    'startingIntensityNAs', 'distToEdgeChangeNAs', 'distToEdgeLastNAs', 'edgeAdvanceDistFirstChangeNAs', 'edgeAdvanceDistLastChangeNAs', 'maxEdgeAdvanceDistChangeNAs',...
    'maxIntensityNAs', 'timeToMaxInten', 'edgeVariation'};
predictors = datasetTable(:,predictorNames);
predictors = table2array(varfun(@double, predictors));
response = datasetTable.Group;
% Perform cross-validation
% figure; imagesc(predictors);
% predictedLabels = predict(trainedClassifier,predictors);
% [predictedLabels,NegLoss,PBScore] = trainedClassifier.predict(predictors);
predictedLabels = trainedClassifier.predict(predictors);
% if the number of response is different (e.g. no Group6), merge into
% Group9.
results = nan(1,numel(predictedLabels));
for i = 1 : numel(predictedLabels)
    results(i) = strcmp(predictedLabels{i},response{i});
end
validationAccuracy=sum(results)/length(results);
% confusion matrix
ascendingOrder = unique(sort([response; predictedLabels]));
[C,order] = confusionmat(response,predictedLabels,'order',ascendingOrder);
end