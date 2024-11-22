% Compute pendulum state from gyro data

clc; clear; close all;

% Define the path to the data file
dataFilePath = "../../data/vision2/usb_pendulum_log_raw_4g_500dps_1.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);

% Identify relevant data
timeIdx = matches(data.Properties.VariableNames, 'Timestamp');
time = data{:, timeIdx};

gyroXIdx = matches(data.Properties.VariableNames, 'GyroX');
gyroX = data{:, gyroXIdx};
gyroX = gyroX - mean(gyroX);    % eliminate gyroscope drift

% Plot raw data
figure;
plot(time, gyroX);
title('Gyroscope X-Axis Readings');
xlabel('Time (ms)');
ylabel('Angular Velocity (rad/s)');

% Integrate
dt = 0.008; % sample time (s)
theta = cumsum(gyroX)*dt;

% Plot theta
figure;
plot(time, theta);
title('Gyroscope X-Axis Readings Integrated');
xlabel('Time (ms)');
ylabel('Angle (rad)');

% Overlay plots
figure;
hold on;
plot(time, gyroX, 'DisplayName', 'Angular Velocity (rad/s)');
plot(time, theta, 'DisplayName', 'Angle (rad)');
xlabel('Time (ms)');
ylabel('State');
title('Pendulum State According to Gyroscope X-Axis');
legend;
