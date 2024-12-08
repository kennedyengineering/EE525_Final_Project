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

%% Calculate Theoretical Optimal Alpha and Beta

% Noise variance for accelerometer (angle from static data)
sThetaAccel = atan2(sAY, sqrt(sAX.^2 + sAZ.^2));
varAccelAngle = var(sThetaAccel); % Variance of accelerometer angle
varGyro = var(sGX); % Variance of gyroscope noise

% Theoretical alpha (angle fusion)
alpha = varAccelAngle^2 / (varAccelAngle^2 + varGyro^2 * dt^2);
fprintf('Theoretical alpha (angle fusion): %.3f\n', alpha);

%% Precompute Accelerometer-Based Angles
theta_accel = atan2(aY, sqrt(aX.^2 + aZ.^2)); % Compute all accelerometer-based angles

% Angular velocity derived from accelerometer angles
theta_dot_accel = diff(theta_accel) / dt; % Angular velocity from consecutive accelerometer angles

% Noise variance for dynamic data (angular velocity)
varAccelVel = var(theta_dot_accel); % Variance of accel-derived velocity
varGyroVel = var(gX); % Variance of gyroscope angular velocity

% Theoretical beta (velocity fusion)
beta = varAccelVel^2 / (varAccelVel^2 + varGyroVel^2);
fprintf('Theoretical beta (velocity fusion): %.3f\n', beta);

%% Complementary Filter Setup
n = length(time); % Number of data points
theta = zeros(1, n); % Initialize fused angle array
theta_gyro = zeros(1, n); % Gyroscope angle
theta_accel = zeros(1, n); % Accelerometer angle

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
figure;
% Plot fused angle
plot(time, theta, 'DisplayName', 'Fused Angle (Complementary Filter)');
hold on;

% Plot gyroscope-only angle
plot(time, theta_gyro, '--', 'DisplayName', 'Gyroscope-Only Angle');

% Plot accelerometer-only angle
plot(time, theta_accel, ':', 'DisplayName', 'Accelerometer-Only Angle');

% Add legend and labels
legend;
xlabel('Time (s)');
ylabel('Angle (rad)');
title('Comparison of Fused Angle vs. Individual Sources');
grid on;

% Optional: Plot differences for analysis
% figure;
% plot(time, theta - theta_gyro, 'DisplayName', 'Difference: Fused vs Gyroscope');
% hold on;
% plot(time, theta - theta_accel, 'DisplayName', 'Difference: Fused vs Accelerometer');
% legend;
% xlabel('Time (s)');
% ylabel('Difference (rad)');
% title('Differences Between Fused Angle and Individual Sources');
% grid on;

%% Pendulum Parameters
g = 9.81; % Gravity
r = 1.0; % Length (meters)
b = 0.05; % Damping coefficient
m = 1.0; % Mass (kg)

% beta = 0.98; % Complementary filter constant for angular velocity

%% Initialize Angular Velocity
theta_dot = zeros(1, n-1); % Fused angular velocity

%% Loop through dynamic data
for k = 2:n-1
    % Gyroscope angular velocity (direct measurement)
    theta_dot_gyro = gX(k);

    % Complementary filter for angular velocity
    theta_dot(k-1) = beta * theta_dot_gyro + (1 - beta) * theta_dot_accel(k-1); % Match indexing
end

%% Plot Results for Angular Velocity
figure;
% Plot fused angular velocity
plot(time(1:end-1), theta_dot, 'DisplayName', 'Fused Angular Velocity (Complementary Filter)');
hold on;

% Plot gyroscope-only angular velocity
plot(time(1:end-1), gX(1:end-1), '--', 'DisplayName', 'Gyroscope-Only Angular Velocity');

% Plot accelerometer-derived angular velocity
plot(time(1:end-1), theta_dot_accel, ':', 'DisplayName', 'Accelerometer-Derived Angular Velocity');

% Add legend and labels
legend;
xlabel('Time (s)');
ylabel('Angular Velocity (rad/s)');
title('Comparison of Fused Angular Velocity vs. Individual Sources');
grid on;

%% Initialize Uncertainty Tracking
var_theta = zeros(1, n); % Variance of fused angle (theta)
var_theta(1) = varAccelAngle; % Start with accelerometer variance

var_theta_dot = zeros(1, n-1); % Variance of fused angular velocity (theta_dot)
var_theta_dot(1) = varGyroVel; % Start with gyroscope variance

%% Loop through dynamic data (tracking uncertainties)
for k = 2:n
    % Gyroscope variance for angle (propagated over time)
    var_theta_gyro = var_theta(k-1) + varGyro * dt^2;

    % Variance of the fused angle (complementary filter)
    var_theta(k) = alpha^2 * var_theta_gyro + (1 - alpha)^2 * varAccelAngle;

    if k < n
        % Gyroscope variance for angular velocity (constant noise)
        var_theta_dot_gyro = varGyroVel;

        % Accelerometer variance for angular velocity (from diff)
        var_theta_dot_accel = varAccelVel;

        % Variance of fused angular velocity (complementary filter)
        var_theta_dot(k) = beta^2 * var_theta_dot_gyro + (1 - beta)^2 * var_theta_dot_accel;
    end
end

figure;
plot(time, sqrt(var_theta), 'DisplayName', 'Uncertainty in Fused Angle (std dev)');
xlabel('Time (s)');
ylabel('Uncertainty (rad)');
title('Uncertainty in Fused Angle Over Time (Complementary Filter)');
grid on;
legend;

figure;
plot(time(1:end-1), sqrt(var_theta_dot), 'DisplayName', 'Uncertainty in Fused Angular Velocity (std dev)');
xlabel('Time (s)');
ylabel('Uncertainty (rad/s)');
title('Uncertainty in Fused Angular Velocity Over Time (Complementary Filter)');
grid on;
legend;
