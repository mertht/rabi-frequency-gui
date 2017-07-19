function varargout = rabi_frequency_v2(varargin)
% RABI_FREQUENCY_V2 MATLAB code for rabi_frequency_v2.fig
%      RABI_FREQUENCY_V2, by itself, creates a new RABI_FREQUENCY_V2 or raises the existing
%      singleton*.
%
%      H = RABI_FREQUENCY_V2 returns the handle to a new RABI_FREQUENCY_V2 or the handle to
%      the existing singleton*.
%
%      RABI_FREQUENCY_V2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RABI_FREQUENCY_V2.M with the given input arguments.
%
%      RABI_FREQUENCY_V2('Property','Value',...) creates a new RABI_FREQUENCY_V2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rabi_frequency_v2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rabi_frequency_v2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rabi_frequency_v2

% Last Modified by GUIDE v2.5 17-Jul-2017 10:58:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rabi_frequency_v2_OpeningFcn, ...
                   'gui_OutputFcn',  @rabi_frequency_v2_OutputFcn, ...
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


% --- Executes just before rabi_frequency_v2 is made visible.
function rabi_frequency_v2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rabi_frequency_v2 (see VARARGIN)

% Choose default command line output for rabi_frequency_v2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rabi_frequency_v2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


%% FINAL CHANGES TO GUI
axes(handles.sinusoid)
title('Rabi Oscillation')
xlabel('RF Pulse Duration (ns)')
ylabel('Normalized PL (arb.)')


% --- Outputs from this function are returned to the command line.
function varargout = rabi_frequency_v2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
















% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of start
    global EXPORTED_DATA_PATH;
    clc
    cla(handles.sinusoid)
    cla(handles.pic_frame)
    
    % program and execute Rabi measurement sequence
    [image_array, rf_durations, pl_array] = rabi_pulse_sequence(handles);
    
    % save data and images to .mat files
    
    save(strcat(EXPORTED_DATA_PATH, 'image_array.mat'), 'image_array');
    save(strcat(EXPORTED_DATA_PATH, 'rf_durations.mat'), 'rf_durations');
    save(strcat(EXPORTED_DATA_PATH, 'pl_array.mat'), 'pl_array');

    process_rabi_data(handles);
    
    
function process_rabi_data(handles)
    [image_array_mat] = load('image_array.mat');
    [pl_array_mat] = load('pl_array.mat');
    [rf_durations_mat] = load('rf_durations.mat');

    % get data from loaded values
    image_array = image_array_mat.image_array;
    pl_array = pl_array_mat.pl_array;
    rf_durations = rf_durations_mat.rf_durations;
    
    % calculate and set empirical Rabi frequency
    [~,rabi_freq] = fit_sinusoid(rf_durations, pl_array);
    output = strcat(num2str(rabi_freq), ' GHz');
    set(handles.freq_output, 'String', output);

    









% --- Executes during object creation, after setting all properties.
function t_laser_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_laser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



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



function cycles_Callback(hObject, eventdata, handles)
% hObject    handle to cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cycles as text
%        str2double(get(hObject,'String')) returns contents of cycles as a double
    cur_val = getN(handles.cycles);
    new_val = num2str(ceil(cur_val));
    set(handles.cycles, 'String', new_val);


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



function samples_Callback(hObject, eventdata, handles)
% hObject    handle to samples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of samples as text
%        str2double(get(hObject,'String')) returns contents of samples as a double
    cur_val = getN(handles.samples);
    new_val = num2str(ceil(cur_val));
    set(handles.samples, 'String', new_val);


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


% --- Executes on selection change in ccd_size.
function ccd_size_Callback(hObject, eventdata, handles)
% hObject    handle to ccd_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ccd_size contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ccd_size


% --- Executes during object creation, after setting all properties.
function ccd_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ccd_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in binning.
function binning_Callback(hObject, eventdata, handles)
% hObject    handle to binning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns binning contents as cell array
%        contents{get(hObject,'Value')} returns selected item from binning


% --- Executes during object creation, after setting all properties.
function binning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to binning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rf_frequency_Callback(hObject, eventdata, handles)
% hObject    handle to rf_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rf_frequency as text
%        str2double(get(hObject,'String')) returns contents of rf_frequency as a double


% --- Executes during object creation, after setting all properties.
function rf_frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rf_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rf_power_Callback(hObject, eventdata, handles)
% hObject    handle to rf_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rf_power as text
%        str2double(get(hObject,'String')) returns contents of rf_power as a double


% --- Executes during object creation, after setting all properties.
function rf_power_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rf_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function t_laser_Callback(hObject, eventdata, handles)
% hObject    handle to t_laser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_laser as text
%        str2double(get(hObject,'String')) returns contents of t_laser as a double


% --- Executes on button press in close_all.
function close_all_Callback(hObject, eventdata, handles)
% hObject    handle to close_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close all
