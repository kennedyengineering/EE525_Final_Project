% Validate raw data

clear; clc;

% Validate data
function validate_data(folder, filename)

    % Display the filename
    disp(' ');
    disp(filename);

    % Use regular expressions to extract the values
    pattern = '_(\d+)g_(\d+)dps';
    tokens = regexp(filename, pattern, 'tokens');

    % Check if tokens were found
    if isempty(tokens)
        error('Filename format is incorrect. Expected format: "something_#g_#dps.csv"');
    end

    % Convert the tokens to numbers
    g_value = str2double(tokens{1} {1});
    dps_value = str2double(tokens{1} {2});

    % Display the results
    disp([ 'g value: ', num2str(g_value) ]);
    disp([ 'dps value: ', num2str(dps_value) ]);

    % Read data from log file into a table
    data = readtable(fullfile(folder, filename));

    % Find the maximum value in each column
    maxValues = varfun(@(x) max(abs(x)), data);

    % Display the maximum values
    disp('Maximum Values:');
    disp(maxValues);

    % Identify accelerometer and gyroscope data
    accelIdx = contains(data.Properties.VariableNames, 'Accel');
    gyroIdx = contains(data.Properties.VariableNames, 'Gyro');

    % Define saturation thresholds
    g_saturation_threshold = g_value * 9.8;
    dps_saturation_threshold = deg2rad(dps_value);

    % Determine if sensor has been saturated
    isSaturated = false;

    if any (maxValues{ :, accelIdx} > g_saturation_threshold)
        disp('Sensor is saturated in g values!');
        isSaturated = true;
    end

    if any (maxValues{ :, gyroIdx} > dps_saturation_threshold)
        disp('Sensor is saturated in dps values!');
        isSaturated = true;
    end

    if ~isSaturated
        disp('Sensor values are within normal operating ranges.');
    end
end

% Get files in data directory
data_dir = '../../data/';
listing = dir(data_dir);

for i = 1 : length(listing)
    % Check if it's a file (not a directory)
    if ~listing(i).isdir
        % Perform data validation
        validate_data(listing(i).folder, listing(i).name);
    end
end
