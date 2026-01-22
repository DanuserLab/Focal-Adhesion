function [trainedClassifier, validationAccuracy,C,order,validationPredictions, validationScores] = trainClassifierNA(datasetTable)
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
predictorNames = {'decayingIntensityNAs', 'edgeAdvanceSpeedNAs', 'advanceSpeedNAs', 'lifeTimeNAs', 'meanIntensityNAs', 'distToEdgeFirstNAs', 'startingIntensityNAs',...
    'distToEdgeChangeNAs', 'distToEdgeLastNAs', 'edgeAdvanceDistFirstChangeNAs', 'edgeAdvanceDistLastChangeNAs', 'maxEdgeAdvanceDistChangeNAs',...
    'maxIntensityNAs', 'timeToMaxInten', 'edgeVariation'};
predictors = datasetTable(:,predictorNames);
predictors = table2array(varfun(@double, predictors));
response = datasetTable.Group;
% Get the unique resonses
[totalGroups, ~, ic] = unique(response);
% Filter out small training data group
arrayIc = unique(ic);
numEntitiesInGroup=arrayfun(@(x) sum(ic==x), arrayIc);
bigEnoughGroups=find(numEntitiesInGroup>5);
bigEnoughGroupsIcCellArray=arrayfun(@(x) (ic==x), bigEnoughGroups,'UniformOutput',false);
bigEnoughGroupsIc = bigEnoughGroupsIcCellArray{1};
for kk=2:numel(bigEnoughGroupsIcCellArray)
    bigEnoughGroupsIc = bigEnoughGroupsIc | bigEnoughGroupsIcCellArray{kk};
end
predictors = predictors(bigEnoughGroupsIc,:);
response = response(bigEnoughGroupsIc,:);
totalGroups = totalGroups(bigEnoughGroups);
% Train a classifier
template = templateSVM('KernelFunction', 'polynomial', 'PolynomialOrder', 2, 'KernelScale', 'auto', 'BoxConstraint', 1, 'Standardize', 1);
trainedClassifier = fitcecoc(predictors, response,'FitPosterior',1, 'Learners', template, 'Coding', 'onevsone', 'PredictorNames', ...
    {'decayingIntensityNAs' 'edgeAdvanceSpeedNAs' 'advanceSpeedNAs' 'lifeTimeNAs' 'meanIntensityNAs' 'distToEdgeFirstNAs' 'startingIntensityNAs' ...
    'distToEdgeChangeNAs' 'distToEdgeLastNAs' 'edgeAdvanceDistFirstChangeNAs' 'edgeAdvanceDistLastChangeNAs' 'maxEdgeAdvanceDistChangeNAs' ...
    'maxIntensityNAs' 'timeToMaxInten' 'edgeVariation'}, 'ResponseName', 'Group', 'ClassNames', totalGroups');

% Perform cross-validation
partitionedModel = crossval(trainedClassifier, 'KFold', 5);

% Compute validation accuracy
validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');

% confusion matrix
predictedLabels = trainedClassifier.predict(predictors);
[C,order] = confusionmat(response,predictedLabels);

%% Uncomment this section to compute validation predictions and scores:
% Compute validation predictions and scores
[validationPredictions, validationScores] = kfoldPredict(partitionedModel);
end
