%% Complementary Filter for Angle Estimation
%% Setup
clear; clc; close all;
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

%% Calculate Theoretical Optimal Alpha and Beta

% Noise variance for accelerometer (angle from static data)
sThetaAccel = atan2(sAY, sqrt(sAX.^2 + sAZ.^2));
varAccelAngle = var(sThetaAccel);
varGyro = var(sGX);

% Theoretical alpha (angle fusion)
dt = 0.008;
alpha = varAccelAngle / (varAccelAngle + varGyro * dt^2);
fprintf('Theoretical alpha (angle fusion): %.3f\n', alpha);

alpha = 0.99; % Empirically optimized alpha
fprintf('Empirical alpha (angle fusion): %.3f\n', alpha);

%% Complementary Filter Setup
n = length(time);
theta = zeros(1, n);
theta_gyro = zeros(1, n);
theta_accel = zeros(1, n);

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

%% Plot Results for Angular Position
figure('Position', [100, 100, 1000, 800]);
plot(time, theta, 'DisplayName', 'Fused Angle (Complementary Filter)', 'LineWidth', 2.0);
hold on;
plot(time, theta_gyro, '--', 'DisplayName', 'Gyroscope-Only Angle', 'LineWidth', 1.5);
plot(time, theta_accel, ':', 'DisplayName', 'Accelerometer-Only Angle', 'LineWidth', 1.5);
legend('FontSize', 10, 'Location', 'best');
xlabel('Time (s)', 'FontSize', 12);
ylabel('Angle (rad)', 'FontSize', 12);
title('Comparison of Fused Angle vs. Individual Sources', 'FontSize', 14);
grid on;

%% Initialize Uncertainty Tracking
var_theta = zeros(1, n);
var_theta(1) = varAccelAngle;

%% Loop through dynamic data (tracking uncertainties)
for k = 2:n
    % Gyroscope variance for angle (propagated over time)
    var_theta_gyro = var_theta(k-1) + varGyro * dt^2;

    % Variance of the fused angle (complementary filter)
    var_theta(k) = alpha^2 * var_theta_gyro + (1 - alpha)^2 * varAccelAngle;
end

figure('Position', [100, 100, 1000, 800]);
plot(time, sqrt(var_theta), 'DisplayName', 'Uncertainty in Fused Angle (std dev)', 'LineWidth', 1.5);
xlabel('Time (s)', 'FontSize', 12);
ylabel('Uncertainty (rad)', 'FontSize', 12);
title('Uncertainty in Fused Angle Over Time (Complementary Filter)', 'FontSize', 14);
grid on;
legend('FontSize', 10, 'Location', 'best');
