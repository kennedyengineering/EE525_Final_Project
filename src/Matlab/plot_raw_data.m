% Plot raw data

clear; clc;

% Define the path to the data file
dataFilePath = "../../data/vision/swing_pendulum_vision_log_raw_4g_500dps_1.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);

% Extract the first column as X
x = data{:, 1};

% Get variable names for X
xName = data.Properties.VariableNames(1);

% Extract all other columns as Y
y = data{:, 2:end};

% Get variable names for Y
yNames = data.Properties.VariableNames(2:end);

% Identify accelerometer and gyroscope data
accelIdx = find(contains(yNames, 'Accel'));
gyroIdx = find(contains(yNames, 'Gyro'));

% Plot the accelerometer data (separate)
figure;
sgtitle('Accelerometer Readings');
hold on;
subplotcount = 1;
for i = accelIdx
    subplot(length(accelIdx), 1, subplotcount);
    subplotcount = subplotcount + 1;
    plot(x, y(:, i), 'LineWidth', 1.5);
    xlabel('Time (ms)');
    ylabel('Linear Acceleration (m/s^2)');
    title([yNames{i}]);
    grid on;
end

% Plot the accelerometer data (Combined)
figure;
title('Comparison of Accelerometer Readings');
hold on;
for i = accelIdx
    plot(x, y(:, i), 'LineWidth', 1.5, 'DisplayName', [yNames{i}]);
end
xlabel('Time (ms)');
ylabel('Linear Acceleration (m/s^2)');
grid on;
legend;

% Plot the gyroscope data (separate)
figure;
sgtitle('Gyroscope Readings');
hold on;
subplotcount = 1;
for i = gyroIdx
    subplot(length(gyroIdx), 1, subplotcount);
    subplotcount = subplotcount + 1;
    plot(x, y(:, i), 'LineWidth', 1.5);
    xlabel('Time (ms)');
    ylabel('Angular Velocity (rad/s)');
    title([yNames{i}]);
    grid on;
end

% Plot the gyroscope data (combined)
figure;
title('Comparison of Gyroscope Readings');
hold on;
for i = gyroIdx
    plot(x, y(:, i), 'LineWidth', 1.5, 'DisplayName', [yNames{i}]);
end
xlabel('Time (ms)');
ylabel('Angular Velocity (rad/s)');
grid on;
legend;
