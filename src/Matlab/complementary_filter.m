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

%% Define constants
dt = 0.008;  % Sample period
g = 9.80665; % Standard gravity
b = 0.0190;  % Drag coefficient (optimal)
m = 0.0837;  % Mass (optimal)
r = 0.3628;  % Radius (optimal)

%% Complementary Filter (with control input)
