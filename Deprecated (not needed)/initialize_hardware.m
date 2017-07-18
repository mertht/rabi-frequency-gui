function [vid , s] = initialize_hardware(binning_index, ccd_size_index, exposure_time)
    %% SET UP RF SWEEPER
    
    rf_sweeper = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 19);

    % Create the GPIB object if it does not exists
    if isempty(rf_sweeper)
        rf_sweeper = gpib('NI', 0, 19);    %this is the key line. works without
                                % %the rest unless program halts or something
    else
        fclose(rf_sweeper);
        rf_sweeper = rf_sweeper(1);
    end
    
    fopen(rf_sweeper);    %%Connect to rf generator object, rf_sweeper. 
    set(rf_sweeper, 'Timeout', 2);

    fprintf(rf_sweeper, 'PS0');                              % Sets RF power on
    fprintf(rf_sweeper, 'CW %d GZ', rf_frequency);           % Sets CW frequency 
    fprintf(rf_sweeper, 'PL %d DB', rf_power);               % Sets the power level 
    fprintf(rf_sweeper, 'PS1');                              % Sets RF power off
    
    %% SET UP CCD AREA
    bSize = [1 2 4]; % possible camera binning options
    binning = bSize(binning_index);

    c_size = [128 256 512 1024 2048]; % possible image size options
    ccd_size = c_size(ccd_size_index);

    if binning*ccd_size > 2048 % if binning * ccd area is greater than total camera pixel number
        error('invalid image size requested. check binning and ccd size.')
    end
    
    imagingM = {'MONO16_2048x2048_FastMode','MONO16_BIN2x2_1024x1024_FastMode','MONO16_BIN4x4_512x512_FastMode'};
    imagingMode = imagingM{binning_index};
 
    % region of interest (intensity sampling region)    
    ROIPosition = [2048/binning/2 - ccd_size/2 2048/binning/2 - ccd_size/2 ccd_size ccd_size];
    
     %% INITIALIZE VIDEO OBJECT
    vid                     = videoinput('hamamatsu', 1, imagingMode);
    src                     = getselectedsource(vid); 
    
    src.ExposureTime        = exposure_time; % assign exposure time
    kinTime = exposure_time + ccd_size/(2048/binning)*10E-3; % total time to take an image (inc. readout)
    
    vid.FramesPerTrigger    = 1; 
    vid.TriggerRepeat       = 1; % one image per trigger
    
    triggerconfig(vid, 'hardware', 'RisingEdge', 'EdgeTrigger');
    vid.ROIPosition         = ROIPosition; 
    
    
    %% INITIALZE DAQ
    s = daq.createSession('ni');
    addCounterOutputChannel(s,'Dev1', 1, 'PulseGeneration'); % camera
    
    daq_camera_trigger_duty_cycle          = 0.50; % duty cycle of camera trigger
    daq_camera_trigger_inital_delay        = 0.0005;
    daq_camera_trigger_frequency           = 1/kinTime; 
    
    daq_rate                               = 50000; % daq read/write rate
    daq_duration                           = kinTime; % time daq is on
    
    % % print settings to daq instance
    s.Rate                                 = daq_rate;
    s.DurationInSeconds                    = daq_duration;
    
    % % set up camera trigger
    ch                                     = s.Channels(1);
    ch.InitialDelay                        = daq_camera_trigger_inital_delay;
    ch.Frequency                           = daq_camera_trigger_frequency;
    ch.DutyCycle                           = daq_camera_trigger_duty_cycle;
    
end