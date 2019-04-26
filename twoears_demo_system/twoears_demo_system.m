function varargout = twoears_demo_system(varargin)
% twoears_demo_system MATLAB code for twoears_demo_system.fig
%      twoears_demo_system, by itself, creates a new twoears_demo_system or raises the existing
%      singleton*.
%
%      H = twoears_demo_system returns the handle to a new twoears_demo_system or the handle to
%      the existing singleton*.
%
%      twoears_demo_system('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in twoears_demo_system.M with the given input arguments.
%
%      twoears_demo_system('Property','Value',...) creates a new twoears_demo_system or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before twoears_demo_system_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to twoears_demo_system_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help twoears_demo_system

% Last Modified by GUIDE v2.5 26-Apr-2019 23:25:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @twoears_demo_system_OpeningFcn, ...
                   'gui_OutputFcn',  @twoears_demo_system_OutputFcn, ...
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


% --- Executes just before twoears_demo_system is made visible.
function twoears_demo_system_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to twoears_demo_system (see VARARGIN)

% Choose default command line output for twoears_demo_system
handles.output = hObject;

% Create demo controller
handles.ctrl = DemoController(hObject);

% Save structure
guidata(hObject, handles);


%% UIWAIT makes twoears_demo_system wait for user response (see UIRESUME)
uiwait(handles.figureSystemDemo);


% --- Outputs from this function are returned to the command line.
function varargout = twoears_demo_system_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;


% --- Executes on button press in pushbuttonDoLocalisation.
function pushbuttonDoLocalisation_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDoLocalisation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Disable the button during localisation
set(hObject, 'Enable', 'off');
set(handles.pushbuttonStop, 'Enable', 'on');
set(handles.checkboxFrontalPlane, 'Enable', 'off');
%set(handles.checkboxHeadRotation, 'Enable', 'off');
% Start blackboard
try
   handles.ctrl.startBlackboard;
catch ME
   close all;
   rethrow(ME);
end

set(hObject, 'Enable', 'on');
set(handles.pushbuttonStop, 'Enable', 'off');
set(handles.checkboxFrontalPlane, 'Enable', 'on');
set(handles.checkboxHeadRotation, 'Enable', 'on');

% --- Executes on button press in checkboxHeadRotation.
function checkboxHeadRotation_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxHeadRotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxHeadRotation
handles.ctrl.setSolveConfusion(get(hObject,'Value'));


% --- Executes on button press in checkboxFrontalPlane.
function checkboxFrontalPlane_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFrontalPlane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFrontalPlane
% handles.ctrl.bRotateAtEnd = get(hObject,'Value');
handles.ctrl.bFrontPlaneOnly = get(hObject,'Value');


% --- Executes during object creation, after setting all properties.
function editGenomixPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editGenomixPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonStop.
function pushbuttonStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ctrl.stop;
%set(hObject, 'Enable', 'off');
%set(handles.pushbuttonDoLocalisation, 'Enable', 'on');

set(handles.checkboxFrontalPlane, 'Enable', 'on');
set(handles.checkboxHeadRotation, 'Enable', 'on');


% --- Executes on selection change in popupmenuRunningMode.
function popupmenuRunningMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuRunningMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuRunningMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuRunningMode
% Determine the selected data set.
val = get(hObject,'Value');

% Set current data to the selected data set.
switch val
    case 1 % top-down localization
       handles.ctrl.runningMode = 'frequencyMasked loc';
    case 2 % segregated identification
       handles.ctrl.runningMode = 'segregated identification';
    case 3 % both
       handles.ctrl.runningMode = 'both';
end



% --- Executes during object creation, after setting all properties.
function popupmenuRunningMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuRunningMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxNsrcsGroundtruth.
function checkboxNsrcsGroundtruth_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxNsrcsGroundtruth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxNsrcsGroundtruth

handles.ctrl.nsrcsGroundtruth = get( hObject, 'Value' );


% --- Executes on button press in checkboxUseAdream.
function checkboxUseAdream_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseAdream (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseAdream

handles.ctrl.bUseAdream = get( hObject, 'Value' );


% --- Executes on button press in checkboxFsInitSegId.
function checkboxFsInitSegId_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxFsInitSegId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxFsInitSegId

handles.ctrl.bFsInitSI = get( hObject, 'Value' );


% --- Executes on button press in checkboxUseMaxLatDistRot.
function checkboxUseMaxLatDistRot_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseMaxLatDistRot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseMaxLatDistRot

handles.ctrl.bMaxLatDistRotate = get( hObject, 'Value' );


% --- Executes on button press in checkboxUseTestSet.
function checkboxUseTestSet_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseTestSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseTestSet
handles.ctrl.bTestSet = get( hObject, 'Value' );
