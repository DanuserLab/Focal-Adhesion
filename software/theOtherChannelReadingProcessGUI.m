function varargout = theOtherChannelReadingProcessGUI(varargin)
% THEOTHERCHANNELREADINGPROCESSGUI M-file for theOtherChannelReadingProcessGUI.fig
%      THEOTHERCHANNELREADINGPROCESSGUI, by itself, creates a new THEOTHERCHANNELREADINGPROCESSGUI or raises the existing
%      singleton*.
%
%      H = THEOTHERCHANNELREADINGPROCESSGUI returns the handle to a new THEOTHERCHANNELREADINGPROCESSGUI or the handle to
%      the existing singleton*.
%
%      THEOTHERCHANNELREADINGPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in THEOTHERCHANNELREADINGPROCESSGUI.M with the given input arguments.
%
%      THEOTHERCHANNELREADINGPROCESSGUI('Property','Value',...) creates a new THEOTHERCHANNELREADINGPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before theOtherChannelReadingProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to theOtherChannelReadingProcessGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
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

% Edit the above text to modify the response to help theOtherChannelReadingProcessGUI

% Last Modified by GUIDE v2.5 26-Oct-2017 16:20:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @theOtherChannelReadingProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @theOtherChannelReadingProcessGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before theOtherChannelReadingProcessGUI is made visible.
function theOtherChannelReadingProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% Set up dark current paths
if ~all(cellfun(@isempty,userData.crtProc.inFilePaths_(:)))
    set(handles.listbox_darkCurrentChannels, 'String', ...
        userData.crtProc.inFilePaths_(1,funParams.iChanSlave ));
end
set(handles.listbox_darkCurrentChannels, 'Value',1);

userData.userDir=userData.MD.outputDirectory_;

% Update user data and GUI data
handles.output = hObject;
set(hObject, 'UserData', userData);
guidata(hObject, handles);

uicontrol(handles.pushbutton_done)


% --- Outputs from this function are returned to the command line.
function varargout = theOtherChannelReadingProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
channelProps = get (handles.listbox_selectedChannels, {'Userdata','String'});
channelIndex=channelProps{1};
channelString=channelProps{2};
slaveChannels = get(handles.listbox_darkCurrentChannels, 'String');
% Check user input
if isempty(slaveChannels)
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end
iSlaveChannels=find(strcmp(userData.crtProc.inFilePaths_,slaveChannels));


% Save old process settings (for recovery if sanity check fails)
funParams = userData.crtProc.funParams_;

% Apply new channel index and new shade images for sanity check
funParams.iChanMaster = channelIndex; 
funParams.iChanSlave = iSlaveChannels; 

parseProcessParams(userData.crtProc,funParams);

% Set parameters
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes on button press in pushbutton_deleteDarkCurrentChannel.
function pushbutton_deleteDarkCurrentChannel_Callback(hObject, eventdata, handles)
% Call back function of 'delete' button
contents = get(handles.listbox_darkCurrentChannels,'String');
% Return if list is empty
if isempty(contents)
    return;
end
num = get(handles.listbox_darkCurrentChannels,'Value');

% Delete selected item
contents(num) = [ ];

% Refresh listbox
set(handles.listbox_darkCurrentChannels,'String',contents);
% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (num>length(contents) && num>1)
    set(handles.listbox_darkCurrentChannels,'Value',length(contents));
end

guidata(hObject, handles);

% --- Executes on button press in pushbutton_addDarkCurrentChannel.
function pushbutton_addDarkCurrentChannel_Callback(hObject, eventdata, handles)
% Call back of 'add' button
% Directories can be the same, no need to check directory pool
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
set(handles.listbox_darkCurrentChannels, 'Value',1)

path = uigetdir(userData.userDir, 'Add Channels ...');
if path == 0
    return;
end
% Input validation function ...
% Get current list
contents = get(handles.listbox_darkCurrentChannels,'String');

% Add current formula to the listbox
contents{end+1} = path;
set(handles.listbox_darkCurrentChannels,'string',contents);

% Set user directory
sepDir = regexp(path, filesep, 'split');
dir = sepDir{1};
for i = 2: length(sepDir)-1
    dir = [dir filesep sepDir{i}];
end
userData.userDir = dir;

set(handles.figure1, 'Userdata', userData)
guidata(hObject, handles);


% --- Executes on button press in checkbox_gaussianfilter.
function checkbox_gaussianfilter_Callback(hObject, eventdata, handles)

if get(hObject, 'Value'), state='on'; else state='off'; end
set([handles.text_filters1 handles.edit_sigma], 'Enable',state);

% --- Executes on button press in pushbutton_up.
function pushbutton_up_Callback(hObject, eventdata, handles)

% call back of 'Up' button
id = get(handles.listbox_darkCurrentChannels,'Value');
contents = get(handles.listbox_darkCurrentChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

set(handles.listbox_darkCurrentChannels, 'string', contents);
set(handles.listbox_darkCurrentChannels, 'value', id-1);

% --- Executes on button press in pushbutton_down.
function pushbutton_down_Callback(hObject, eventdata, handles)

% Call back of 'Down' button
id = get(handles.listbox_darkCurrentChannels,'Value');
contents = get(handles.listbox_darkCurrentChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

set(handles.listbox_darkCurrentChannels, 'string', contents);
set(handles.listbox_darkCurrentChannels, 'value', id+1);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_done (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end
