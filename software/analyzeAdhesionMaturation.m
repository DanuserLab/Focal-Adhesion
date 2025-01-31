function analyzeAdhesionMaturation(MD)
% function [trNAonly,indFail,indMature,lifeTimeNAfailing,lifeTimeNAmaturing,maturingRatio,NADensity,FADensity,focalAdhInfo] = analyzeAdhesionMaturation(pathForTheMovieDataFile, varargin)
% [tracksNA,lifeTimeNA] = analyzeAdhesionMaturation(pathForTheMovieDataFile,outputPath,showAllTracks,plotEachTrack)
% filter out NA tracks, obtain life time of each NA tracks
% input:    pathForTheMovieDataFile:       path to the movieData file (FA
%                   segmentation and NA    tracking package should be run beforehand)
%           outputPath                      outputPath
%           'onlyEdge' [false]              collect NA tracks that ever close to cell edge
%           'matchWithFA' [true]            For cells with only NAs, we turn this off.
%           'getEdgeRelatedFeatures'[true]  For cells with only NAs, we turn this off.
%           'reTrack' [true]     This is for 
%           'minLifetime' [5]               For cells with only NAs, we turn this off.
%           'iChan' [1]                        Channel with FA marker
% output:   images will be stored in pathForTheMovieDataFile/trackFrames
%           tracksNAfailing,          tracks of failing NAs that go on to turn-over
%           tracksNAmaturing,          tracks of failing NAs that matures to FAs
%           lifeTimeNAfailing,            lifetime of all NAs that turn over 
%           lifeTimeNAmaturing,            lifetime of all maturing NAs until their final turn-over
%           maturingRatio,            ratio of maturing NAs w.r.t. all NA tracks 
%           NADensity                   density of nascent adhesions, unit: number/um2
%           FADensity                   density of focal adhesions , unit: number/um2
% status of each track
%           BA,          Before Adhesion
%           NA,          Nascent Adhesion
%           FC,            Focal Contact
%           FA,            Focal Adhesion
%           ANA,           After Nascent Adhesion
%           Out_of_Band,            Out of band from the cell edge
% Sangyoon Han April 2014
% Andrew R. Jamieson Feb. 2017 - Updating to incorporate into MovieData Process GUI (Focal Adhesion Package)
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

%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('MD', @(x)(isa(x,'MovieData')));
ip.parse(MD);
%Get the indices of any previous processes
iProc = MD.getProcessIndex('AdhesionAnalysisProcess', 'nDesired', 1, 'askUser', false);
%Check if process exists
if isempty(iProc)
    error('No AdhesionAnalysisProcess in input movieData! please create the process and use the process.run method to run this function!')
end
%Parse input, store in parameter structure
thisProc = MD.processes_{iProc};
p = parseProcessParams(thisProc);


%% --------------- Initialization ---------------%%

%% --------------- Parameters ---------- %%
matchWithFA = p.matchWithFA;
minLifetime = p.minLifetime;
onlyEdge = p.onlyEdge;
reTrack = p.reTrack;
getEdgeRelatedFeatures = p.getEdgeRelatedFeatures;
iChan = p.ChannelIndex;
bandwidthNA = p.bandwidthNA;

ApplyCellSegMask = p.ApplyCellSegMask;

% Load Respective Process objects
if ApplyCellSegMask
    maskProc = MD.getProcess(p.SegCellMaskProc);
end
detectedNAProc = MD.getProcess(p.detectedNAProc);
trackNAProc = MD.getProcess(p.trackFAProc);
FASegProc = MD.getProcess(p.FAsegProc);

%% ------------------ Config Output  ---------------- %%

% Set up the output file

%% TODO -- What is the "canonical" way to define this for multi-input situations?
% Set up the input directories (input images)
inFilePaths = cell(4,numel(MD.channels_));
for i = p.ChannelIndex
    inFilePaths{1,i} = MD.getChannelPaths(i);
    inFilePaths{2,i} = detectedNAProc.outFilePaths_{1,i};
    inFilePaths{3,i} = trackNAProc.outFilePaths_{1,i};
    inFilePaths{4,i} = FASegProc.outFilePaths_{1,i};
end
thisProc.setInFilePaths(inFilePaths);
    
% Set up the output files
outFilePaths = cell(5, numel(MD.channels_));
for i = p.ChannelIndex
    [~, chanDirName, ~] = fileparts(MD.getChannelPaths{i});
    outFilename = [chanDirName '_Chan' num2str(i) '_tracksNA'];
    outFilePaths{1,i} = [p.OutputDirectory filesep outFilename '.mat'];
    dataPath_tracksNA = outFilePaths{1,i};

    outFilename = [chanDirName '_Chan' num2str(i) '_focalAdhInfo'];
    outFilePaths{2,i} = [p.OutputDirectory filesep outFilename '.mat'];
    dataPath_focalAdhInfo = outFilePaths{2,i};

    outFilename = [chanDirName '_Chan' num2str(i) '_NAFADensity'];
    outFilePaths{3,i} = [p.OutputDirectory filesep outFilename '.mat'];
    dataPath_NAFADensity = outFilePaths{3,i};

    outFilename = [chanDirName '_Chan' num2str(i) '_allAnalysisFA'];
    outFilePaths{4,i} = [p.OutputDirectory filesep outFilename '.mat'];
    dataPath_analysisAll = outFilePaths{4,i};

    outFilename = [chanDirName '_Chan' num2str(i) '_assemRates'];
    outFilePaths{5,i} = [p.OutputDirectory filesep outFilename '.mat'];
    assembly_disassembly_ratesPath = outFilePaths{5,i};
end

thisProc.setOutFilePaths(outFilePaths);

%% Backup previous Analysis output
foundTracks=false;
if exist(p.OutputDirectory,'dir')
    if exist(outFilePaths{1,i},'file') && exist(outFilePaths{2,i},'file') && usejava('desktop')
        useExistingTracks = questdlg(...
            ['A tracksNA and focalAdhInfo outputs have been dectected. Do you' ...
            ' want to use these results and continue the analysis'],...
            'Recover previous run','Yes','No','Yes');
        if strcmpi(useExistingTracks,'Yes'), foundTracks=true; end
    end
    if p.backupOldResults && ~foundTracks
        disp('Backing up the original data')
        ii = 1;
        backupFolder = [p.OutputDirectory ' Backup ' num2str(ii)];
        while exist(backupFolder,'dir')
            backupFolder = [p.OutputDirectory ' Backup ' num2str(ii)];
            ii=ii+1;
        end
