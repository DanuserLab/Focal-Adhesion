function [] = readTractionForceFromTracks(MD,varargin)
% readTractionForceFromTracks runs colocalization between peaks in TFM maps and peaks in paxillin using MD.
% Basically this function make grayscale of TFM and pick up peaks of the
% map and see if how many of them are colocalized with significant paxillin
% signal or neighborhood of nascent adhesions.
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

% input:    pathForTheMovieDataFile:    path to the MD file (TFM
% package should be run beforehand)
%           outputPath              outputPath
%           band:                       band width for cutting border
%           (default=4)
%           pointTF:                   true if you want to trace force at
%           a certain point (default = false)
% output:   images of heatmap stored in pathForTheMovieDataFile/heatmap
%           forceNAdetec,          force at detectable NAs
%           forceNAund,             force at undetectable NAs
%           forceFA,                     force magnitude at FA
%           peaknessRatio,      portion of forces that are themselves local maxima
%           DTMS                        Deviation of Traction Magnitude from Surrounding
% Note: detectable NAs are defined by coincidence of NA position with bead
% location and force node
% Sangyoon Han April 2013

%% Input
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('MD', @(x) isa(x,'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(MD,varargin{:});
paramsIn=ip.Results.paramsIn;
%Parse input, store in parameter structure
%Get the indices of any previous threshold processes from this function                                                                              
iProc = MD.getProcessIndex('TractionForceReadingProcess',1,0);
%If the process doesn't exist, create it
if isempty(iProc)
    iProc = numel(MD.processes_)+1;
    MD.addProcess(TractionForceReadingProcess(MD));                                                                                                 
end
tractionForceReadProc = MD.processes_{iProc};
p = parseProcessParams(tractionForceReadProc,paramsIn);

% ip.addParamValue('chanIntensity',@isnumeric); % channel to quantify intensity (2 or 3)
% ip.parse(MD,showAllTracks,plotEachTrack,varargin{:});
% iChanMaster=p.ChannelIndex;

%% Reading tracks from master channel
% Use the previous analysis folder structure
% It might be good to save which process the tracksNA was obtained.
disp('Reading tracksNA ...')
tic
try
    iAdhProc = MD.getProcessIndex('TheOtherChannelReadingProcess');
    adhAnalProc = MD.getProcess(iAdhProc);
    % numChans = numel(p.ChannelIndex);
    tracksNA = load(adhAnalProc.outFilePaths_{1,p.ChannelIndex},'tracksNA');
    tracksNA = tracksNA.tracksNA;
catch
    try
        iAdhProc = MD.getProcessIndex('AdhesionClassificationProcess');
        adhAnalProc = MD.getProcess(iAdhProc);
        % numChans = numel(p.ChannelIndex);
        tracksNA = load(adhAnalProc.outFilePaths_{5,p.ChannelIndex},'tracksNA');
        tracksNA = tracksNA.tracksNA;
    catch
        iAdhProc = MD.getProcessIndex('AdhesionAnalysisProcess');
        adhAnalProc = MD.getProcess(iAdhProc);
        % numChans = numel(p.ChannelIndex);
        tracksNA = load(adhAnalProc.outFilePaths_{1,p.ChannelIndex},'tracksNA');
        tracksNA = tracksNA.tracksNA;
    end    
end
toc
%% Data Set up
% Set up the output file path for master channel
outputFile = cell(5, numel(MD.channels_));
iBeadChan = 1; % might need to be updated based on asking TFMPackage..
for i = 1:numel(MD.channels_)
    [~, chanDirName, ~] = fileparts(MD.getChannelPaths{i});
    outFilename = [chanDirName '_Chan' num2str(i) '_tracksNA'];
    outputFile{1,i} = [p.OutputDirectory filesep outFilename '.mat'];
    outFilename = [chanDirName '_Chan' num2str(i) '_idsClassified'];
    outputFile{2,i} = [p.OutputDirectory filesep outFilename '.mat'];
    outFilename = [chanDirName '_Chan' num2str(i) '_tractionMap'];
    outputFile{3,i} = [p.OutputDirectory filesep outFilename '.mat'];
    outFilename = [chanDirName '_Chan' num2str(i) '_forceField'];
    outputFile{4,i} = [p.OutputDirectory filesep outFilename '.mat'];
    outFilename = [chanDirName '_Chan' num2str(i) '_forceFieldShifted'];
    outputFile{5,i} = [p.OutputDirectory filesep outFilename '.mat'];
end
tractionForceReadProc.setOutFilePaths(outputFile);
mkClrDir(p.OutputDirectory);
%% tracion map stack
% Build the interpolated TFM matrix first and then go through each track
% First build overall TFM images
% We don't need to build traction map again if this one is already built
% during force field calculation process.
% Load the forcefield
try 
    TFMPackage = MD.getPackage(MD.getPackageIndex('TFMPackage'));
    forceFieldProc = MD.findProcessTag('ForceFieldCalculationProcess');
%     iForceFieldProc = TFMPackage.getProcessIndex(forceFieldProc)
%     forceFieldProc = TFMPackage.processes_{iForceFieldProc};
    forceFieldStruct = load(forceFieldProc.outFilePaths_{1});
    forceField = forceFieldStruct.forceField;
    forceFieldShifted = forceFieldStruct.forceFieldShifted;
catch noTFM
    disp('===== =====================================================');
    disp('===== =====================================================');
    disp('===== No TFMPackage found for this MovieData!===========');
    disp('===== =====================================================');
    disp('===== =====================================================');
    rethrow(noTFM)
end
disp('Reading traction map...')
tic
tMapIn=forceFieldProc.loadChannelOutput('output','tMap');
%This tMap is based on the reference image, for which movie frames are
%shifted with T_TFM. Meanwhile, all tracksNA is based on SDC in FApackage
%which is based on the first frame (or the second one). Thus we need two
%things: First, we need to shift traction field back to the movie frame (-T_TFM),
%and then we have to shift it again with T_FA. In conclusion, we need to
%do: -T_TFM + T_FA per each frame.

iFAPack = MD.getPackageIndex('FocalAdhesionPackage');
FAPackage=MD.packages_{iFAPack}; iSDCProc=1;
SDCProc_FA=FAPackage.processes_{iSDCProc};
%iSDCProc =MD.getProcessIndex('StageDriftCorrectionProcess',1,1);     
if ~isempty(SDCProc_FA)
    s = load(SDCProc_FA.outFilePaths_{3,iBeadChan},'T');    
    T_FA = s.T;
end
SDCProc_TFM=TFMPackage.processes_{iSDCProc};
%iSDCProc =MD.getProcessIndex('StageDriftCorrectionProcess',1,1);     
if ~isempty(SDCProc_TFM)
    iBeadChan = 1; % might need to be updated based on asking TFMPackage..
    s = load(SDCProc_TFM.outFilePaths_{3,iBeadChan},'T');    
    T_TFM = s.T;
end
nFrames = MD.nFrames_;
[h,w] = size(tMapIn{1});
tMap = zeros(h,w,nFrames);

%% Shifting traction map and field
for ii=1:nFrames
    cur_tMap = tMapIn{ii};
    cur_T = -T_TFM(ii,:) + T_FA(ii,:);
    cur_tMap = imtranslate(cur_tMap, cur_T);
    tMap(:,:,ii) = cur_tMap;
    forceField(ii).pos(:,1) = forceField(ii).pos(:,1)+cur_T(2);
    forceField(ii).pos(:,2) = forceField(ii).pos(:,2)+cur_T(1);
    forceFieldShifted(ii).pos(:,1) = forceFieldShifted(ii).pos(:,1)+cur_T(2);
    forceFieldShifted(ii).pos(:,2) = forceFieldShifted(ii).pos(:,2)+cur_T(1);
end
%% Filter out tracks that is out of traction field
cropInfo = [ceil(min(forceField(1).pos(:,1))),ceil(min(forceField(1).pos(:,2))),floor(max(forceField(1).pos(:,1))),floor(max(forceField(1).pos(:,2)))];
idxTracks = true(numel(tracksNA),1);
disp('Filtering with TFM boundary...')
for ii=1:numel(tracksNA)
    if any(round(tracksNA(ii).xCoord)<=cropInfo(1) | round(tracksNA(ii).xCoord)>=cropInfo(3) ...
            | round(tracksNA(ii).yCoord)<=cropInfo(2) | round(tracksNA(ii).yCoord)>=cropInfo(4))
        idxTracks(ii) = false;
    end
end
tracksNA=tracksNA(idxTracks);
%% Filter out idsClassified
% Since we are resizing tracksNA, we have to apply this to idsClassified
% too
iClaProc = MD.getProcessIndex('AdhesionClassificationProcess');
classProc = MD.getProcess(iClaProc);
% numChans = numel(p.ChannelIndex);
idsClassified = load(classProc.outFilePaths_{4,p.ChannelIndex});
idGroup1 = idsClassified.idGroup1(idxTracks);
idGroup2 = idsClassified.idGroup2(idxTracks);
idGroup3 = idsClassified.idGroup3(idxTracks);
idGroup4 = idsClassified.idGroup4(idxTracks);
idGroup5 = idsClassified.idGroup5(idxTracks);
idGroup6 = idsClassified.idGroup6(idxTracks);
idGroup7 = idsClassified.idGroup7(idxTracks);
idGroup8 = idsClassified.idGroup8(idxTracks);
idGroup9 = idsClassified.idGroup9(idxTracks);
%% Read force from tMap
% get the intensity
disp('Reading traction...')

tracksNA = readIntensityFromTracks(tracksNA,tMap,2); % 2 means traction magnitude collection from traction stacks

%% Saving
disp('Saving...')
save(outputFile{1,p.ChannelIndex},'tracksNA','-v7.3'); 
save(outputFile{2,p.ChannelIndex},'idGroup1','idGroup2','idGroup3','idGroup4','idGroup5','idGroup6','idGroup7','idGroup8','idGroup9','-v7.3') 
if p.saveTractionField
    save(outputFile{3,iBeadChan},'tMap','-v7.3'); 
    save(outputFile{4,iBeadChan},'forceField','-v7.3'); 
    save(outputFile{5,iBeadChan},'forceFieldShifted','-v7.3');
end
disp('Done!')
end
%
