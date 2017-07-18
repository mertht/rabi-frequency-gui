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
    
    % get constants
    global CLOCK_FREQ;
    global LASER_ON;
    global RF_ON;
    global ALL_OFF;
    global REGION_WIDTH;
    
    
    %% GET USER PARAMETERS
    
    % get pulse parameters from gui text fields
    t_laser = getN(handles.t_laser);
    t_rf_min = getN(handles.t_rf_min);
    t_rf_max = getN(handles.t_rf_max);
    samples = getN(handles.samples);
    cycles = getN(handles.cycles);
    rf_frequency = getN(handles.rf_frequency);
    rf_power = getN(handles.rf_power);
    
    % get binning/imaging parameters
    binning_index = get(handles.binning,'Value');
    ccd_size_index = get(handles.ccd_size,'Value');
    rf_durations = linspace(t_rf_min, t_rf_max, samples);
    
    
    % check parameters
    if t_rf_min >= t_rf_max
        error('invalid microwave time inputs')
    elseif cycles < 1
        error('number of cycles must be a positive integer')
    end
    
    % initialize pulseblaster
    pb_init();
    
    % set clock frequency of board and start programming
    pb_core_clock(CLOCK_FREQ);
    total_t_laser = cycles * t_laser; % exposure time for background image
    
    
    %% CALCULATE RF OFF COUNTS
    pb_start_programming('PULSE_PROGRAM'); % get pb ready
    pb_inst_pbonly(LASER_ON, 'CONTINUE', 0, t_laser); % continuous laser beam for background image
    pb_inst_pbonly(ALL_OFF, 'CONTINUE', 0, 1000); % zero pins after completions
    pb_stop_programming();

    disp('initializing RF off counts measurement')
    hardware = Hardware;
    hardware.init(binning_index, ccd_size_index, total_t_laser, rf_frequency, rf_power);
    disp('running RF off counts measurement')
    rf_off_image = hardware.capture();
    disp('killing RF off counts measurement')
    hardware.kill();
    
    % plot image
    figure
    imagesc(rf_off_image)
    image_title = strcat('RF Off Image - see integration region');
    title(image_title)
    hold on

    % determine inegration parameters then integrate to get average counts for RF off signal
    [x0, y0] = get_center(rf_off_image);
    rf_off_counts = average_counts(rf_off_image, x0, y0);
    
    % display integration region
    rw = 2 * REGION_WIDTH;
    rectangle('Position',[x0 - REGION_WIDTH, y0 - REGION_WIDTH, rw, rw],...
     'LineWidth', 2, 'EdgeColor', 'red')
    hold off
    
    %% CALCULATE BACKGROUND COUNTS
    pb_start_programming('PULSE_PROGRAM'); % get pb ready
    pb_inst_pbonly(ALL_OFF, 'CONTINUE', 0, t_laser); % continuous laser beam for background image
    pb_inst_pbonly(ALL_OFF, 'CONTINUE', 0, 1000); % zero pins after completions
    pb_stop_programming();

    disp('initializing background counts measurement')
    hardware.init(binning_index, ccd_size_index, total_t_laser, rf_frequency, rf_power);
    disp('running background counts measurement')
    bg_image = hardware.capture();
    disp('killing background counts measurement')
    hardware.kill();
    
    % plot image
    figure
    imagesc(bg_image)
    image_title = strcat('Background Image');
    title(image_title)
    
    % calculate background count rate to compensate for pulsed experiments
    % to follow
    bg_count_rate = average_counts(bg_image, x0, y0) / total_t_laser;

    
    %% RUN PULSED SEQUENCES
    
    pl_array = zeros(length(rf_durations), 1); % array to store actual photon counts
    image_array = zeros(hardware.ccd_size, hardware.ccd_size, length(rf_durations));
  
    % for each rf duration, generate looped pulses of both laser and RF
    for d = 1:length(rf_durations)
        pb_start_programming('PULSE_PROGRAM'); % get pb ready
        t_rf = rf_durations(d); % length of rf pulse in ns
        
        start_laser = pb_inst_pbonly(LASER_ON, 'LOOP', cycles, t_laser); % turn laser pulse on, rf off
        pb_inst_pbonly(RF_ON, 'END_LOOP', start_laser, t_rf); % turn rf pulse on, laser off
        pb_inst_pbonly(ALL_OFF, 'CONTINUE', 0, 1000); % zero pins after completions
        pb_stop_programming();
        
        
        exposure_time = cycles * (t_laser + t_rf); % total exposure time for this experiment
        bg_counts = bg_count_rate * exposure_time; % need to subtract this off after getting average counts
        disp('initializing pulse sequence')

        % initialize hardware setup
        hardware = Hardware;
        hardware.init(binning_index, ccd_size_index, exposure_time, rf_frequency, rf_power);
        disp('running pulse sequence')

        % run pulsed sequence and gather image
        image = hardware.capture();
        diff_counts = average_counts(image, x0, y0) - bg_counts; % number of counts above bg_counts
        pl_array(d) = counts2photons(diff_counts, rf_off_counts); % add data sample to data array
        image_array(:,:,d) = image; % add image to image array
        
        % plot image
        figure
        imagesc(image)
        image_title = strcat('RF Pulse =  ', num2str(t_rf), ' ns');
        title(image_title)
        
        disp('killing pulse sequence')
        hardware.kill();
    end
    
    
    pb_stop();
    pb_close(); % close the pulseblaster

end