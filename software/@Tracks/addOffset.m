function obj=addOffset(obj,X,Y,Z)
   % Philippe Roudot 2017
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
   if(length(obj)==1)
     obj.x=obj.x+X;
     obj.y=obj.y+Y;
     obj.z=obj.z+Z;
   else
     arrayfun(@(o) o.addOffset(X,Y,Z),obj,'unif',false);
   end
 end
