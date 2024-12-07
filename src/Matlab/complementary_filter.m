%% Complementary Filter (with control input)
clear; clc; close all;

% Define path to static capture data file
staticFilePath = "../../data/static/static_table_log_raw_4g_500dps.csv";

% Check if the file exists
if ~isfile(staticFilePath)
    error('Data file does not exist: %s', staticFilePath);
end

% Load static data
staticData = readtable(staticFilePath);

staticAccelX = staticData{:, matches(staticData.Properties.VariableNames, 'AccelX')}';
staticAccelY = staticData{:, matches(staticData.Properties.VariableNames, 'AccelY')}';
staticAccelZ = staticData{:, matches(staticData.Properties.VariableNames, 'AccelZ')}';

staticGyroX = staticData{:, matches(staticData.Properties.VariableNames, 'GyroX')}';
staticGyroY = staticData{:, matches(staticData.Properties.VariableNames, 'GyroY')}';
staticGyroZ = staticData{:, matches(staticData.Properties.VariableNames, 'GyroZ')}';

% Compute noise variances
varAccelX = var(staticAccelX);
varAccelY = var(staticAccelY);
varAccelZ = var(staticAccelZ);

varGyroX = var(staticGyroX);
varGyroY = var(staticGyroY);
varGyroZ = var(staticGyroZ);

%% Load swing data
% Define the path to dynamic capture data file
dataFilePath = "../../data/vision2/usb_pendulum_log_raw_4g_500dps_1.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Load table
data = readtable(dataFilePath);

% Parse table
time = data{:, matches(data.Properties.VariableNames, 'Timestamp')}';

accelX = data{:, matches(data.Properties.VariableNames, 'AccelX')}';
accelY = data{:, matches(data.Properties.VariableNames, 'AccelY')}';
accelZ = data{:, matches(data.Properties.VariableNames, 'AccelZ')}';

gyroX = data{:, matches(data.Properties.VariableNames, 'GyroX')}';
gyroY = data{:, matches(data.Properties.VariableNames, 'GyroY')}';
gyroZ = data{:, matches(data.Properties.VariableNames, 'GyroZ')}';

%% Complementary Filter (with control input)
% Initialize complementary filter parameters
alpha_angle = 0.96;    % High-pass filter coefficient for angle fusion
alpha_velocity = 0.90;  % High-pass filter coefficient for velocity fusion
complementary_angle = atan2(accelY(1), sqrt(accelX(1).^2 + accelZ(1).^2));
dt = 0.008;

% Arrays to store results
num_samples = length(time);
complementary_angles = zeros(1, num_samples);
complementary_velocities = zeros(1, num_samples);

% Store initial values
complementary_angles(1) = complementary_angle;
complementary_velocities(1) = gyroX(1);

% Run complementary filter
for k = 2:num_samples
    % Angle estimation
    gyro_angle = complementary_angles(k-1) + gyroX(k)*dt;
    accel_angle = atan2(accelY(k), sqrt(accelX(k)^2 + accelZ(k)^2));
    complementary_angles(k) = alpha_angle * gyro_angle + (1-alpha_angle) * accel_angle;

    % Velocity estimation
    % Calculate velocity from accelerometer angle changes
    accel_velocity = (accel_angle - atan2(accelY(k-1), sqrt(accelX(k-1)^2 + accelZ(k-1)^2))) / dt;
    % Combine with gyro measurement
    complementary_velocities(k) = alpha_velocity * gyroX(k) + (1-alpha_velocity) * accel_velocity;
end

% Plot results
figure;
subplot(2,1,1);
plot(time, complementary_angles, 'DisplayName', 'Angle');
title('Complementary Filter - Angle Estimation');
ylabel('Angle (rad)');
xlabel('Time (s)');
legend;
grid on;

subplot(2,1,2);
plot(time, complementary_velocities, 'DisplayName', 'Angular Velocity');
title('Complementary Filter - Angular Velocity');
ylabel('Angular Velocity (rad/s)');
xlabel('Time (s)');
legend;
grid on;
