classdef Hardware < handle
    % Hardware is an object that encapsulates the harware interactions
    % including:
    %   -RF sweeper
    %   -DAQ channels
    %   -Image acquisition
    %   -Pulseblaster
    % 
    % Only one Hardware object needs to be created for a GUI; simply kill()
    % and redo the init() call to re-program the hardware.
    
    
    properties
        rf_sweeper                      % rf_sweeper object (through DAQ)
        vid                             % camera object
        s                               % DAQ session object
        is_initialized                  % boolean flag; '1' if this is already initialized
        exposure_time_sec               % exposure time of shot in seconds
        rf_frequency                    % frequency to drive RF in GHz
        rf_power                        % RF power in dBm
        ccd_size                        % image resolution
        capture_taken                   % boolean flag; '1' if a picture was taken with this initialized object
        laser_response                  % time delay between Pulseblaster signal and laser response at table
    end
    
    properties (Constant)
        CAMERA_DELAY = 50;              % delay between start of Pulseblaster pulses and camera shutter opening (ns)
        LASER_RESPONSE = 100;           % delay between pulseblaster trigger and deflection of beam at diamond
        
        % Hamamatsu camera constants (from model)
        DARK_OFFSET = 100;              % hamamatsu dark offset: 100 extra counts each time a picture is taken
        CONVERSION_FACTOR = 0.46;       % hamamatsu average photons/count
        
        % Hex flags corresponding to Pulseblaster output
        ALL_OFF = 0;                    % hex pin for rf output pulse
        LASER_ON = 1;                   % hex pin for laser output pulse (pin 0)
        RF_ON = 2;                      % hex pin for rf output pulse (pin 1)
        
        CORE_CLOCK = 100;               % this specific model of Pulseblaster (SP17) has 100 MHz clock freq.
        MIN_INSTR_LENGTH = 10;          % minimum allowed instruction length of Pulseblaster (ns)
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
            % commented out for now because image preview (Image Acquisition)
            % shuts off when reset.
%             delete(imaqfind)
%             daqreset
            
            %% SET OBJECT FIELDS
            % see "Properties" for description of fields
            obj.exposure_time_sec = exposure_time * 10^(-9);
            obj.rf_frequency = rf_frequency;
            obj.rf_power = rf_power;
            
            %% SET UP RF SWEEPER

            obj.rf_sweeper = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 19);

            % Create the GPIB object if it does not exists
            if isempty(obj.rf_sweeper)
                % this is the key line. works without the rest unless program halts or something
                obj.rf_sweeper = gpib('NI', 0, 19);
            else
                fclose(obj.rf_sweeper);
                obj.rf_sweeper = obj.rf_sweeper(1);
            end

            
            try
                fopen(obj.rf_sweeper);    % Connect to rf generator object, obj.rf_sweeper. 
            catch ME
                error('turn on the RF sweeper!')
            end
                set(obj.rf_sweeper, 'Timeout', 2);

            fprintf(obj.rf_sweeper, 'PS0');                              % Sets power sweep mode off
            fprintf(obj.rf_sweeper, 'CW %d GZ', obj.rf_frequency);       % Sets CW frequency 
            fprintf(obj.rf_sweeper, 'PL %d DB', obj.rf_power);           % Sets the power level 
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
            try
                obj.vid                     = videoinput('hamamatsu', 1, imagingMode);
            catch ME
                error('turn on Hamamatsu camera!')
            end
                
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

            % print settings to daq instance
            obj.s.Rate                             = daq_rate;
            obj.s.DurationInSeconds                = daq_duration;

            % set up camera trigger
            ch                                     = obj.s.Channels(1);
            ch.InitialDelay                        = daq_camera_trigger_inital_delay;
            ch.Frequency                           = daq_camera_trigger_frequency;
            ch.DutyCycle                           = daq_camera_trigger_duty_cycle;
            obj.is_initialized                     = 1;
            
            
            %% INITIALIZE PULSEBLASTER
            
            pb_close(); % ensure pb is already closed
            pb_init(); % initialize
            pb_core_clock(Hardware.CORE_CLOCK); % set core clock speed
        end

        
        
        function image = capture(obj)
            % With the initialized parameters, capture and return an image
            
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
            
            % actually capture image... note that this command also acts as
            % pause(exposure_time) and ensures that the pulseblaster has
            % completed its sequence
            [~,~] = obj.s.startForeground();
            obj.s.wait();
            
            % stop objects
            stop(obj.vid)
            pb_stop();

            % now get images from camera
            image = double(getdata(obj.vid, obj.vid.TriggerRepeat));

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
                
            %% KILL HAMAMATSU CAMERA
            delete(obj.vid)

            %% KILL DAQ AND RF SWEEPER
            obj.s.release; % release the daq instance
            delete(obj.s) % delete the daq instance
            fprintf(obj.rf_sweeper, 'RS');      % reset the instrument
            fprintf(obj.rf_sweeper, 'CS');      % clear status
            fprintf(obj.rf_sweeper, 'CS');      % clear status
            fprintf(obj.rf_sweeper, 'RF0');     % Sets RF power on
            fclose(obj.rf_sweeper);             % close 
            delete(obj.rf_sweeper);             % delete
            obj.is_initialized = 0;
            
            %% KILL PULSEBLASTER
            pb_stop();
            pb_close();
            
        end
    end
    
    methods(Static)
        
        function photons = counts2photons(camera_counts)
            % converts counts (from Hamamatsu camera) to photons
            % camera counts: number of counts over integration region
            % rf_off_counts: measured counts during laser excitation integration with RF off
                actual_counts = camera_counts - (Hardware.DARK_OFFSET);
                photons = actual_counts * Hardware.CONVERSION_FACTOR;
        end
        
    end
end