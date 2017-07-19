function [x0, y0] = get_center(background_image, handles)
    % Finds the point of max intensity the provided image,
    % and outputs the (x,y) coordinates of that point. If that point
    % is too close to the edge, then an error will be thrown
    
    global REGION_WIDTH;
    
    % size of background image
    [y_width,x_width] = size(background_image);
    
    % get linear index of maximum brightness pixel
    [~, index] = max(background_image(:));
    % get 2d subscript of maximum brightness pixel
    [y0, x0] = ind2sub(size(background_image), index)
    
    % send picture out to GUI
    axes(handles.pic_frame)
    
    if ((x0 - REGION_WIDTH < 0) || (y0 - REGION_WIDTH < 0)) || ((x0 + REGION_WIDTH > x_width) || (y0 + REGION_WIDTH > y_width))
        % plot image and alert user of invalid max intensity spot
        imagesc(background_image)
        title('Bad integration region, see circle')
        hold on
        h = plot(x0, y0, 'o');
        set(h, 'MarkerSize', 30, 'Color', 'red', 'LineWidth', 5);
        error('invalid integration region. check image.')
    end

    % plot image
    imagesc(background_image)
    image_title = strcat('RF Off Image - see integration region');
    title(image_title)
    hold on
    
    % display integration region
    rw = 2 * REGION_WIDTH;
    rectangle('Position',[x0 - REGION_WIDTH, y0 - REGION_WIDTH, rw, rw],...
     'LineWidth', 2, 'EdgeColor', 'red')
    hold off
    
end
