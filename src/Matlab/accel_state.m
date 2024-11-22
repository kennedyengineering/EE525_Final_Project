% Compute pendulum state from accel data

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

accelZIdx = matches(data.Properties.VariableNames, 'AccelX');
accelZ = data{:, accelZIdx};

% Convert to angular acceleration
R = 0.4064;  % Length of pendulum (16 inches in meters)
dd_theta = accelZ / R;

% Plot angular acceleration
figure;
plot(time, dd_theta);
title('Accelerometer Z-Axis Angular Acceleration');
xlabel('Time (ms)');
ylabel('Angular Acceleration (rad/s^2)');

% Integrate to get angular velocity
dt = 0.008; % sample time (s)
d_theta = cumsum(dd_theta)*dt;

% Plot angular velocity
figure;
plot(time, d_theta);
title('Accelerometer Z-Axis Angular Velocity');
xlabel('Time (ms)');
ylabel('Angular Velocity (rad/s)');

% Integrate to get angle
theta = cumsum(d_theta)*dt;

% Plot angle
figure;
plot(time, theta);
title('Accelerometer Z-Axis Angle');
xlabel('Time (ms)');
ylabel('Angle (rad)');

% Overlay plots
figure;
hold on;
plot(time, d_theta, 'DisplayName', 'Angular Velocity (rad/s)');
plot(time, theta, 'DisplayName', 'Angle (rad)');
xlabel('Time (ms)');
ylabel('State');
title('Pendulum State According to Accelerometer Z-Axis');
legend;
