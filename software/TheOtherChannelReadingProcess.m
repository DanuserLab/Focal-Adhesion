classdef TheOtherChannelReadingProcess < DataProcessingProcess
    methods (Access = public)
        function obj = TheOtherChannelReadingProcess(owner,varargin)
%             obj = obj@DataProcessingProcess(owner, TheOtherChannelReadingProcess.getName);
%             obj.funName_ = @readTheOtherChannelFromTracks;
%             obj.funParams_ = TheOtherChannelReadingProcess.getDefaultParams(owner,varargin{1});
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
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir', owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = TheOtherChannelReadingProcess.getName;
                super_args{3} = @readTheOtherChannelFromTracks;
                
                if isempty(funParams)
                    funParams = TheOtherChannelReadingProcess.getDefaultParams(owner,outputDir);
                end
                
                super_args{4} = funParams;
            end
            
            obj = obj@DataProcessingProcess(super_args{:});
        end
        
        function output = loadChannelOutput(obj, iChan, varargin)
            outputList = {};
            nOutput = length(outputList);

            ip.addRequired('iChan',@(x) obj.checkChanNum(x));
            ip.addOptional('iOutput',1,@(x) ismember(x,1:nOutput));
            ip.addParamValue('output','',@(x) all(ismember(x,outputList)));
            ip.addParamValue('useCache',false,@islogical);
            ip.parse(iChan,varargin{:})
    
            s = cached.load(obj.outFilePaths_{iChan},'-useCache',ip.Results.useCache);

            output = s.Imean;          
        end
    end
    methods (Static)
        function name = getName()
            name = 'The Other Channel Reading';
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            adhAnalProc = owner.getProcess(owner.getProcessIndex('AdhesionAnalysisProcess'));
            pAnal=adhAnalProc.funParams_;
            
            ip.addOptional('ChannelIndex',pAnal.ChannelIndex,...
               @(x) all(owner.checkChanNum(x)));
            ip.addOptional('iChanSlave',setdiff(1:numel(owner.channels_),pAnal.ChannelIndex),...
               @(x) all(owner.checkChanNum(x)));
            ip.parse(owner,varargin{:})
            
            % Set default parameters
            funParams.OutputDirectory = [ip.Results.outputDir filesep 'TheOtherChannelReading'];
            funParams.ChannelIndex = ip.Results.ChannelIndex;
            funParams.iChanSlave = ip.Results.iChanSlave;
        end
        
        function h = GUI()
            h = @theOtherChannelReadingProcessGUI;
        end
    end
end
