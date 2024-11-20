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

% --- Function Definitions ---
function column = extract_column(data, keyword)
    idx = contains(data.Properties.VariableNames, keyword);
    column = data{:, idx};
end

function table = extract_table(data, keyword)
    idx = contains(data.Properties.VariableNames, keyword);
    table = data(:, idx);
end

function noiseData = isolate_noise(dataTable)
    noiseData.noiseTable = dataTable - mean(dataTable);
end

function [accelNoiseData, gyroNoiseData] = process_multiple_files(filePaths)
    % Initialize containers for noise data
    accelNoiseData = {};
    gyroNoiseData = {};

    % Loop through each file
    for i = 1:length(filePaths)
        dataFilePath = filePaths(i);
        if ~isfile(dataFilePath)
            warning('Data file does not exist: %s', dataFilePath);
            continue;
        end

        % Read data
        data = readtable(dataFilePath);
        accelTable = extract_table(data, 'Accel');
        gyroTable = extract_table(data, 'Gyro');

        % Store processed noise data
        accelNoiseData{end+1} = isolate_noise(accelTable);
        gyroNoiseData{end+1} = isolate_noise(gyroTable);
    end
end

function process_noise(sensorType, dataTable, time, dt, fs, figure_size, yLimits)

    % Isolate noise
    noiseTable = dataTable - mean(dataTable);

    % Plot noise
    plot_table_data(noiseTable, time, figure_size, ...
        sprintf('%s Noise', sensorType), ...
        'Time (ms)', sensorType_axes_label(sensorType), ...
        sprintf('%s_Noise.tikz', sensorType));

    % Plot autocorrelation
    plot_table_autocorrelation(noiseTable, dt, figure_size, ...
        sprintf('%s Noise Autocorrelation', sensorType), ...
        sprintf('%s_Noise_Autocorrelation.tikz', sensorType));

    % Plot power spectral density
    plot_table_psd(noiseTable, fs, figure_size, ...
        sprintf('%s Noise Power Spectral Density', sensorType), yLimits, ...
        sprintf('%s_Noise_PSD.tikz', sensorType));

    % Plot rolling mean and variance
    window_length = floor(0.5 / dt); % 0.5 second window
    plot_rolling_stats(noiseTable, time, window_length, figure_size, ...
        sprintf('%s Rolling Mean and Variance', sensorType), ...
        sprintf('%s_Rolling_Mean_Variance.tikz', sensorType));
end

function plot_table_data(table, time, figure_size, titleText, xLabel, yLabel, filename)
    figure(Position = figure_size);
    sgtitle(titleText);
    for i = 1:width(table)
        subplot(width(table), 1, i);
        plot(time, table{:, i}, 'LineWidth', 1);
        title(sprintf('%s Noise', table.Properties.VariableNames{i}));
        xlabel(xLabel); ylabel(yLabel);
        xlim([time(1), time(end)]);
        grid on;
    end
    drawnow;
    matlab2tikz(filename, 'width', '0.9\linewidth', 'height', '0.9\textheight');
end

function plot_table_autocorrelation(table, dt, figure_size, titleText, filename)
    figure(Position = figure_size);
    sgtitle(titleText);
    for i = 1:width(table)
        [r, lags] = xcorr(table{:, i}, 'unbiased');
        taus = lags * dt;
        subplot(width(table), 1, i);
        plot(taus, r, 'LineWidth', 1);
        title(sprintf('%s Autocorrelation', table.Properties.VariableNames{i}));
        xlabel('\tau (s)');
        ylabel('Autocorrelation');
        xlim([taus(1), taus(end)]);
        % Temporary fix for y-axis limits
        %ylim([-3*10^(-6), 3*10^(-6)]);
        grid on;
    end
    drawnow;
    matlab2tikz(filename, 'width', '1.0\linewidth');
end

function plot_table_psd(table, fs, figure_size, titleText, yLimits, filename)
    figure(Position = figure_size);
    sgtitle(titleText);
    for i = 1:width(table)
        [pxx, f] = periodogram(table{:, i}, rectwin(length(table{:, i})), length(table{:, i}), fs, 'psd');
        subplot(width(table), 1, i);
        plot(f, pow2db(pxx), 'LineWidth', 1);
        title(sprintf('%s Power Spectral Density', table.Properties.VariableNames{i}));
        xlabel('Frequency (Hz)');
        ylabel('Power/frequency (dB/Hz)');
        xlim([f(1), f(end)]);
        ylim(yLimits);
        grid on;
    end
    drawnow;
    matlab2tikz(filename, 'width', '1.0\linewidth');
end
