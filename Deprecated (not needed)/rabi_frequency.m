function varargout = rabi_frequency(varargin)
% RABI_FREQUENCY MATLAB code for rabi_frequency.fig
%      RABI_FREQUENCY, by itself, creates a new RABI_FREQUENCY or raises the existing
%      singleton*.
%
%      H = RABI_FREQUENCY returns the handle to a new RABI_FREQUENCY or the handle to
%      the existing singleton*.
%
%      RABI_FREQUENCY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RABI_FREQUENCY.M with the given input arguments.
%
%      RABI_FREQUENCY('Property','Value',...) creates a new RABI_FREQUENCY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rabi_frequency_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rabi_frequency_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rabi_frequency

% Last Modified by GUIDE v2.5 12-Jul-2017 15:41:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rabi_frequency_OpeningFcn, ...
                   'gui_OutputFcn',  @rabi_frequency_OutputFcn, ...
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

% --- Executes just before rabi_frequency is made visible.
function rabi_frequency_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rabi_frequency (see VARARGIN)

% Choose default command line output for rabi_frequency
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using rabi_frequency.
if strcmp(get(hObject,'Visible'),'off')
    plot(rand(5));
end

% UIWAIT makes rabi_frequency wait for user response (see UIRESUME)
% uiwait(handles.figure1);





% --- Outputs from this function are returned to the command line.
function varargout = rabi_frequency_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;





function num = getN(tag)
% getN acts similar to get(handles.___, 'Value') except the result is
% immediately cast to a double.
    num = str2double(get(tag, 'Value'));


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % check parameters
    if t_rf_min >= t_rf_min
        error('invalid microwave time inputs')
    elseif cycles < 1
        error('number of cycles must be a positive integer')
    end
    
    % get pulse durations
    t_laser_val = getN(handles.t_laser);
    t_rf_min_val = getN(handles.t_rf_min);
    t_rf_max_val = getN(handles.t_rf_max);
    samples_val = getN(handles.samples);
    cycles_val = getN(handles.cycles);
    rf_durations = linspace(t_rf_min_val, t_rf_max_val, samples_val);
    
    % program and execute Rabi measurement sequence
    pl_array = rabi_pulse_sequence(t_laser_val, rf_durations, cycles_val);
    
    % plot pl intensity vs rf pulse duration - should expect to see sinusoid
    max_pl = max(pl_array);
    normalized_pl = pl_array / max_pl;
    plot(rf_durations, normalized_pl);
    xaxis('RF pulse duration (ns)');
    yaxis('Arbitrary units of intensity');
    title('Rabi sequence');
    
    % calculate frequency and sinusoid fit
    [fit, freq] = fit_sinusoid(rf_durations, normalized_pl];
    set(handles.freq, 'Value', num2str(freq));
    
    
    
% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});



function t_laser_Callback(hObject, eventdata, handles)
% hObject    handle to t_laser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_laser as text
%        str2double(get(hObject,'String')) returns contents of t_laser as a double


% --- Executes during object creation, after setting all properties.
function t_laser_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_laser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function t_rf_min_Callback(hObject, eventdata, handles)
% hObject    handle to t_rf_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_rf_min as text
%        str2double(get(hObject,'String')) returns contents of t_rf_min as a double


% --- Executes during object creation, after setting all properties.
function t_rf_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_rf_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function t_rf_max_Callback(hObject, eventdata, handles)
% hObject    handle to t_rf_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_rf_max as text
%        str2double(get(hObject,'String')) returns contents of t_rf_max as a double


% --- Executes during object creation, after setting all properties.
function t_rf_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_rf_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function samples_Callback(hObject, eventdata, handles)
% hObject    handle to samples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of samples as text
%        str2double(get(hObject,'String')) returns contents of samples as a double

    % round modified value
    cur_val = getN(handles.samples, 'Value');
    new_val = num2str(ceil(cur_val));
    set(handles.samples, 'Value', new_val);


% --- Executes during object creation, after setting all properties.
function samples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cycles_Callback(hObject, eventdata, handles)
% hObject    handle to cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cycles as text
%        str2double(get(hObject,'String')) returns contents of cycles as a double

    % round modified value
    cur_val = getN(handles.cycles, 'Value');
    new_val = num2str(ceil(cur_val));
    set(handles.cycles, 'Value', new_val);


% --- Executes during object creation, after setting all properties.
function cycles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function t_rf_min_Callback(hObject, eventdata, handles)
% hObject    handle to t_rf_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_rf_min as text
%        str2double(get(hObject,'String')) returns contents of t_rf_min as a double


% --- Executes during object creation, after setting all properties.
function t_rf_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_rf_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function t_rf_max_Callback(hObject, eventdata, handles)
% hObject    handle to t_rf_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_rf_max as text
%        str2double(get(hObject,'String')) returns contents of t_rf_max as a double


% --- Executes during object creation, after setting all properties.
function t_rf_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_rf_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
