% Plot noise
clear; clc; close all;

dataFilePath = "../../data/static/static_pendulum_log_raw_4g_500dps_2.csv";
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);
time = extract_column(data, 'Time');
accelTable = extract_table(data, 'Accel');
gyroTable = extract_table(data, 'Gyro');

% Sampling information
dt = 0.008; % seconds per sample
fs = 1 / dt;

% Defaults figure size
figure_size = [100, 100, 1000, 1200];
accel_yLimits = [-100, -20];
gyro_yLimits = [-120, -50];

% Process accelerometer and gyroscope noise must be processed separately
process_noise('Accelerometer', accelTable, time, dt, fs, figure_size, accel_yLimits);
process_noise('Gyroscope', gyroTable, time, dt, fs, figure_size, gyro_yLimits);

% Process for Ensemble Average
dataFiles = [
    "../data/static/static_pendulum_log_raw_4g_500dps_1.csv";
    "../../data/static/static_pendulum_log_raw_4g_500dps_2.csv";
    "../../data/static/static_pendulum_log_raw_4g_500dps_3.csv"
];

accel_ensemble_yLimits = [-60, -20];
gyro_ensemble_yLimits = [-80, -30];

% Process each file and aggregate results
[accelNoiseData, gyroNoiseData] = process_multiple_files(dataFiles);

% Plot ensemble average autocorrelation and PSD results
plot_ensemble_autocorr(accelNoiseData, dt, 'Accelerometer', figure_size);
plot_ensemble_autocorr(gyroNoiseData, dt, 'Gyroscope', figure_size);
