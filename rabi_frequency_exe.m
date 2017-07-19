function rabi_frequency_exe()
    % rabi_frequency_exe executes the rabi_frequency GUI, setting global
    % parameters.
    % The Pulseblaster used by this program is version SP17.
    
    
    clc

    
    % ensure hardware is not already instantiated
    delete(instrfind)
    daqreset
    if exist('hardware', 'var') == 1 % kill most recent 
        hardware.kill();
        disp('killed old hardware object')
    end
    
    clear all
    close all

    global SPINAPI_DLL_NAME;
    global SPINAPI_DLL_PATH;
    global EXPORTED_DATA_PATH;
    global CLOCK_FREQ;
    global LASER_ON;
    global RF_ON;
    global ALL_OFF;
    global REGION_WIDTH;
    global CAMERA_DELAY;

    % set measurement constants
    REGION_WIDTH = 18;  % 1/2 length of integration region: total region is 36 x 36, ~ 1 um x 1 um
    CLOCK_FREQ = 100;   % this specific model of Pulseblaster (SP17) has 100 MHz clock freq.
    CAMERA_DELAY = 3;   % delay between start of Pulseblaster pulses and camera shutter opening (ns)
    
    % set pulseblaster pins (refer to Pulseblaster API in README folder)
    ALL_OFF = '0';      % hex pin for rf output pulse
    LASER_ON = '1';     % hex pin for laser output pulse (pin 0)
    RF_ON = '2';        % hex pin for rf output pulse (pin 1)

    % set paths
    SPINAPI_DLL_PATH = 'C:\SpinCore\SpinAPI\lib\';
    SPINAPI_DLL_NAME = 'spinapi64';
    EXPORTED_DATA_PATH = '/Exported_Data';
    
    % Choose default command line output for pulse_blaster_gui
    if libisloaded(SPINAPI_DLL_NAME) ~= 1
        loadlibrary(strcat(SPINAPI_DLL_PATH, SPINAPI_DLL_NAME, '.dll'),...
            'C:\SpinCore\SpinAPI\include\spinapi.h',...
            'addheader','C:\SpinCore\SpinAPI\include\pulseblaster.h');
    end
    
    % check if MATLAB wrapper functions (for SpinAPI) exist
    if (exist('./Matlab_SpinAPI', 'dir') == 7)
        addpath('./Matlab_SpinAPI');
    else
        error('Cannot find ./Matlab_SpinAPI folder');
    end
    
    % check if helper functions exist in folder
    if (exist('./Image_Processing', 'dir') == 7)
        addpath('./Image_Processing');
    else
        error('Cannot find ./Image_Processing folder');
    end
    
    % check if exported data folder exists
    pathname = strcat('.', EXPORTED_DATA_PATH);
    if (exist(pathname, 'dir') == 7)
        addpath(pathname);
    else
        error('Cannot find %s folder', pathname);
    end

    % launch GUI
    rabi_frequency_v2();
end

