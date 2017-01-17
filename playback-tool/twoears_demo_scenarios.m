function varargout = twoears_demo_scenarios(varargin)
% TWOEARS_DEMO_SCENARIOS MATLAB code for twoears_demo_scenarios.fig
%      TWOEARS_DEMO_SCENARIOS, by itself, creates a new TWOEARS_DEMO_SCENARIOS or raises the existing
%      singleton*.
%
%      H = TWOEARS_DEMO_SCENARIOS returns the handle to a new TWOEARS_DEMO_SCENARIOS or the handle to
%      the existing singleton*.
%
%      TWOEARS_DEMO_SCENARIOS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TWOEARS_DEMO_SCENARIOS.M with the given input arguments.
%
%      TWOEARS_DEMO_SCENARIOS('Property','Value',...) creates a new TWOEARS_DEMO_SCENARIOS or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before twoears_demo_scenarios_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to twoears_demo_scenarios_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help twoears_demo_scenarios

% Last Modified by GUIDE v2.5 17-Nov-2016 18:14:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @twoears_demo_scenarios_OpeningFcn, ...
                   'gui_OutputFcn',  @twoears_demo_scenarios_OutputFcn, ...
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

% --- Executes just before twoears_demo_scenarios is made visible.
function twoears_demo_scenarios_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to twoears_demo_scenarios (see VARARGIN)

% Choose default command line output for twoears_demo_scenarios
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes twoears_demo_scenarios wait for user response (see UIRESUME)
% uiwait(handles.figure1);

initialise_GUI(hObject, handles);




function initialise_GUI(hObject, handles)

handles.scenarioDir = 'scenarios';
fileList = dir(fullfile(handles.scenarioDir, '*.mat'));

scenarioList = cell(length(fileList), 1);
for n=1:length(fileList)
    scenarioList{n} = fileList(n).name;
end

set(handles.popupmenuScenario, 'String', scenarioList);
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = twoears_demo_scenarios_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function popupmenuScenario_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuScenario (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuScenario.
function popupmenuScenario_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuScenario (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuScenario contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuScenario


% --- Executes on button press in buttonStop.
function buttonStop_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiwait(msgbox('Press Q to stop playback','','modal'));



% --- Executes on button press in buttonPlay.
function buttonPlay_Callback(hObject, eventdata, handles)
% hObject    handle to buttonPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get channel indice
spk1 = str2double(get(handles.editChannel1, 'String'));
spk2 = str2double(get(handles.editChannel2, 'String'));
spk3 = str2double(get(handles.editChannel3, 'String'));
spk4 = str2double(get(handles.editChannel4, 'String'));
spkChannels = [spk1, spk2, spk3, spk4];

% Play the precreated sound
scenarioList = get(handles.popupmenuScenario, 'String');
scenarioIndex = get(handles.popupmenuScenario, 'Value');
scenarioMatFile = fullfile(handles.scenarioDir, scenarioList{scenarioIndex});
uiwait(msgbox(scenarioMatFile,'','modal'));
scmat = load( scenarioMatFile );
playbackScenario( scmat.scenario, [], [], spkChannels );



function editChannel1_Callback(hObject, eventdata, handles)
% hObject    handle to editChannel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editChannel1 as text
%        str2double(get(hObject,'String')) returns contents of editChannel1 as a double


% --- Executes during object creation, after setting all properties.
function editChannel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editChannel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editChannel2_Callback(hObject, eventdata, handles)
% hObject    handle to editChannel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editChannel2 as text
%        str2double(get(hObject,'String')) returns contents of editChannel2 as a double


% --- Executes during object creation, after setting all properties.
function editChannel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editChannel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editChannel3_Callback(hObject, eventdata, handles)
% hObject    handle to editChannel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editChannel3 as text
%        str2double(get(hObject,'String')) returns contents of editChannel3 as a double


% --- Executes during object creation, after setting all properties.
function editChannel3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editChannel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editChannel4_Callback(hObject, eventdata, handles)
% hObject    handle to editChannel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editChannel4 as text
%        str2double(get(hObject,'String')) returns contents of editChannel4 as a double


% --- Executes during object creation, after setting all properties.
function editChannel4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editChannel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
