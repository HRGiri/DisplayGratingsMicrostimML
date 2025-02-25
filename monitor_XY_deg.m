function [X, Y] = monitor_XY_deg(kwargs)
% This function returns the monitor x and y coordinate meshgrid in degrees, given monitor details and view distance in cm.
%
% Uses name=value syntax to allow for flexible and explicit arguments. Typical use cases:
% i. [X, Y] = monitor_XY_deg; if you are from Ray Lab, assuming none of the defaults need altering
% ii. [X, Y] = monitor_XY_deg(view_dist=23, lab="Arun"); if you are from Arun Lab
%
% The order of name=value arguments does not matter. This function currently has no positional arguments; every argument
% is optional. I (Sveekruth) have not included monitor_specs as an optional argument as creating it is usually more
% tedious than simply hardcoding it (refer lines 19 and 21).

    % DEFAULTS:
    arguments
        kwargs.view_dist (1, 1) double {mustBeReal} = 50 % Viewing distance from screen center (cm)
        kwargs.method (1, 1) double {mustBeReal} = 3 % Method used to map pixels to degrees visual angle (dva)
        kwargs.lab string = "Ray" % Lab name, to fetch monitor specifications (in px and cm)
    end
    if kwargs.lab == "Ray"
        monitor_specs = cell2struct({1280; 720; 53.086; 29.972}, ["x_res", "y_res", "width", "height"]);
    elseif kwargs.lab == "Arun"
        monitor_specs = cell2struct({1366; 768; 34.4232; 19.3536}, ["x_res", "y_res", "width", "height"]);
        % monitor_specs = cell2struct({1366; 768; 34.4; 19.35}, ["x_res", "y_res", "width", "height"]);
    end

    if kwargs.method == 4 % Trigonometric method (most accurate, mathematically precise, no approximations):
        x_axis_deg = atand(linspace(-monitor_specs.width/2, monitor_specs.width/2, monitor_specs.x_res)/kwargs.view_dist);
        y_axis_deg = atand(linspace(-monitor_specs.height/2, monitor_specs.height/2, monitor_specs.y_res)/kwargs.view_dist);
    end

    x_deg = atand((monitor_specs.width)/(2*kwargs.view_dist)); % Half-width (degrees visual angle or dva)
    y_deg = atand((monitor_specs.height)/(2*kwargs.view_dist)); % Half-height (dva)
    if kwargs.method == 1 % Full FOV method (includes both extremes at the expense of inexact pixel coordinates, but doesn't require dpp measurement):
        x_axis_deg = linspace(-x_deg, x_deg, monitor_specs.x_res);
        y_axis_deg = linspace(-y_deg, y_deg, monitor_specs.y_res);
    end

    x_dpp = (2*x_deg)/monitor_specs.x_res; % Degrees per pixel
    y_dpp = (2*y_deg)/monitor_specs.y_res; 
    
    if kwargs.method == 2 % Origin method (Supratim's default, includes the origin (0, 0) but at the expense of full FOV at the positive ends of the axes):
        x_axis_deg = -x_deg:x_dpp:x_deg; x_axis_deg = x_axis_deg(1:monitor_specs.x_res);
        y_axis_deg = -y_deg:y_dpp:y_deg; y_axis_deg = y_axis_deg(1:monitor_specs.y_res);
    elseif kwargs.method == 3 % Pixel center method (more accurate, ensures every pixel number is mapped to its center):
        x_axis_deg = -(x_deg - x_dpp/2):x_dpp:(x_deg - x_dpp/2);
        y_axis_deg = -(y_deg - y_dpp/2):y_dpp:(y_deg - y_dpp/2);        
    end
    
    [X, Y] = meshgrid(x_axis_deg, y_axis_deg);

end