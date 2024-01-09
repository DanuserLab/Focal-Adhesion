classdef FocalAdhesionSegmentationProcess < SegmentationProcess
    %A process for segmenting focal adhesions
    %Hunter Elliott
    %3/2013
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
    
    methods (Access = public)
        function obj = FocalAdhesionSegmentationProcess(owner,varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = FocalAdhesionSegmentationProcess.getName;
                super_args{3} = @segmentMovieFocalAdhesions;
                if isempty(funParams)
                    funParams = FocalAdhesionSegmentationProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            
            obj = obj@SegmentationProcess(super_args{:});
        end
        
    end
    methods (Static)
        function name = getName()
            name = 'Focal Adhesion Segmentation';
        end
        function h = GUI()
            h= @focalAdhesionSegmentationProcessGUI;
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1:numel(owner.channels_);
            funParams.OutputDirectory = [outputDir  filesep 'adhesion_masks'];
            funParams.SteerableFilterSigma = 250;%Sigma in nm of steerable filter to use in splitting adjacent adhesions
            funParams.OpeningRadiusXY = 0; %Spatial radius in nm of structuring element used in opening.
            funParams.OpeningHeightT = 50; %Temporal "height" in seconds of structuring element used in opening            
            funParams.MinVolTime = 5; %Minimum spatiotemporal "Volume" in micron^2 * seconds of segmented adhesions to retain.
            funParams.BatchMode = false;
        end
    end
end