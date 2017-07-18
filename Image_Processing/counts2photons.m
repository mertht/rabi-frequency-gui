function photons = counts2photons(camera_counts, rf_off_counts)
% converts counts (from Hamamatsu camera) to photons
% camera counts: number of counts over integration region
% rf_off_counts: measured counts during laser excitation integration with RF off

    DARK_OFFSET = 100; % hamamatsu dark offset: 100 extra counts each time a picture is taken
    CONVERSION_FACTOR = 0.46; % hamamatsu average photons/count
    actual_counts = camera_counts - (DARK_OFFSET + rf_off_counts);
    photons = actual_counts * CONVERSION_FACTOR;
end