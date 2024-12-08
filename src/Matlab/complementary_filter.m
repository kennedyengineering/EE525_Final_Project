%% Setup
clear; clc; close all;
dt = 0.008;
staticFile = "../../data/static/static_table_log_raw_4g_500dps.csv";
dynamicFile = "../../data/vision2/usb_pendulum_log_raw_4g_500dps_1.csv";

if ~isfile(staticFile), error('Data file does not exist: %s', staticFile); end
if ~isfile(dynamicFile), error('Data file does not exist: %s', dynamicFile); end

%% Load Static Data
staticData = readtable(staticFile);
sAX = staticData{:, matches(staticData.Properties.VariableNames, 'AccelX')}';
sAY = staticData{:, matches(staticData.Properties.VariableNames, 'AccelY')}';
sAZ = staticData{:, matches(staticData.Properties.VariableNames, 'AccelZ')}';
sGX = staticData{:, matches(staticData.Properties.VariableNames, 'GyroX')}';
sGY = staticData{:, matches(staticData.Properties.VariableNames, 'GyroY')}';
sGZ = staticData{:, matches(staticData.Properties.VariableNames, 'GyroZ')}';

%% Load Dynamic Data
dynamicData = readtable(dynamicFile);
time = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'Timestamp')}';
aX = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'AccelX')}';
aY = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'AccelY')}';
aZ = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'AccelZ')}';
gX = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'GyroX')}';
gY = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'GyroY')}';
gZ = dynamicData{:, matches(dynamicData.Properties.VariableNames, 'GyroZ')}';

%% Complementary Filter Setup
n = length(time); % Number of data points
theta = zeros(1, n); % Initialize fused angle array
theta_gyro = zeros(1, n); % Gyroscope angle
theta_accel = zeros(1, n); % Accelerometer angle

alpha = 0.98; % Complementary filter constant

% Initial angle (from accelerometer)
theta(1) = atan2(aY(1), sqrt(aX(1)^2 + aZ(1)^2));

%% Loop through dynamic data
for k = 2:n
    % Gyroscope-based angle
    theta_gyro(k) = theta(k-1) + gX(k) * dt;

    % Accelerometer-based angle
    theta_accel(k) = atan2(aY(k), sqrt(aX(k)^2 + aZ(k)^2));

    % Complementary filter
    theta(k) = alpha * theta_gyro(k) + (1 - alpha) * theta_accel(k);
end

%% Plot Results
figure;
plot(time, theta, 'DisplayName', 'Fused Angle');
hold on;
plot(time, theta_gyro, 'DisplayName', 'Gyro Angle');
plot(time, theta_accel, 'DisplayName', 'Accel Angle');
legend;
xlabel('Time (s)');
ylabel('Angle (rad)');
title('Complementary Filter Output');
grid on;

%% Pendulum Parameters
g = 9.81; % Gravity
r = 1.0; % Length (meters)
b = 0.05; % Damping coefficient
m = 1.0; % Mass (kg)
beta = 0.98; % Complementary filter constant for angular velocity

%% Initialize Angular Velocity
theta_dot = zeros(1, n); % Fused angular velocity
% theta_dot_model = zeros(1, n); % Model-predicted angular velocity

%% Loop through dynamic data
for k = 2:n
    % Gyroscope angular velocity (direct measurement)
    theta_dot_gyro = gX(k);

    % Accelerometer-derived angular velocity (from consecutive angles)
    theta_dot_accel = (theta_accel(k) - theta_accel(k-1)) / dt;

    % Complementary filter for angular velocity
    theta_dot(k) = beta * theta_dot_gyro + (1 - beta) * theta_dot_accel;
end

%% Plot Results
figure;
plot(time, theta_dot, 'DisplayName', 'Fused Angular Velocity');
hold on;
plot(time, gX, 'DisplayName', 'Gyro Angular Velocity');
% plot(time, theta_dot_model, 'DisplayName', 'Model Angular Velocity');
legend;
xlabel('Time (s)');
ylabel('Angular Velocity (rad/s)');
title('Complementary Filter Output for Angular Velocity');
grid on;
