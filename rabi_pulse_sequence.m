function [image_array, rf_durations, pl_array] = rabi_pulse_sequence(handles)
    % rabi_pulse_sequence returns an array of pulse instructions as objects
    % t_laser       laser duration (ns)
    % t_rf_min      minimum laser duration (ns)
    % t_rf_max      maximum laser duration (ns)
    % samples       number of samples (steps)
    
    % Returns an array of captured images and photon counts (pl_array)
    % which corresponds to the rf_durations array (where rf_durations is
    % in units of ns)
    
    
    % FOR EXAMPLE - 3 cycles of pulses, where the length of the laser pulse is
    % t_laser and the length of the takes on a value from rf_durations.
    %
    % laser pulse (initializtion/readout):
    %       |''''''|___|''''''|___|''''''|___
    % rf pulse:
    %       _______|'''|______|'''|______|'''|
    
    %% GET USER PARAMETERS
    
    % get pulse parameters from gui text fields
    t_laser = getN(handles.t_laser);
    t_rf_min = getN(handles.t_rf_min);
    t_rf_max = getN(handles.t_rf_max);
    samples = getN(handles.samples);
    cycles = getN(handles.cycles);
    rf_frequency = getN(handles.rf_frequency);
    rf_power = getN(handles.rf_power);
    n_average = 1;
    
    
    % get binning/imaging parameters
    binning_index = get(handles.binning,'Value');
    ccd_size_index = get(handles.ccd_size,'Value');
    rf_durations = linspace(t_rf_min, t_rf_max, samples);
    total_t_laser = cycles * t_laser; % exposure time for background image

    
    % check parameters
    if t_rf_min >= t_rf_max
        error('invalid microwave time inputs')
    elseif cycles < 1
        error('number of cycles must be a positive integer')
    end

    
    %% CALCULATE RF OFF COUNTS
    
    disp('initializing RF off counts measurement')
    hardware = Hardware;
    hardware.init(binning_index, ccd_size_index, total_t_laser, rf_frequency, rf_power);
    pb_start_programming('PULSE_PROGRAM'); % get pb ready
    pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.CAMERA_DELAY); % account for time delay of camera launch
    pb_inst_pbonly(Hardware.LASER_ON, 'CONTINUE', 0, total_t_laser); % continuous laser beam for background image
    pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.MIN_INSTR_LENGTH); % zero pins after completions
    pb_stop_programming();
    
    disp('running RF off counts measurement')
    rf_off_image = hardware.capture_average(n_average); % combine images for averaging later
    hardware.kill();
    disp('killing RF off counts measurement')

        
    % determine inegration parameters then integrate to get average counts for RF off signal
    [x0, y0] = get_center(rf_off_image, handles);
    rf_off_counts = average_counts(rf_off_image, x0, y0);

    
    
    %% CALCULATE BACKGROUND COUNTS FOR RF OFF
    disp('initializing background counts measurement')
    hardware.init(binning_index, ccd_size_index, total_t_laser, rf_frequency, rf_power);

    pb_start_programming('PULSE_PROGRAM'); % get pb ready
    pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.CAMERA_DELAY); % account for time delay (fiber optic + camera launch)
    pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, total_t_laser); % continuous laser beam for background image
    pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.MIN_INSTR_LENGTH); % zero pins after completions
    pb_stop_programming();

    disp('running background counts measurement')    
    bg_image = hardware.capture_average(n_average);
    disp('killing background counts measurement')
    hardware.kill();

    % calculate background count rate to compensate for pulsed experiments to follow
    bg_counts = average_counts(bg_image, x0, y0);
    rf_off_counts = rf_off_counts - bg_counts;
    

    
    %% RUN PULSED SEQUENCES
    
    pl_array = zeros(length(rf_durations), 1); % array to store actual photon counts
    image_array = zeros(hardware.ccd_size, hardware.ccd_size, length(rf_durations));
    
    % for each rf duration, generate loop of laser and RF pulses
    for d = 1:length(rf_durations)
        t_rf = rf_durations(d); % length of rf pulse in ns        
        exposure_time = cycles * (t_laser + t_rf); % total exposure time for this experiment
        
        
        %% CALCULATE BACKGROUND COUNTS
        disp('initializing background counts measurement')
        hardware.init(binning_index, ccd_size_index, exposure_time, rf_frequency, rf_power);

        pb_start_programming('PULSE_PROGRAM'); % get pb ready
        pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.CAMERA_DELAY); % account for time delay (fiber optic + camera launch)
        pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, exposure_time); % continuous laser beam for background image
        pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.MIN_INSTR_LENGTH); % zero pins after completions
        pb_stop_programming();

        disp('running background counts measurement')    
        bg_image = hardware.capture_average(n_average);
        disp('killing background counts measurement')
        hardware.kill();

        % calculate background count rate to compensate for pulsed experiments to follow
        bg_counts = average_counts(bg_image, x0, y0);
        
        %% RUN PULSED SEQUENCE
        disp('initializing pulse sequence')
        % initialize hardware setup
        hardware = Hardware;
        hardware.init(binning_index, ccd_size_index, exposure_time, rf_frequency, rf_power);
        disp('running pulse sequence')
        
        
%         pb_start_programming('PULSE_PROGRAM'); % get pb ready
%         pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.CAMERA_DELAY); % account for time delay of camera launch
%         pb_inst_pbonly(Hardware.LASER_ON, 'CONTINUE', 0, total_t_laser); % continuous laser beam for background image
%         pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.MIN_INSTR_LENGTH); % zero pins after completions
%         pb_stop_programming();
        
        
        % Old pulse instruction; does not account for delay of AOM (laser)
%         pb_start_programming('PULSE_PROGRAM'); % get pb ready
%         pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.CAMERA_DELAY); % account for time delay (fiber optic + camera launch)
%         start_laser = pb_inst_pbonly(Hardware.LASER_ON, 'LOOP', cycles, t_laser); % laser pulse on
%         pb_inst_pbonly(Hardware.RF_ON, 'END_LOOP', start_laser, t_rf); % turn rf pulse on, laser off
%         pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.MIN_INSTR_LENGTH); % zero pins after completions
%         pb_stop_programming();

        % New pulse instruction; does not account for delay of AOM (laser)
        both_on = bitor(Hardware.LASER_ON, Hardware.RF_ON); % get hex flag for both on
        pb_start_programming('PULSE_PROGRAM'); % get pb ready
        pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.CAMERA_DELAY); % account for time delay (fiber optic + camera launch)
        % pb_inst_pbonly(Hardware.LASER_ON, 'CONTINUE', 0, t_laser); % initialize
        
            % actual loop
            start_laser = pb_inst_pbonly(Hardware.LASER_ON, 'LOOP', cycles, Hardware.LASER_RESPONSE - t_rf); % turn rf pulse on, laser off
            pb_inst_pbonly(both_on, 'CONTINUE', 0, t_rf); % turn rf pulse on, laser off
            pb_inst_pbonly(Hardware.LASER_ON, 'CONTINUE', 0, t_laser - Hardware.LASER_RESPONSE); % turn rf pulse on, laser off
            pb_inst_pbonly(Hardware.ALL_OFF, 'END_LOOP', start_laser, t_rf); % delay due to laser response, both off

        pb_inst_pbonly(Hardware.ALL_OFF, 'CONTINUE', 0, Hardware.MIN_INSTR_LENGTH); % zero pins after completions
        pb_stop_programming();

        % run pulsed sequence and gather image
        image = hardware.capture_average(n_average);
        
        real_counts = average_counts(image, x0, y0) - bg_counts;                    % number of counts above bg_counts                  % "difference image"
        pl_array(d) = real_counts;    % normalize and add data to data array
        image_array(:,:,d) = image;                                     % add image to image array
        
        
        % add point to sinusoid plot in GUI
        x_limits = [rf_durations(1), rf_durations(end)];
        axes(handles.sinusoid);
        plot(handles.sinusoid, rf_durations(1:d), pl_array(1:d)); % refresh plot with new data point
        set(handles.sinusoid, 'XLimMode', 'manual');
        set(handles.sinusoid, 'Xlim', x_limits);
        title('Rabi Oscillation')
        xlabel('RF Pulse Duration (ns)')
        ylabel('Normalized PL (arb.)')
        
        % plot image
        figure
        imagesc(image)
        image_title = strcat('RF Pulse =  ', num2str(t_rf), ' ns');
        title(image_title)
        
        disp('killing pulse sequence')
        hardware.kill();
    end

end