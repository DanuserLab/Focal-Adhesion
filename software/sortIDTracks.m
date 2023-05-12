function         [idGroup1Selected,idGroup2Selected,idGroup3Selected,idGroup4Selected,idGroup5Selected,idGroup6Selected,...
            idGroup7Selected,idGroup8Selected,idGroup9Selected] = ...
            sortIDTracks(idTracks,iGroup,outputCellArray)
    % for duplicate ids that were assigned to multiple different groups,
    % assign them to the latest group
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
    [uniqIdTracks, ia, ic]=unique(idTracks,'stable');
    uniqIGroup = zeros(size(uniqIdTracks));
    for jj=1:numel(ia)
        laterIdx = find(ic==jj,1,'last');
        uniqIGroup(jj)=iGroup(laterIdx);
    end
    idGroup1Selected = uniqIdTracks(uniqIGroup==1);
    idGroup2Selected = uniqIdTracks(uniqIGroup==2);
    idGroup3Selected = uniqIdTracks(uniqIGroup==3);
    idGroup4Selected = uniqIdTracks(uniqIGroup==4);
    idGroup5Selected = uniqIdTracks(uniqIGroup==5);
    idGroup6Selected = uniqIdTracks(uniqIGroup==6);
    idGroup7Selected = uniqIdTracks(uniqIGroup==7);
    idGroup8Selected = uniqIdTracks(uniqIGroup==8);
    idGroup9Selected = uniqIdTracks(uniqIGroup==9);
    if nargin>2 && outputCellArray
        idGroup1Selected = {idGroup1Selected,idGroup2Selected,idGroup3Selected,idGroup4Selected,idGroup5Selected,idGroup6Selected,....
                                    idGroup7Selected,idGroup8Selected,idGroup9Selected};
    end
end      