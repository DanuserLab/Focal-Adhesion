function varargout = adhesionClassificationProcessGUI(varargin)
% focalAdhesionAnalysisProcessGUI M-file for adhesionClassificationProcessGUI.fig
%      focalAdhesionAnalysisProcessGUI, by itself, creates a new adhesionClassificationProcessGUI or raises the existing
%      singleton*.
%
%      H = adhesionClassificationProcessGUI returns the handle to a new adhesionClassificationProcessGUI or the handle to
%      the existing singleton*.
%
%      adhesionClassificationProcessGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in focalAdhesionAnalysisProcessGUI.M with the given input arguments.
%
%      adhesionClassificationProcessGUI('Property','Value',...) creates a new adhesionClassificationProcessGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before adhesionClassificationProcessGUI gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to adhesionClassificationProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help adhesionClassificationProcessGUI

% Copied from FocalAdhesionAnalysisProcessGUI.m

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @adhesionClassificationProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @adhesionClassificationProcessGUI_OutputFcn, ...
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


% --- Executes just before focalAdhesionAnalysisProcessGUI is made visible.
function adhesionClassificationProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set default parameters
userData = get(handles.figure1, 'UserData');
funParams = userData.crtProc.funParams_;

% Set-up parameters
                        
% Set edit strings/numbers

% Set edit strings/numbers
% for paramName = userData.checkBoxes
%     set(handles.(['checkbox_' paramName{1}]), 'Value', funParams.(paramName{1}));
% end

% Update GUI user data
handles.output = hObject;
set(hObject, 'UserData', userData);
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = adhesionClassificationProcessGUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(~, ~, handles)
% Delete figure
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, ~, handles)
% Notify the package GUI that the setting panel is closed
userData = get(handles.figure1, 'UserData');

delete(userData.helpFig(ishandle(userData.helpFig))); 

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

% Check user input
if isempty(get(handles.listbox_selectedChannels, 'String'))
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end
funParams.ChannelIndex = get(handles.listbox_selectedChannels, 'Userdata');

% Get numerical parameters
funParams.autoLabeling = get(handles.checkbox_autoLabeling, 'Value');
funParams.manLabeling = get(handles.checkbox_manLabeling, 'Value');
funParams.useSimpleClassification = get(handles.checkbox_useSimpleFiltering, 'Value');

kk=0;
labelData=[];
if ~isempty(get(handles.edit_sampleGroup1, 'String'))
    kk=kk+1;
    labelData{kk}=get(handles.edit_sampleGroup1, 'String');
end
if ~isempty(get(handles.edit_sampleGroup2, 'String'))
    kk=kk+1;
    labelData{kk}=get(handles.edit_sampleGroup2, 'String');
end
if ~isempty(get(handles.edit_sampleGroup3, 'String'))
    kk=kk+1;
    labelData{kk}=get(handles.edit_sampleGroup3, 'String');
end
funParams.labelData = labelData;

processGUI_ApplyFcn(hObject, eventdata, handles, funParams);


% --- Executes on button press in pushbutton_done.
function pushbutton_sampleGroup1_Callback(hObject, eventdata, handles)
[file, path] = uigetfile({'*.mat;*.MAT',...
    'Mat files (*.mat)'},...
    'Select the file containing selectedGroups');
if ~isequal(file, 0) && ~isequal(path, 0)
    set(handles.edit_sampleGroup1,'String',[path file]);
end

% --- Executes on button press in pushbutton_done.
function pushbutton_sampleGroup2_Callback(hObject, eventdata, handles)
[file, path] = uigetfile({'*.mat;*.MAT',...
    'Mat files (*.mat)'},...
    'Select the file containing selectedGroups');
if ~isequal(file, 0) && ~isequal(path, 0)
    set(handles.edit_sampleGroup2,'String',[path file]);
end
% --- Executes on button press in pushbutton_done.
function pushbutton_sampleGroup3_Callback(hObject, eventdata, handles)
[file, path] = uigetfile({'*.mat;*.MAT',...
    'Mat files (*.mat)'},...
    'Select the file containing selectedGroups');
if ~isequal(file, 0) && ~isequal(path, 0)
    set(handles.edit_sampleGroup3,'String',[path file]);
end


function useSimpleFiltering_Callback(hObject, eventdata, handles)
% hObject    handle to useLcurve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
useSimpleFiltering=get(handles.checkbox_useSimpleFiltering,{'UserData','Value'});
if useSimpleFiltering{2}
    set(handles.checkbox_autoLabeling,'Enable','off');
    set(handles.checkbox_manLabeling,'Enable','off');
else
    set(handles.checkbox_autoLabeling,'Enable','on');
    set(handles.checkbox_manLabeling,'Enable','on');
end
