function counts = average_counts(image, x0, y0)
    % Gets the total counts from a (1 um)^2 area around the
    % point (x0, y0).
    
    global REGION_WIDTH;
        
    x = x0 + (-REGION_WIDTH:1:REGION_WIDTH); % x coordinates to sum over
    y = y0 + (-REGION_WIDTH:1:REGION_WIDTH); % y coordinates to sum over
    
    counts = squeeze(sum(sum(image(y,x,:)))); % counts in (1 um)^2 area around center
    
end