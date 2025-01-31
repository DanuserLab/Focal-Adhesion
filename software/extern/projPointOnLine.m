function point = projPointOnLine(point, line)
%PROJPOINTONLINE Project of a point orthogonally onto a line
%
%   PT2 = projPointOnLine(PT, LINE).
%   Computes the (orthogonal) projection of point PT onto the line LINE.
%   
%   Function works also for multiple points and lines. In this case, it
%   returns multiple points.
%   Point PT1 is a [N*2] array, and LINE is a [N*4] array (see createLine
%   for details). Result PT2 is a [N*2] array, containing coordinates of
%   orthogonal projections of PT1 onto lines LINE.
%
%   Example
%     line = [0 2  2 1];
%     projPointOnLine([3 1], line)
%     ans = 
%          2   3
%
%   See also:
%   lines2d, points2d, isPointOnLine, linePosition
%
%   ---------
%   author : David Legland 
%   INRA - TPV URPOI - BIA IMASTE
%   created the 07/04/2005.
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

%   HISTORY
%   2005-08-06 correct bug when several points were passed as param.
%   2012-08-23 remove repmats

% direction vector of the line
vx = line(:, 3);
vy = line(:, 4);

% difference of point with line origin
dx = point(:,1) - line(:,1);
dy = point(:,2) - line(:,2);

% Position of projection on line, using dot product
tp = (dx .* vx + dy .* vy ) ./ (vx .* vx + vy .* vy);

% convert position on line to cartesian coordinates
point = [line(:,1) + tp .* vx, line(:,2) + tp .* vy];
