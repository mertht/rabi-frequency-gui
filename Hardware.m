classdef Hardware < handle
    % Hardware is an object that encapsulates the harware interactions
    % including:
    %   -RF sweeper
    %   -DAQ channels
    %   -Image acquisition
    % 
    % Only one Hardware object needs to be created for a GUI; simply kill()
    % and redo the init() call to re-program the hardware.
    
    
    properties
        rf_sweeper          % rf_sweeper object (through DAQ)
        vid                 % camera object
        s                   % DAQ session object
        is_initialized      % boolean flag; '1' if this is already initialized
        exposure_time_sec   % exposure time of shot in seconds
        rf_frequency        % frequency to drive RF in GHz
        rf_power            % RF power in dBm
        ccd_size            % image resolution
        capture_taken       % boolean flag; '1' if a picture was taken with this initialized object
    end
    
    methods
        function obj = init(obj, binning_index, ccd_size_index, exposure_time, rf_frequency, rf_power)
            % initializes the Hamamatsu camera, DAQ system, and RF sweeper
            % binning_index: index corresponding to binning setting
            % ccd_size_index: index corresponding to ccd size
            % exposure_time: exposure time of measurement (ns)
            % rf_frequency: frequency to drive RF (GHz)
            % rf_power: power of drive RF (dBm)
            
            if obj.is_initialized
                error('hardware is already initialized')
            end
            
            
            %% ENSURE OLD VIDEO OBJECTS ARE DELETED
            delete(imaqfind)
            
            
            %% SET OBJECT FIELDS
            obj.exposure_time_sec = exposure_time * 10^(-9);
            obj.rf_frequency = rf_frequency;
            obj.rf_power = rf_power;
            
            
            %% SET UP RF SWEEPER

            obj.rf_sweeper = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 19);

            % Create the GPIB object if it does not exists
            if isempty(obj.rf_sweeper)
                obj.rf_sweeper = gpib('NI', 0, 19);    %this is the key line. works without
                                        % %the rest unless program halts or something
            else
                fclose(obj.rf_sweeper);
                obj.rf_sweeper = obj.rf_sweeper(1);
            end

            fopen(obj.rf_sweeper);    %% Connect to rf generator object, obj.rf_sweeper. 
            set(obj.rf_sweeper, 'Timeout', 2);

            fprintf(obj.rf_sweeper, 'PS0');                              % Sets power sweep mode off
            fprintf(obj.rf_sweeper, 'CW %d GZ', obj.rf_frequency);           % Sets CW frequency 
            fprintf(obj.rf_sweeper, 'PL %d DB', obj.rf_power);               % Sets the power level 
            fprintf(obj.rf_sweeper, 'RF1');                              % Sets RF power on

            
            %% SET UP CCD AREA
            b_size = [1 2 4]; % possible camera binning options
            binning = b_size(binning_index);

            c_size = [128 256 512 1024 2048]; % possible image size options
            obj.ccd_size = c_size(ccd_size_index);

            if binning * obj.ccd_size > 2048 % if binning * ccd area is greater than total camera pixel number
                error('invalid image size requested. check binning and ccd size.')
            end

            imagingM = {'MONO16_2048x2048_FastMode','MONO16_BIN2x2_1024x1024_FastMode','MONO16_BIN4x4_512x512_FastMode'};
            imagingMode = imagingM{binning_index};

            % region of interest (intensity sampling region)    
            ROIPosition = [2048/binning/2 - obj.ccd_size/2 2048/binning/2 - obj.ccd_size/2 obj.ccd_size obj.ccd_size];

            
            %% INITIALIZE VIDEO OBJECT
            obj.vid                     = videoinput('hamamatsu', 1, imagingMode);
            src                         = getselectedsource(obj.vid);
            MAX_EXPOSURE_TIME           = 1;

            if obj.exposure_time_sec > MAX_EXPOSURE_TIME
                error('desired exposure time is too large for Hamamatsu camera')
            end
            
            src.ExposureTime            = obj.exposure_time_sec; % assign exposure time
            kinTime = obj.exposure_time_sec + obj.ccd_size/(2048/binning)*10E-3; % total time to take an image (inc. readout)

            obj.vid.FramesPerTrigger    = 1; 
            obj.vid.TriggerRepeat       = 1; % one image per trigger

            triggerconfig(obj.vid, 'hardware', 'RisingEdge', 'EdgeTrigger');
            obj.vid.ROIPosition         = ROIPosition; 


            %% INITIALZE DAQ
            obj.s = daq.createSession('ni');
            addCounterOutputChannel(obj.s,'Dev1', 1, 'PulseGeneration'); % camera

            daq_camera_trigger_duty_cycle          = 0.50; % duty cycle of camera trigger
            daq_camera_trigger_inital_delay        = 0.0005;
            daq_camera_trigger_frequency           = 1/kinTime; 

            daq_rate                               = 50000; % daq read/write rate
            daq_duration                           = kinTime; % time daq is on

            % % print settings to daq instance
            obj.s.Rate                             = daq_rate;
            obj.s.DurationInSeconds                = daq_duration;

            % % set up camera trigger
            ch                                     = obj.s.Channels(1);
            ch.InitialDelay                        = daq_camera_trigger_inital_delay;
            ch.Frequency                           = daq_camera_trigger_frequency;
            ch.DutyCycle                           = daq_camera_trigger_duty_cycle;
            
            obj.is_initialized                     = 1;
        end
        
        
        
        function image = capture(obj)
            
            % check if this object is initialized
            if not(obj.is_initialized)
                error('Cannot capture image on Hardware object that is not initialized');
            end
            
            % Capture an image using the initialized Hardware object and it
            % corresponding capture parameters.

            %% TAKE PIX
            start(obj.vid);
            pause(0.25);

            % trigger Pulseblaster sequence    
            pb_start();
            [~,~] = obj.s.startForeground();

            stop(obj.vid)

            % now get images from camera
            rawCameraImages = double(getdata(obj.vid, obj.vid.TriggerRepeat));

            % check if pulseblaster is still running
            running = bitand(pb_read_status(), 4);


            % post-process image
            image = rawCameraImages;

            % print out Pulseblaster exit status
            status = num2str(pb_read_status());
            message = strcat('pb exit status:  ', status);
            disp(message);
        end
        
        
        function size = get_image_size(obj)
            % Returns the size length (in pixels) of the image to be
            % captured by this Hardware object
            if not(obj.is_initialized)
                error('initialize the Hardware object first')
            end
            
            size = obj.ccd_size;
        end
                
        
        
        
        function kill(obj)
            % called after init() and measurement_script() to kill current
            % hardware connections
            
            
            if obj.is_initialized == 0
                error('Hardware is not initialized')
            end
                
            % delete hamamatsu video object
            delete(obj.vid)

            % clear daq
            % clear daq
            obj.s.release; % release the daq instance
            delete(obj.s) % delete the daq instance

            fprintf(obj.rf_sweeper, 'RS');      % reset the instrument
            fprintf(obj.rf_sweeper, 'CS');      % clear status
            fprintf(obj.rf_sweeper, 'CS');      % clear status
            fprintf(obj.rf_sweeper, 'RF0');     % Sets RF power on
            fclose(obj.rf_sweeper);             % close 
            delete(obj.rf_sweeper);             % delete
            obj.is_initialized = 0;
        end
    end
end