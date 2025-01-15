function saturateImageColormap(handle,satPct)
%SATURATEIMAGECOLORMAP adjusts the colormap for the specified image so that it is saturated by the specified amount 
%
% success = saturateImageColormap(handle,satPct)
%  
%   handle - axes handle with image to saturate
%   satPct - the percentage of pixels to saturate. (Half this amount will
%            be saturated on the low end, half on the high end)
%
% Hunter Elliott
% 8/24/2012
%
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

if nargin < 1 || isempty(handle)
    handle = gca;
end

if nargin < 2 || isempty(satPct)
    satPct = 1;
end

imDat = double(getimage(handle));
caxis(prctile(imDat(:),[satPct/2 (100-satPct/2)]));




