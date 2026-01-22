function varargout = mfFigureExport(figHan,fileName,varargin)
%MFFIGUREEXPORT multi-format figure export to .tif, .eps and .fig
% 
% mfFigureExport(figHan,fileName)
% success = mfFigureExport(figHan,fileName,...)
%
%   Input:
%
%       figHan - handle to figure to export. Optional. Default is current
%       figure.
%
%       fileName - the file name to export to WITHOUT file extension.
%       Required.
%
%   Parameter/Value pairs:
%
%       'MakeTif' - If true, export to .tif. Default true.
%       'MakeEps' - If true, export to .eps. Default true.
%       'MakeFig' - If true, export to matlab .fig. Default true.
%       'DPI' - DPI to export to eps and tif in. Default is 300.
%       'TifOptions' - Cell array of options to pass to print command when
%           exporting to .tif. Default = {'-dtiff'}
%       'EpsOptions' - Cell array of options to pass to print command when
%           exporting to .eps. Default = {'-depsc2'}
%
%
%   Output:
%
%       success - 1x3 logical which is true the elements of which are true
%       if if export to tif, eps and fig respectively were successful.
%
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

%Hunter Elliott
%4/2013

ip = inputParser;
ip.addRequired('fileName',@ischar);
ip.addOptional('figHan',gcf,@(x)(ishghandle(x)));
ip.addParamValue('MakeTif',true,@islogical);
ip.addParamValue('MakeEps',true,@islogical);
ip.addParamValue('MakeFig',true,@islogical);
ip.addParamValue('TifOptions',{'-dtiff'},@iscell);
ip.addParamValue('EpsOptions',{'-depsc2'},@iscell);
ip.addParamValue('DPI',300,@isposint);

ip.parse(fileName,figHan,varargin{:});
p = ip.Results;

resStr = ['-r' num2str(p.DPI)];%String specifying output resolution in DPI

success = false(1,3);

try        
    print(figHan,[fileName '.tif'],p.TifOptions{:},resStr)
    success(1) = true;
catch err
    warning('MFFIGUREEXPORT:expFailure',['Error exporting to tif:' err.message])
end
try
    print(figHan,[fileName '.eps'],p.EpsOptions{:},resStr);
    success(2) = true;
catch err
    warning('MFFIGUREEXPORT:expFailure',['Error exporting to eps:' err.message])
end
try
    hgsave(figHan,[fileName '.fig']);
    success(3) = true;
catch err
    warning('MFFIGUREEXPORT:expFailure',['Error exporting to fig:' err.message])
end

if nargout > 0
    varargout{1} = success;
end