%         if strcmp(computer('arch'), 'win64')
%             mkdir(backupFolder);
%         else
%             try
%                 system(['mkdir -p ''' backupFolder '''']);
%             catch
%                 mkdir(backupFolder);
%             end            
%         end
        copyfile(p.OutputDirectory, backupFolder,'f')
        mkClrDir(p.OutputDirectory);
    end
else
    mkClrDir(p.OutputDirectory);
end
dataPath = [p.OutputDirectory filesep 'data'];
labelTifPath = [p.OutputDirectory filesep 'labelTifs'];
if ~exist(dataPath,'dir') || ~exist(labelTifPath,'dir') 
    mkdir(labelTifPath);
    mkdir(dataPath);
end

% Get whole frame number
nFrames = MD.nFrames_;
iPaxChannel = iChan;
%% TODO - Check with Sanity
iiformat = ['%.' '3' 'd'];
%% TODO - Check with Sangyoon on pixel size/minsize
% minSize = round((500/MD.pixelSize_)*(300/MD.pixelSize_)); %adhesion limit=.5um*.5um
minLifetime = min(nFrames, minLifetime);
markerSize = 2;

%% For Debugging 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
loadSaved_state = false;
if loadSaved_state
    [abpath outFilename ext] = fileparts(dataPath_tracksNA);
    load([backupFolder filesep outFilename ext]);
    [abpath outFilename ext] = fileparts(dataPath_focalAdhInfo);
    load([backupFolder filesep outFilename ext]);
    [abpath outFilename ext] = fileparts(dataPath_NAFADensity);
    load([backupFolder filesep outFilename ext]);
    [abpath outFilename ext] = fileparts(dataPath_analysisAll);
    load([backupFolder filesep outFilename ext]); 
else
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SDC Loading if there is one
iFAPack = MD.getPackageIndex('FocalAdhesionPackage');
FAPackage=MD.packages_{iFAPack}; iSDCProc=1;
SDCProc=FAPackage.processes_{iSDCProc};
%iSDCProc =MD.getProcessIndex('StageDriftCorrectionProcess',1,1);     
if ~isempty(SDCProc)
    iBeadChan = 1; % might need to be updated based on asking TFMPackage..
    s = load(SDCProc.outFilePaths_{3,iBeadChan},'T');    
    T = s.T;
end

%% tracksNA quantification
if ~foundTracks
    % tracks
    % filter out tracks that have lifetime less than 2 frames
    disp('loading NA tracks...')
    tic
    tracksNAorg = trackNAProc.loadChannelOutput(iPaxChannel);
    toc
    % if ii>minLifetime
    SEL = getTrackSEL(tracksNAorg); %SEL: StartEndLifetime
    % Remove any less than 3-frame long track.
    isValid = SEL(:,3) >= minLifetime;
    tracksNAorg = tracksNAorg(isValid);
    % end
    detectedNAs = detectedNAProc.loadChannelOutput(iPaxChannel);

    % re-express tracksNA so that each track has information for every frame
    disp('reformating NA tracks...')

    tracksNA = formatTracks(tracksNAorg, detectedNAs, nFrames); 

    bandArea = zeros(nFrames,1);
    NADensity = zeros(nFrames,1); % unit: number/um2 = numel(tracksNA)/(bandArea*MD.pixelSize^2*1e6);
    FADensity = zeros(nFrames,1); % unit: number/um2 = numel(tracksNA)/(bandArea*MD.pixelSize^2*1e6);
    nChannels = numel(MD.channels_);
    % minEcc = 0.7;

    % Filtering adhesion tracks based on cell mask. Adhesions appearing at the edge are only considered
    if onlyEdge
        disp(['Filtering adhesion tracks based on cell mask. Only adhesions appearing at the edge are considered'])
        trackIdx = false(numel(tracksNA),1);
        bandwidthNA_pix = round(bandwidthNA*1000/MD.pixelSize_);
        for ii=1:nFrames
            % Cell Boundary Mask 
            if ApplyCellSegMask
                mask = maskProc.loadChannelOutput(iChan,ii);
            else
                mask = true(MD.imSize_);
            end
            % mask for band from edge
            iMask = imcomplement(mask);
            distFromEdge = bwdist(iMask);
            bandMask = distFromEdge <= bandwidthNA_pix;

            maskOnlyBand = bandMask & mask;
            bandArea(ii) = sum(maskOnlyBand(:)); % in pixel

            % collect index of tracks which first appear at frame ii
            idxFirstAppear = arrayfun(@(x) x.startingFrame==ii,tracksNA);
            % now see if these tracks ever in the maskOnlyBand
            for k=find(idxFirstAppear)'
                if maskOnlyBand(round(tracksNA(k).yCoord(ii)),round(tracksNA(k).xCoord(ii)))
                    trackIdx(k) = true;
                end
            end
        end    
    else
        disp('Entire adhesion tracks are considered.')
        trackIdx = true(numel(tracksNA),1);
        if ApplyCellSegMask
            mask = maskProc.loadChannelOutput(iChan,1);
        else
            mask = true(MD.imSize_);
        end
        for ii=1:nFrames
            % Cell Boundary Mask 
            if ApplyCellSegMask
                mask = maskProc.loadChannelOutput(iChan,ii);
            else
                mask = true(MD.imSize_);
            end
            % mask for band from edge
            maskOnlyBand = mask;
            bandArea(ii) = sum(maskOnlyBand(:)); % in pixel
            % filter tracks with naMasks
            % only deal with presence and status
            % Tracks in its emerging state ever overlap with bandMask are
            % considered.
            for k=1:numel(tracksNA)
                if tracksNA(k).presence(ii) && ~isnan(tracksNA(k).yCoord(ii)) && ...
                        ((round(tracksNA(k).xCoord(ii)) > size(maskOnlyBand,2) || ...
                        round(tracksNA(k).xCoord(ii)) < 1 || ...
                        round(tracksNA(k).yCoord(ii)) > size(maskOnlyBand,1) || ...
                        round(tracksNA(k).yCoord(ii)) < 1) || ...
                        ~maskOnlyBand(round(tracksNA(k).yCoord(ii)),round(tracksNA(k).xCoord(ii))))
                    tracksNA(k).state{ii} = 'Out_of_Band';
                    tracksNA(k).presence(ii) = false;
                    if trackIdx(k)
                        trackIdx(k) = false;
                    end
                end
            end
        end
    end
    % get rid of tracks that have out of bands...
    tracksNA = tracksNA(trackIdx);
    %% add intensity of tracks including before and after NA status
    % get the movie stack
    disp('Loading image stacks ...'); tic;
    h = MD.imSize_(1); 
    w = MD.imSize_(2);
    imgStack = zeros(h,w,nFrames);
    for ii = 1:nFrames
        imgStack(:,:,ii) = MD.channels_(iPaxChannel).loadImage(ii); 
    end
    toc;

    % get the intensity
    disp('Reading intensities with additional tracking...')
    tic

    % reTrack=false;
    tracksNA = readIntensityFromTracks(tracksNA, imgStack, 1, 'extraLength',30,'movieData',MD,'retrack',reTrack); % 1 means intensity collection from pax image


    toc
    %% Filtering again after re-reading
    disp('Filtering again after re-reading with cell mask ...')
    tic
    if onlyEdge
        trackIdx = true(numel(tracksNA),1);
        bandwidthNA_pix = round(bandwidthNA*1000/MD.pixelSize_);
        for ii=1:nFrames
            % Cell Boundary Mask 
            if ApplyCellSegMask
                mask = maskProc.loadChannelOutput(iChan,ii);
            else
                mask = true(MD.imSize_);
            end
            % mask for band from edge
            iMask = imcomplement(mask);
            distFromEdge = bwdist(iMask);
            bandMask = distFromEdge <= bandwidthNA_pix;

            maskOnlyBand = bandMask & mask;
            bandArea(ii) = sum(maskOnlyBand(:)); % in pixel

            % collect index of tracks which first appear at frame ii
    %         idxFirstAppear = arrayfun(@(x) x.startingFrameExtra==ii,tracksNA);
            % now see if these tracks ever in the maskOnlyBand
            for k=find(trackIdx)'
    %         for k=find(idxFirstAppear)'
                if tracksNA(k).presence(ii) && ~isnan(tracksNA(k).yCoord(ii)) && ...
                        ((round(tracksNA(k).xCoord(ii)) > size(maskOnlyBand,2) || ...
                        round(tracksNA(k).xCoord(ii)) < 1 || ...
                        round(tracksNA(k).yCoord(ii)) > size(maskOnlyBand,1) || ...
                        round(tracksNA(k).yCoord(ii)) < 1) || ...
                        ~maskOnlyBand(round(tracksNA(k).yCoord(ii)),round(tracksNA(k).xCoord(ii))))
                    trackIdx(k) = false;
                end
            end
        end    
    else
        disp('Entire adhesion tracks are considered.')
        trackIdx = true(numel(tracksNA),1);
        for ii=1:nFrames
            % Cell Boundary Mask 
            if ApplyCellSegMask
                mask = maskProc.loadChannelOutput(iChan,ii);
            else
                mask = true(MD.imSize_);
            end
            % mask for band from edge
            maskOnlyBand = mask;
            bandArea(ii) = sum(maskOnlyBand(:)); % in pixel
            % filter tracks with naMasks
            % only deal with presence and status
            % Tracks in its emerging state ever overlap with bandMask are
            % considered.
            for k=find(trackIdx)'
                if tracksNA(k).presence(ii) && ~isnan(tracksNA(k).yCoord(ii)) && ...
                        ((round(tracksNA(k).xCoord(ii)) > size(maskOnlyBand,2) || ...
                        round(tracksNA(k).xCoord(ii)) < 1 || ...
                        round(tracksNA(k).yCoord(ii)) > size(maskOnlyBand,1) || ...
                        round(tracksNA(k).yCoord(ii)) < 1) || ...
                        ~maskOnlyBand(round(tracksNA(k).yCoord(ii)),round(tracksNA(k).xCoord(ii))))
                    tracksNA(k).state{ii} = 'Out_of_Band';
                    tracksNA(k).presence(ii) = false;
                    if trackIdx(k)
                        trackIdx(k) = false;
                    end
                end
            end
        end
    end
    toc
    % get rid of tracks that have out of bands...
    tracksNA = tracksNA(trackIdx);
    %%%%%
    %% Filter with lifeTime again
    lifeTime = arrayfun(@(x) x.endingFrameExtra-x.startingFrameExtra,tracksNA);
    tracksNA = tracksNA(lifeTime>minLifetime);
    %% Matching with adhesion setup
    if ApplyCellSegMask
        firstMask=maskProc.loadChannelOutput(iChan,1);
    else
        firstMask=true(MD.imSize_);
    end

    cropMaskStack = false(size(firstMask,1),size(firstMask,2),nFrames);
    numTracks=numel(tracksNA);

    focalAdhInfo(nFrames,1)=struct('xCoord',[],'yCoord',[],...
        'amp',[],'area',[],'length',[],'meanFAarea',[],'medianFAarea',[]...
        ,'meanLength',[],'medianLength',[],'numberFA',[],'FAdensity',[],'cellArea',[],'ecc',[]);
    FAInfo(nFrames,1)=struct('xCoord',[],'yCoord',[],...
        'amp',[],'area',[],'length',[]);

    %% Matching with segmented adhesions
    progressText(0,'Matching with segmented adhesions', 'Adhesion Analysis');
    prevMask=[];
    neighPix = 2;

    tic;
    for ii=1:nFrames
        % Cell Boundary Mask 
        if ApplyCellSegMask
            mask = maskProc.loadChannelOutput(iChan,ii);
            if ii>1 && max(mask(:))==0
                mask=prevMask;
                disp('Previous mask is used for cell edge because the current mask is empty.')
            else
                prevMask=mask;
            end
        else
            mask=true(MD.imSize_);
        end
        % Cell Boundary
        [B,~,nBD]  = bwboundaries(mask,'noholes');
        cropMaskStack(:,:,ii) = mask;
        % Get the mask for FAs
        I=MD.channels_(iPaxChannel).loadImage(ii); 
        maskFAs = FASegProc.loadChannelOutput(iPaxChannel,ii);
        maskAdhesion = maskFAs>0 & mask;
        % FA Segmentation usually over-segments things. Need to chop them off
        % to smaller ones or filter insignificant segmentation out.
        xNA=arrayfun(@(x) x.xCoord(ii),tracksNA);
        yNA=arrayfun(@(x) x.yCoord(ii),tracksNA);
        try
            maskAdhesion = refineAdhesionSegmentation(maskAdhesion,I,xNA,yNA);%,mask);
        catch
            disp('Refine adhesion mask is failed, Proceeding with the next step ...')
        end
        % close once and dilate once
        % maskAdhesion = bwmorph(maskAdhesion,'close');
    %         maskAdhesion = bwmorph(maskAdhesion,'thin',1);
    %         Adhs = regionprops(maskAdhesion,'Area','Eccentricity','PixelIdxList','PixelList' );
        % Save focal adhesion information
        Adhs = regionprops(bwconncomp(maskAdhesion,4),'Centroid','Area','Eccentricity','PixelList','PixelIdxList','MajorAxisLength');
        numAdhs(ii) = numel(Adhs);
    %         minFASize = round((1000/MD.pixelSize_)*(1000/MD.pixelSize_)); %adhesion limit=1um*1um
    %         minFCSize = round((600/MD.pixelSize_)*(400/MD.pixelSize_)); %adhesion limit=0.6um*0.4um
        minFALength = round((2000/MD.pixelSize_)); %adhesion limit=2um
        minFCLength = round((600/MD.pixelSize_)); %adhesion limit=0.6um

    %         fcIdx = arrayfun(@(x) x.Area<minFASize & x.Area>minFCSize, Adhs);
        fcIdx = arrayfun(@(x) x.MajorAxisLength<minFALength & x.MajorAxisLength>minFCLength, Adhs);
        FCIdx = find(fcIdx);
        adhBound = bwboundaries(maskAdhesion,4,'noholes');    

        % for larger adhesions
    %         faIdx = arrayfun(@(x) x.Area>=minFASize, Adhs);
        faIdx = arrayfun(@(x) x.MajorAxisLength>=minFALength, Adhs);
        FAIdx =  find(faIdx);

        FCs = Adhs(fcIdx | faIdx);
        numFCs = length(FCs);
        for k=1:numFCs
            focalAdhInfo(ii).xCoord(k) = round(FCs(k).Centroid(1));
            focalAdhInfo(ii).yCoord(k) = round(FCs(k).Centroid(2));
            focalAdhInfo(ii).area(k) = FCs(k).Area;
            focalAdhInfo(ii).length(k) = FCs(k).MajorAxisLength;
            focalAdhInfo(ii).amp(k) = mean(I(FCs(k).PixelIdxList));
            focalAdhInfo(ii).ecc(k) = FCs(k).Eccentricity;
        end
        focalAdhInfo(ii).numberFA = numFCs;
        focalAdhInfo(ii).meanFAarea = mean(focalAdhInfo(ii).area);
        focalAdhInfo(ii).medianFAarea = median(focalAdhInfo(ii).area);
        focalAdhInfo(ii).meanLength = mean(focalAdhInfo(ii).length);
        focalAdhInfo(ii).medianLength = median(focalAdhInfo(ii).length);
        focalAdhInfo(ii).cellArea = sum(mask(:))*(MD.pixelSize_/1000)^2; % in um^2
        focalAdhInfo(ii).FAdensity = numFCs/focalAdhInfo(ii).cellArea; % number per um2
        focalAdhInfo(ii).numberFC = sum(fcIdx);
        focalAdhInfo(ii).FAtoFCratio = sum(faIdx)/sum(fcIdx);
        focalAdhInfo(ii).numberPureFA = sum(faIdx);

        FAs = Adhs(faIdx);
        numFAs = length(FAs);
        for k=1:numFAs
            FAInfo(ii).xCoord(k) = round(FAs(k).Centroid(1));
            FAInfo(ii).yCoord(k) = round(FAs(k).Centroid(2));
            FAInfo(ii).area(k) = FAs(k).Area;
            FAInfo(ii).length(k) = FAs(k).MajorAxisLength;
            FAInfo(ii).amp(k) = mean(I(FAs(k).PixelIdxList));
            FAInfo(ii).ecc(k) = FAs(k).Eccentricity;
        end

        if matchWithFA
            %% Field creation before running parfor
            if ~isfield(tracksNA,'refineFAID')
                tracksNA(end).refineFAID=[];
            end
            if ~isfield(tracksNA,'faID')
                tracksNA(end).faID=[];
            end
            if ~isfield(tracksNA,'area')
                tracksNA(end).area=[];
            end
            % Save the labels
            imwrite(maskAdhesion, strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'),'Compression','none');
            labelAdhesion = bwlabel(maskAdhesion,4);
%             if max(labelAdhesion(:))<2^8
%                 imwrite(uint8(labelAdhesion), strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'),'Compression','none');
%             elseif max(labelAdhesion(:))<2^16
%                 imwrite(uint16(labelAdhesion), strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'),'Compression','none');
%             else
%                 imwrite(uint16(labelAdhesion), strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'),'Compression','none');
%             end
            parfor k=1:numTracks
                curTrack=tracksNA(k);
                if curTrack.presence(ii)
    %                     if ~strcmp(curTrack.state{ii} , 'NA') && ii>1
    %                         curTrack.state{ii} = curTrack.state{ii-1};
    %                     end
                    % decide if each track is associated with FC or FA
                    if maskAdhesion(round(curTrack.yCoord(ii)),round(curTrack.xCoord(ii)))>0 %#ok<PFBNS>
                        iAdh = labelAdhesion(round(curTrack.yCoord(ii)),round(curTrack.xCoord(ii))); %#ok<PFBNS>
                        if ismember(iAdh,FCIdx)
                            curTrack.state{ii} = 'FC';
                            curTrack.area(ii) = Adhs(iAdh).Area;%#ok<PFBNS> % in pixel
    %                             curTrack.FApixelList{ii} = Adhs(iAdh).PixelList;
    %                             curTrack.adhBoundary{ii} = adhBound{iAdh};
                            curTrack.refineFAID(ii) = iAdh;
                            curTrack.faID(ii) = maskFAs(round(curTrack.yCoord(ii)),round(curTrack.xCoord(ii))); %#ok<PFBNS>
                        elseif ismember(iAdh,FAIdx)
                            curTrack.state{ii} = 'FA';
                            curTrack.area(ii) = Adhs(iAdh).Area;% in pixel
    %                             curTrack.FApixelList{ii} = Adhs(iAdh).PixelList;
    %                             curTrack.adhBoundary{ii} = adhBound{iAdh};
                            curTrack.refineFAID(ii) = iAdh;
                            curTrack.faID(ii) = maskFAs(round(curTrack.yCoord(ii)),round(curTrack.xCoord(ii)));
                        else 
                            curTrack.state{ii} = 'NA';
                            curTrack.area(ii) = Adhs(iAdh).Area;% in pixel
    %                             curTrack.FApixelList{ii} = Adhs(iAdh).PixelList;
    %                             curTrack.adhBoundary{ii} = adhBound{iAdh};
                            curTrack.refineFAID(ii) = iAdh;
                            curTrack.faID(ii) = maskFAs(round(curTrack.yCoord(ii)),round(curTrack.xCoord(ii)));
                        end
                    else
                        curTrack.state{ii} = 'NA';
                        curTrack.area(ii) = NaN;% in pixel
    %                         curTrack.FApixelList{ii} = [];
    %                         curTrack.adhBoundary{ii} = [];
                        curTrack.refineFAID(ii) = NaN;
                        curTrack.faID(ii) = NaN;
                    end
                elseif ii>curTrack.endingFrameExtra && ...
                        (strcmp(curTrack.state{curTrack.endingFrameExtra},'FA')...
                        || strcmp(curTrack.state{curTrack.endingFrameExtra},'FC')) && ...
                        sum(cellfun(@(x) strcmp(x,'ANA'),curTrack.state(curTrack.endingFrame:ii)))<3
                    % starting from indexed maskFAs, find out segmentation that is
                    % closest to the last track point.
                    curTrack.xCoord(ii) = curTrack.xCoord(curTrack.endingFrameExtra);
                    curTrack.yCoord(ii) = curTrack.yCoord(curTrack.endingFrameExtra);
                    xi = round(curTrack.xCoord(ii));
                    yi = round(curTrack.yCoord(ii));
                    xRange = max(1,xi-neighPix):min(xi+neighPix,w);
                    yRange = max(1,yi-neighPix):min(yi+neighPix,h);
                    curAmpTotal = I(yRange,xRange); %#ok<PFBNS>
                    curAmpTotal = mean(curAmpTotal(:));
                    curTrack.ampTotal(ii) =  curAmpTotal;

                    currentFAID = curTrack.faID(curTrack.endingFrameExtra);
                    subMaskFAs = maskFAs==currentFAID;
                    if max(subMaskFAs(:))==0
                        curTrack.state{ii} = 'ANA';
    %                         curTrack.FApixelList{ii} = NaN;
    %                         curTrack.adhBoundary{ii} = NaN;
                        continue
                    elseif maskAdhesion(round(curTrack.yCoord(curTrack.endingFrameExtra)),...
                            round(curTrack.xCoord(curTrack.endingFrameExtra)))>0
    %                         curTrack.xCoord(ii) = curTrack.xCoord(curTrack.endingFrameExtra);
    %                         curTrack.yCoord(ii) = curTrack.yCoord(curTrack.endingFrameExtra);
                        iAdh = labelAdhesion(round(curTrack.yCoord(ii)),round(curTrack.xCoord(ii)));
    %                         propSubMaskFAs = regionprops(subMaskFAs,'PixelList','MajorAxisLength','Area');
    %                         minDist = zeros(length(propSubMaskFAs),1);
    %                         for q=1:length(propSubMaskFAs)
    %                             minDist(q) = min(sqrt((propSubMaskFAs(q).PixelList(:,1)-(curTrack.xCoord(curTrack.endingFrameExtra))).^2 +...
    %                                 (propSubMaskFAs(q).PixelList(:,2)-(curTrack.yCoord(curTrack.endingFrameExtra))).^2));
    %                         end
    %                         % find the closest segment
    %                         [~,subMaskFAsIdx] = min(minDist);
    %                         subAdhBound = bwboundaries(subMaskFAs,'noholes');    
    % %                         [~,closestPixelID] = min(sqrt((propSubMaskFAs(subMaskFAsIdx).PixelList(:,1)-(curTrack.xCoord(curTrack.endingFrameExtra))).^2 +...
    % %                             (propSubMaskFAs(subMaskFAsIdx).PixelList(:,2)-(curTrack.yCoord(curTrack.endingFrameExtra))).^2));
    %                         if propSubMaskFAs(subMaskFAsIdx).MajorAxisLength>minFCLength && ...
    %                                 propSubMaskFAs(subMaskFAsIdx).MajorAxisLength<minFALength
    %                             curTrack.state{ii} = 'FC';
    %                         elseif propSubMaskFAs(subMaskFAsIdx).MajorAxisLength >= minFALength
    %                             curTrack.state{ii} = 'FA';
    %                         else
    %                             curTrack.state{ii} = 'NA';
    %                         end
                        if ismember(iAdh,FCIdx)
                            curTrack.state{ii} = 'FC';
                        elseif ismember(iAdh,FAIdx)
                            curTrack.state{ii} = 'FA';
                        else 
                            curTrack.state{ii} = 'NA';
                        end
                        curTrack.presence(ii)=true;
                        curTrack.endingFrameExtra = ii; % This is update I did on 5/24/17.
    %                         curTrack.lifeTime = ii-curTrack.startingFrameExtra; % This is update I did on 5/24/17.
    %                     curTrack.xCoord(ii) = propSubMaskFAs(subMaskFAsIdx).PixelList(closestPixelID,1);
    %                     curTrack.yCoord(ii) = propSubMaskFAs(subMaskFAsIdx).PixelList(closestPixelID,2);
    %                         curTrack.FApixelList{ii} = propSubMaskFAs(subMaskFAsIdx).PixelList;
    %                         curTrack.adhBoundary{ii} = subAdhBound{subMaskFAsIdx};
                        curTrack.faID(ii) = currentFAID;
                        curTrack.refineFAID(ii) = iAdh;
                        curTrack.area(ii) = Adhs(iAdh).Area; %propSubMaskFAs(subMaskFAsIdx).Area;% in pixel
                        if curTrack.endingFrameExtraExtra<curTrack.endingFrameExtra 
                            curTrack.endingFrameExtraExtra=curTrack.endingFrameExtra;
                        end
                    end
                end
                tracksNA(k)=curTrack;
            end
        else
            FCIdx = [];
            FAIdx = [];
        end
        % recording features
        % get the point on the boundary closest to the adhesion
        if getEdgeRelatedFeatures
            allBdPoints = [];
            for kk=1:nBD
                boundary = B{kk};
                allBdPoints = [allBdPoints; boundary(:,2), boundary(:,1)];
            end
            for k=1:numel(tracksNA)
                % distance to the cell edge
        %         if tracksNA(k).presence(ii)
                if ii>=tracksNA(k).startingFrameExtraExtra && ii<=tracksNA(k).endingFrameExtraExtra
                    xCropped = tracksNA(k).xCoord(ii);
                    yCropped = tracksNA(k).yCoord(ii);
                    distToAdh = sqrt(sum((allBdPoints- ...
                        ones(size(allBdPoints,1),1)*[xCropped, yCropped]).^2,2));
                    [minDistToBd,indMinBdPoint] = min(distToAdh);
                    tracksNA(k).distToEdge(ii) = minDistToBd;
                    tracksNA(k).closestBdPoint(ii,:) = allBdPoints(indMinBdPoint,:); % this is lab frame of reference. (not relative to adhesion position)
                    if allBdPoints(indMinBdPoint,1)==0 || isnan(allBdPoints(indMinBdPoint,1))
                        error(['Error occurred at ii=' num2str(ii) ' and indMinBDPoint=' num2str(indMinBdPoint) ' and k=' num2str(k) ', allBdPoints(indMinBdPoint,1)=' num2str(allBdPoints(indMinBdPoint,1))]);
                    end
                end
            end
        end
        progressText(ii/(nFrames));
    end


    %% protrusion/retraction information
    % time after protrusion onset (negative value if retraction, based
    % on the next protrusion onset) in frame, based on tracksNA.distToEdge
    % First I have to quantify when the protrusion and retraction onset take
    % place.

    if getEdgeRelatedFeatures
        for k=1:numTracks
            idxZeros = tracksNA(k).closestBdPoint(:,1)==0 & tracksNA(k).closestBdPoint(:,2)==0;
            tracksNA(k).closestBdPoint(idxZeros,:)=NaN(sum(idxZeros),2);
        end
    end

    deltaT = MD.timeInterval_; % sampling rate (in seconds, every deltaT seconds)
    if ~isfield(tracksNA,'advanceDist')
        tracksNA = getFeaturesFromTracksNA(tracksNA, deltaT, getEdgeRelatedFeatures);%,...);
        clear cropMaskStack
        % This will add features like: advanceDist, edgeAdvanceDist, MSD,
        % MSDrate, assemRate, disassemRate, earlyAmpSlope,lateAmpSlope
    end

    %% saving
    tableTracksNA = struct2table(tracksNA);
    save(dataPath_tracksNA, 'tracksNA', 'tableTracksNA','-v7.3');
    save(dataPath_focalAdhInfo, 'focalAdhInfo','-v7.3')
else
    load(dataPath_tracksNA, 'tracksNA');
    load(dataPath_focalAdhInfo, 'focalAdhInfo')    
end
%% re-express tracksNA so that SDC is applied to each feature
if ~isempty(SDCProc)
    if ~isfield(tracksNA,'SDC_applied')
        disp('Applying stage drift correction ...')
        if isa(SDCProc,'EfficientSubpixelRegistrationProcess')
            tracksNA = applyDriftToTracks(tracksNA, T, 1); % need some other function....formatNATracks(tracksNAorg,detectedNAs,nFrames,T); 
        else
            tracksNA = applyDriftToTracks(tracksNA, T, 0);
        end
        deltaT = MD.timeInterval_; % sampling rate (in seconds, every deltaT seconds)
        % This will add features like: advanceDist, edgeAdvanceDist, MSD,
        % MSDrate, assemRate, disassemRate, earlyAmpSlope,lateAmpSlope
        tracksNA = getFeaturesFromTracksNA(tracksNA, deltaT, getEdgeRelatedFeatures);%,...);
        tableTracksNA = struct2table(tracksNA);
        save(dataPath_tracksNA, 'tracksNA', 'tableTracksNA','-v7.3');
        
        % Apply SDC to labelAdhesion too
        for  ii = 1 : nFrames
            labelAdhesion = imread(strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'));
            labelAdhesion = imtranslate(labelAdhesion,T(ii,:));
            if max(labelAdhesion(:))<2^7
                imwrite(uint8(labelAdhesion), strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'));
            elseif max(labelAdhesion(:))<2^15
                imwrite(uint16(labelAdhesion), strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'));
            else
                imwrite(uint16(labelAdhesion), strcat(labelTifPath,'/label',num2str(ii,iiformat),'.tif'));
            end
        end
    else
        disp('Stage drift correction was already applied to tracksNA.')
    end
end

%% NA FA Density analysis
numNAs = zeros(nFrames,1);
numNAsInBand = zeros(nFrames,1);
trackIdx = true(numel(tracksNA),1);
bandwidthNA_pix = round(bandwidthNA*1000/MD.pixelSize_);
for ii=1:nFrames
    if ApplyCellSegMask
        mask = maskProc.loadChannelOutput(iChan,ii);
    else
        mask = true(MD.imSize_);
    end

    % mask = maskProc.loadChannelOutput(iChan,ii);
    % mask for band from edge
    iMask = imcomplement(mask);
    distFromEdge = bwdist(iMask);
    bandMask = distFromEdge <= bandwidthNA_pix;

    maskOnlyBand = bandMask & mask;
    bandArea(ii) = sum(maskOnlyBand(:)); % in pixel

    % collect index of tracks which first appear at frame ii
%         idxFirstAppear = arrayfun(@(x) x.startingFrameExtra==ii,tracksNA);
    % now see if these tracks ever in the maskOnlyBand
    for k=find(trackIdx)'
%         for k=find(idxFirstAppear)'
        if tracksNA(k).presence(ii) && ~isnan(tracksNA(k).yCoord(ii)) && ...
                ((round(tracksNA(k).xCoord(ii)) > size(maskOnlyBand,2) || ...
                round(tracksNA(k).xCoord(ii)) < 1 || ...
                round(tracksNA(k).yCoord(ii)) > size(maskOnlyBand,1) || ...
                round(tracksNA(k).yCoord(ii)) < 1) || ...
                ~maskOnlyBand(round(tracksNA(k).yCoord(ii)),round(tracksNA(k).xCoord(ii))))
            trackIdx(k) = false;
        end
    end
%         for k=find(trackIdxFC)' % I'll work on this later (1/10/17) SH
% %         for k=find(idxFirstAppear)'
%             if focalAdhInfo(ii).presence(ii) && ~isnan(tracksNA(k).yCoord(ii)) && ...
%                     ((round(tracksNA(k).xCoord(ii)) > size(maskOnlyBand,2) || ...
%                     round(tracksNA(k).xCoord(ii)) < 1 || ...
%                     round(tracksNA(k).yCoord(ii)) > size(maskOnlyBand,1) || ...
%                     round(tracksNA(k).yCoord(ii)) < 1) || ...
%                     ~maskOnlyBand(round(tracksNA(k).yCoord(ii)),round(tracksNA(k).xCoord(ii))))
%                 trackIdx(k) = false;
%             end
%         end
    numNAs(ii) = sum(arrayfun(@(x) (x.presence(ii)==true), tracksNA));
    numNAsInBand(ii) = sum(trackIdx);
    NADensity(ii) = numNAsInBand(ii)/(bandArea(ii)*MD.pixelSize_^2*1e-6);  % unit: number/um2 
    
    FADensity(ii) = focalAdhInfo(ii).FAdensity;  % unit: number/um2 
end
save(dataPath_NAFADensity, 'NADensity','FADensity','bandwidthNA','numNAsInBand')
lifeNames = {'NADensity','FADensity','bandwidthNA','numNAsInBand'};
A= table({NADensity; FADensity; bandwidthNA; numNAsInBand'},'RowNames',lifeNames);
writetable(A,[dataPath filesep 'NAFADensity.csv'])

%% Lifetime analysis
p2=0;
idx = false(numel(tracksNA),1);
for k=1:numel(tracksNA)
    % look for tracks that had a state of 'BA' and become 'NA'
    firstNAidx = find(strcmp(tracksNA(k).state,'NA'),1,'first');
    % see if the state is 'BA' before 'NA' state
    if (~isempty(firstNAidx) && firstNAidx>1 && strcmp(tracksNA(k).state(firstNAidx-1),'BA')) || (~isempty(firstNAidx) &&firstNAidx==1)
        p2=p2+1;
        idx(k) = true;
        tracksNA(k).emerging = true;
        tracksNA(k).emergingFrame = firstNAidx;
    else
        tracksNA(k).emerging = false;
    end        
end

%% Analysis of those whose force was under noise level: how long does it take
% Analysis shows that force is already developed somewhat compared to
% background. 
% Filter out any tracks that has 'Out_of_ROI' in their status (especially
% after NA ...)
trNAonly = tracksNA(idx);
if matchWithFA
    indMature = false(numel(trNAonly));
    indFail = false(numel(trNAonly));
    p2=0; q=0;

    for k=1:numel(trNAonly)
        if trNAonly(k).emerging 
            % maturing NAs
            if (any(strcmp(trNAonly(k).state(trNAonly(k).emergingFrame:end),'FC')) || ...
                    any(strcmp(trNAonly(k).state(trNAonly(k).emergingFrame:end),'FA'))) && ...
                    sum(trNAonly(k).presence)>8

                trNAonly(k).maturing = true;
                indMature(k) = true;
                p2=p2+1;
                % lifetime until FC
                lifeTimeNAmaturing(p2) = sum(strcmp(trNAonly(k).state(trNAonly(k).emergingFrame:end),'NA'));
                % it might be beneficial to store amplitude time series. But
                % this can be done later from trackNAmature
            elseif sum(tracksNA(k).presence)<61 && sum(tracksNA(k).presence)>6
            % failing NAs
                tracksNA(k).maturing = false;
                indFail(k) = true;
                q=q+1;
                % lifetime until FC
                lifeTimeNAfailing(q) = sum(strcmp(trNAonly(k).state(trNAonly(k).emergingFrame:end),'NA'));
            end
        end
    end
    lifeTimeAll = [lifeTimeNAmaturing lifeTimeNAfailing];
    maturingRatio = p2/(p2+q);
    tracksNAmaturing = trNAonly(indMature);
    tracksNAfailing = trNAonly(indFail);
    save(dataPath_analysisAll, 'maturingRatio','lifeTimeNAfailing','lifeTimeNAmaturing','lifeTimeAll','-v7.3'); %, 'trNAonly', 'tracksNAfailing','tracksNAmaturing','maturingRatio','lifeTimeNAfailing','lifeTimeNAmaturing')
    lifeNames = {'maturingRatio','lifeTimeNAfailing','lifeTimeNAmaturing','lifeTimeAll'};
    B= table({maturingRatio';lifeTimeNAfailing;lifeTimeNAmaturing;lifeTimeAll},'RowNames',lifeNames);
    outFilename = [chanDirName '_Chan' num2str(iChan) '_allAnalysisFA'];
    dataPath_analysisAllcsv = [p.OutputDirectory filesep outFilename 'lifeTimes.csv'];
    writetable(B,dataPath_analysisAllcsv)

    %% Assembly rate
    % We decided to look at only actually assebling NAs
    % Getting indices of them:
    assemblingNAIdx = arrayfun(@(y) y.startingFrame>1,trNAonly);

    assemRateCellAll = arrayfun(@(y) y.assemRate, trNAonly);
    % filtering in only actually assembling NAs and make it positive
    assemRateCell = assemRateCellAll(assemblingNAIdx);
    
    %% Disassembly rate
    % We decided to look at only actually disassebling NAs
    % Getting indices of them:
    disassemblingNAIdx = arrayfun(@(y) y.endingFrame+1, trNAonly)<max(arrayfun(@(y) y.endingFrame, trNAonly));

    disassemRateCellAll = arrayfun(@(y) y.disassemRate, trNAonly);
    % filtering in only actually disassembling NAs and make it positive
    disassemRateCell = disassemRateCellAll(disassemblingNAIdx);
    %% NA nucleation ratio: How many of NAs were newly assembled - I changed this.
    curNewNAs = arrayfun(@(y) sum(arrayfun(@(x) x.startingFrameExtra==y,trNAonly)),(1:nFrames)');
    curDeadNAs = arrayfun(@(y) sum(arrayfun(@(x) x.endingFrameExtra==y,trNAonly)),(1:nFrames)');
    curExistingNAs = arrayfun(@(y) sum(arrayfun(@(x) double(x.presence(y)),trNAonly)),(1:nFrames)');
    curNewNARatio = curNewNAs./curExistingNAs;
    curDeadNARatio = curDeadNAs./curExistingNAs;

%     curNumStableNAs = sum(arrayfun(@(x) x.lifeTime>0.8*curNFrames,trNAonly));
    % I have to ignore the very first frame and the last four frames.
    numStableNAs = curNewNAs(1);
    curNewNAs2 = curNewNAs(2:end-5);
    curNewNARatio2 = curNewNARatio(2:end-5);
    stableNARatio = curNewNARatio(1);
    curDeadNAs2 = curDeadNAs(5:end-1);
    curDeadNARatio2 = curDeadNARatio(5:end-1);

    nucleationNumber = curNewNAs2; %sum(arrayfun(@(y) y.startingFrame>1, trNAonly));
    nucleationRatio = curNewNARatio2; %nucleationNumber/focalAdhInfo(1).cellArea;

    %% NA disassembly ratio
    disassemblingNANumber = curDeadNAs2; %sum(arrayfun(@(y) y.endingFrameExtra+1, trNAonly)<max(arrayfun(@(y) y.endingFrameExtra, trNAonly)));
    disassemblingNARatio = curDeadNARatio2; %disassemblingNANumber/focalAdhInfo(1).cellArea;
    %% save
    save(assembly_disassembly_ratesPath, 'assemRateCell', 'disassemRateCell','nucleationRatio','maturingRatio','disassemblingNARatio','-v7.3')
    
    assemRateCell = assemRateCell(~isnan(assemRateCell));
    disassemRateCell = disassemRateCell(~isnan(disassemRateCell));
    
    % I need to work to make the same number of the raws for these
    % variables.
    assemNames = {'assemRateCell', 'disassemRateCell','nucleationNumber','nucleationRatio','numStableNAs', 'stableNARatio','disassemblingNANumber','disassemblingNARatio'};
    C= table({assemRateCell; disassemRateCell; nucleationNumber; nucleationRatio; numStableNAs; stableNARatio; disassemblingNANumber; disassemblingNARatio},'RowNames',assemNames);
    assembly_disassembly_ratesPathCSV=[assembly_disassembly_ratesPath(1:end-4) '.csv'];
    writetable(C,assembly_disassembly_ratesPathCSV)
else
    trNAonly = tracksNA;
    indMature = [];
    indFail = [];
    lifeTimeNAfailing=[];
    lifeTimeNAmaturing =[];
    maturingRatio = [];
end

end
disp('Adhesion Analysis Done!')
end

function newTracks = formatTracks(tracks,detectedNAs,nFrames)
% Format tracks structure into tracks with every frame

newTracks(numel(tracks),1) = struct('xCoord', [], 'yCoord', [],'state',[],'iFrame',[],'presence',[],'amp',[],'bkgAmp',[]);
% BA: before adhesion, NA: nascent adh, FC: focal complex, FA: focal adh,
% ANA: after NA (failed to be matured.
%OUTPUT tracksFinal   : Structure array where each element corresponds to a 
%                       compound track. Each element contains the following 
%                       fields:
%           .tracksFeatIndxCG: Connectivity matrix of features between
%                              frames, after gap closing. Number of rows
%                              = number of track segments in compound
%                              track. Number of columns = number of frames
%                              the compound track spans. Zeros indicate
%                              frames where track segments do not exist
%                              (either because those frames are before the
%                              segment starts or after it ends, or because
%                              of losing parts of a segment.
%           .tracksCoordAmpCG: The positions and amplitudes of the tracked
%                              features, after gap closing. Number of rows
%                              = number of track segments in compound
%                              track. Number of columns = 8 * number of
%                              frames the compound track spans. Each row
%                              consists of
%                              [x1 y1 z1 a1 dx1 dy1 dz1 da1 x2 y2 z2 a2 dx2 dy2 dz2 da2 ...]
%                              NaN indicates frames where track segments do
%                              not exist, like the zeros above.
%           .seqOfEvents     : Matrix with number of rows equal to number
%                              of events happening in a compound track and 4
%                              columns:
%                              1st: Frame where event happens;
%                              2nd: 1 = start of track segment, 2 = end of track segment;
%                              3rd: Index of track segment that ends or starts;
%                              4th: NaN = start is a birth and end is a death,
%                                   number = start is due to a split, end
%                                   is due to a merge, number is the index
%                                   of track segment for the merge/split.
progressText(0,'formatting tracks', 'Analysis Initialization');
for i = 1:numel(tracks)
    % Get the x and y coordinate of all compound tracks
    startNA = true;
    endNA = true;
    for  jj = 1 : nFrames
        newTracks(i).iFrame(jj) = jj;
        if jj<tracks(i).seqOfEvents(1,1)     % before Adhesion
            newTracks(i).state{jj} = 'BA';
            newTracks(i).xCoord(jj) = NaN;
            newTracks(i).yCoord(jj) = NaN;
            newTracks(i).presence(jj) = false;
            newTracks(i).amp(jj) = NaN;
            newTracks(i).bkgAmp(jj) = NaN;
        elseif jj>tracks(i).seqOfEvents(end,1) % Adhesion gone!
            newTracks(i).state{jj} = 'ANA';
            newTracks(i).xCoord(jj) = NaN;
            newTracks(i).yCoord(jj) = NaN;
            newTracks(i).amp(jj) = NaN;
            newTracks(i).bkgAmp(jj) = NaN;
            newTracks(i).presence(jj) = false;
            if endNA
                newTracks(i).endingFrame = jj-1; % mark end of frame
                endNA = false;
            end
        elseif jj==tracks(i).seqOfEvents(2,1) % Adhesion occuring
            newTracks(i).state{jj} = 'NA';
            newTracks(i).xCoord(jj) = tracks(i).tracksCoordAmpCG(1,1+8*(jj-tracks(i).seqOfEvents(1,1)));
            newTracks(i).yCoord(jj) = tracks(i).tracksCoordAmpCG(1,2+8*(jj-tracks(i).seqOfEvents(1,1)));
            newTracks(i).amp(jj) = tracks(i).tracksCoordAmpCG(1,4+8*(jj-tracks(i).seqOfEvents(1,1)));
            if tracks(i).tracksFeatIndxCG(jj-tracks(i).seqOfEvents(1,1)+1)==0
                newTracks(i).bkgAmp(jj) = NaN;
            else
                jFromBirth=jj-tracks(i).seqOfEvents(1,1)+1;
                newTracks(i).bkgAmp(jj) = detectedNAs(jj).bkg(tracks(i).tracksFeatIndxCG(jFromBirth));
                newTracks(i).sigma(jj) = detectedNAs(jj).sigmaX(tracks(i).tracksFeatIndxCG(jFromBirth));
            end
            newTracks(i).presence(jj) = true;
            if startNA
                newTracks(i).startingFrame = jj; % Frame when adhesion starts
                startNA = false;
            end
            if endNA
                newTracks(i).endingFrame = jj; % Frame when adhesion ends
                endNA = false;
            end
        else
            newTracks(i).state{jj} = 'NA';
            newTracks(i).xCoord(jj) = tracks(i).tracksCoordAmpCG(1,1+8*(jj-tracks(i).seqOfEvents(1,1)));
            newTracks(i).yCoord(jj) = tracks(i).tracksCoordAmpCG(1,2+8*(jj-tracks(i).seqOfEvents(1,1)));
            newTracks(i).amp(jj) = tracks(i).tracksCoordAmpCG(1,4+8*(jj-tracks(i).seqOfEvents(1,1)));
            if tracks(i).tracksFeatIndxCG(jj-tracks(i).seqOfEvents(1,1)+1)==0
                newTracks(i).bkgAmp(jj) = NaN;
            else % tracksFeatIndxCG: [x1 y1 z1 a1 dx1 dy1 dz1 da1 x2 y2 z2 a2 dx2 dy2 dz2 da2 ...]
%           .tracksFeatIndxCG: Connectivity matrix of features between
%                              frames, after gap closing. Number of rows
%                              = number of track segments in compound
%                              track. Number of columns = number of frames
%                              the compound track spans. Zeros indicate
%                              frames where track segments do not exist
%                              (either because those frames are before the
%                              segment starts or after it ends, or because
%                              of losing parts of a segment.
                newTracks(i).bkgAmp(jj) = detectedNAs(jj).bkg(tracks(i).tracksFeatIndxCG(jj-tracks(i).seqOfEvents(1,1)+1));
                newTracks(i).sigma(jj) = detectedNAs(jj).sigmaX(tracks(i).tracksFeatIndxCG(jj-tracks(i).seqOfEvents(1,1)+1));
            end
            newTracks(i).presence(jj) = true;
            if startNA
                newTracks(i).startingFrame = jj;
                startNA = false;
            end
        end
            
        if isfield(tracks, 'label')
            %% TODO -- what is this?
            newTracks(iTrack).label = tracks(i).label; 
        end
    end
    % go through frames again and fill NaNs with numbers at the gap
    % position
%     masGap=20;
%     for gap = masGap:-1:1;
    jj=newTracks(i).startingFrame;
    gap=0;
    while jj<newTracks(i).endingFrame
        if newTracks(i).presence(jj) && ~isnan(newTracks(i).xCoord(jj))
            % jump to the next broken block
            nNextConsecBlock = find(isnan(newTracks(i).xCoord) & newTracks(i).iFrame>jj,1,'first');
            if isempty(nNextConsecBlock)
                break % there is no gap afterward
            else
                % see if abscence (or gap) is until the end of frame
                % find the next presence after this gap
                nNextNextConsecBlock = find(~isnan(newTracks(i).xCoord) & newTracks(i).iFrame>nNextConsecBlock,1,'first');
                gap = nNextNextConsecBlock-nNextConsecBlock;
                jj=nNextConsecBlock;
            end
        else
            for kk=1:gap
                newTracks(i).xCoord(jj+kk-1) = ((gap+1-kk)*newTracks(i).xCoord(jj-1)+kk*newTracks(i).xCoord(jj+gap))/(gap+1);
                newTracks(i).yCoord(jj+kk-1) = ((gap+1-kk)*newTracks(i).yCoord(jj-1)+kk*newTracks(i).yCoord(jj+gap))/(gap+1);
                newTracks(i).amp(jj+kk-1) = ((gap+1-kk)*newTracks(i).amp(jj-1)+kk*newTracks(i).amp(jj+gap))/(gap+1);
                newTracks(i).bkgAmp(jj+kk-1) = ((gap+1-kk)*newTracks(i).bkgAmp(jj-1)+kk*newTracks(i).bkgAmp(jj+gap))/(gap+1);
            end
            jj=jj+gap;
        end
    end

    if isempty(newTracks(i).startingFrame)
        warning(['startingFrame is empty for track #' num2str(i)])
    end
progressText(i/numel(tracks));
end
end