function idx = getSplitIdx(obj,msM)
    if(nargin < 2)
        msM = obj.getMergeSplitMatrix;
    end
    splitM = msM(msM(:,2) == 1,:);
    idx = sub2ind([obj.totalSegments obj.numTimePoints],splitM(:,3:4),[splitM(:,1) splitM(:,1)-1])';
end
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
