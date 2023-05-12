function varargout = FocalAdhesionPackageGUI(varargin)
% Launch the GUI for the Focal Adhesion Package
%
% This function calls the generic packageGUI function, passes all its input
% arguments and returns all output arguments of packageGUI
%
%
% Copyright (C) 2023, Danuser Lab - UTSouthwestern 
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

% Andrew R. Jamieson - Feb 2017

if nargin>0 && isa(varargin{1},'MovieList')
    varargout{1} = packageGUI('FocalAdhesionPackage',...
        [varargin{1}.getMovies{:}],varargin{2:end},'ML',varargin{1});
else
    varargout{1} = packageGUI('FocalAdhesionPackage', varargin{:});
end

end