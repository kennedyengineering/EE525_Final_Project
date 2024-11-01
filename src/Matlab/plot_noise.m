% Plot noise

clear; clc; close all;

% Define the path to the data file
dataFilePath = "../../data/static_log_raw_4g_500dps.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);

% Identify relavant data
timeIdx = contains(data.Properties.VariableNames, 'Time');
time = data{:, timeIdx};

accelIdx = contains(data.Properties.VariableNames, 'Accel');
accelTable = data(:, accelIdx);

gyroIdx = contains(data.Properties.VariableNames, 'Gyro');
gyroTable = data(:, gyroIdx);

% Isolate the noise
accelNoiseTable = accelTable - mean(accelTable);
gyroNoiseTable = gyroTable - mean(gyroTable);

% Sampling information
dt = 0.008; % seconds per sample
fs = 1/dt;

% Figure Size in order to plots scales
figure_size = [100, 100, 1000, 800];

% Analyze accelerometer noise
for table={accelNoiseTable}

    % Plot noise
    figure(Position=figure_size);
    sgtitle('Accelerometer Noise');
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Plot on subplot
        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;

        X_name = entry.Properties.VariableNames(1);

        plot(time, entry{:, :}, 'LineWidth', 1);
        title(strcat(X_name,' Noise'));
        xlabel('Time (ms)');
        xlim([time(1), time(end)]);
        ylabel('Linear Acceleration (m/s^2)');
        grid on;
    end

    % Plot autocorrelation
    figure(Position=figure_size);
    sgtitle('Accelerometer Noise Autocorrelation (Unbiased Estimate)');
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Compute autocorrelation
        [r, lags] = xcorr(entry{:, :}, 'unbiased');
        taus = lags * dt;   % Convert from samples to seconds

        % Plot on subplot
        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;

        X_name = entry.Properties.VariableNames(1);

        plot(taus, r, 'LineWidth', 1);
        title(strcat(X_name,' Autocorrelation'));
        xlabel('\tau (s)');
        xlim([taus(1), taus(end)]);
        ylabel('Linear Acceleration Squared (m/s^2)^2');
        grid on;
    end

    % Plot power spectral density
    figure(Position=figure_size);
    sgtitle('Accelerometer Noise Power Spectral Density (Periodogram Estimate)');
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Compute power spectral density
        values = entry{:, :};
        [pxx, f] = periodogram(values, rectwin(length(values)), length(values), fs, 'psd');

        % Plot on subplot
        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;

        X_name = entry.Properties.VariableNames(1);

        plot(f, pow2db(pxx), 'LineWidth', 1);
        title(strcat(X_name,' Power Spectral Density'));
        xlabel('Frequency (Hz)');
        xlim([f(1), f(end)]);
        ylabel('Power/frequency (db/Hz)');
        grid on;
    end

    % Plot Accelerometer Noise
    figure(Position=figure_size);
    sgtitle('Accelerometer Noise Rolling Mean and Variance');
    hold on;
    subplotcount = 1;

    mean_interval = mean(diff(time)) / 1000; % in ms
    windowSize = round(0.5 / mean_interval);

    for entry = table{1}
        % Extract values and compute statistics
        values = entry{:, :};
        X_mean = mean(values);
        X_squared_mean = mean(values.^2);
        X_std = std(values);
        X_var = var(values);

        tolerance = 0.02 * max(abs(values)); % 2% of the maximum absolute value
        upper_tolerance = X_mean + tolerance;
        lower_tolerance = X_mean - tolerance;

        % Display tolerance information
        fprintf('Upper tolerance band: %.4e\n', upper_tolerance);
        fprintf('Lower tolerance band: %.4e\n', lower_tolerance);

        % Display calculated statistics
        X_name = string(entry.Properties.VariableNames(1));

        fprintf('\n');
        fprintf('%s noise mean: %f\n', X_name, X_mean);
        fprintf('%s noise squared mean: %f\n', X_name, X_squared_mean);
        fprintf('%s noise variance: %f\n', X_name, X_var);

        % Compute rolling mean and variance
        rolling_mean = movmean(values, windowSize);
        rolling_var = movvar(values, windowSize);

        % Plot Rolling Mean with Tolerance Bands
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_mean, 'LineWidth', 1.5);
        hold on;
        yline(X_mean, 'Color', 'r', 'LineWidth', 1.5);
        yline(upper_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
        yline(lower_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
        hold off;
        title(strcat(X_name, ' Rolling Mean'));
        xlabel('Time (ms)');
        ylabel('Mean');

        % Plot Rolling Variance
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_var, 'LineWidth', 1.5);
        hold on;
        hold off;
        title(strcat(X_name, ' Rolling Variance'));
        xlabel('Time (ms)');
        ylabel('Variance');
    end
end

% Analyze gyroscope noise
for table={gyroNoiseTable}

    % Plot noise
    figure(Position=figure_size);
    sgtitle('Gyroscope Noise');
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Plot on subplot
        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;

        X_name = entry.Properties.VariableNames(1);

        plot(time, entry{:, :}, 'LineWidth', 1);
        title(strcat(X_name,' Noise'));
        xlabel('Time (ms)');
        xlim([time(1), time(end)]);
        ylabel('Angular Velocity (rad/s)');
        grid on;
    end

    % Plot autocorrelation
    figure(Position=figure_size);
    sgtitle('Gyroscope Noise Autocorrelation (Unbiased Estimate)');
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Compute autocorrelation
        [r, lags] = xcorr(entry{:, :}, 'unbiased');
        taus = lags * dt;   % Convert from samples to seconds

        % Plot on subplot
        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;

        X_name = entry.Properties.VariableNames(1);

        plot(taus, r, 'LineWidth', 1);
        title(strcat(X_name,' Autocorrelation'));
        xlabel('\tau (s)');
        xlim([taus(1), taus(end)]);
        ylabel('Angular Velocity Squared (rad/s)^2');
        grid on;
    end

    % Plot power spectral density
    figure(Position=figure_size);
    sgtitle('Gyroscope Noise Power Spectral Density (Periodogram Estimate)');
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Compute power spectral density
        values = entry{:, :};
        [pxx, f] = periodogram(values, rectwin(length(values)), length(values), fs, 'psd');

        % Plot on subplot
        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;

        X_name = entry.Properties.VariableNames(1);

        plot(f, pow2db(pxx), 'LineWidth', 1);
        title(strcat(X_name,' Power Spectral Density'));
        xlabel('Frequency (Hz)');
        xlim([f(1), f(end)]);
        ylabel('Power/frequency (db/Hz)');
        grid on;
    end

    % Plots to Describe Stationary and Ergodic
    figure(Position=figure_size);
    sgtitle('Gryoscope Noise Rolling Mean and Variance');
    hold on;
    subplotcount = 1;

    mean_interval = mean(diff(time)) / 1000; % in ms
    windowSize = round(0.5 / mean_interval);

    % Loop through each entry in the table (assuming gyroscope data)
    for entry = table{1}
        % Extract values and compute statistics
        values = entry{:, :};
        X_mean = mean(values);
        X_squared_mean = mean(values.^2);
        X_std = std(values);
        X_var = var(values);


        % Plotting for Stationary
        tolerance = 0.02 * max(abs(values));
        upper_tolerance = X_mean + tolerance;
        lower_tolerance = X_mean - tolerance;

        % Display tolerance information
        fprintf('Upper tolerance band: %.4e\n', upper_tolerance);
        fprintf('Lower tolerance band: %.4e\n', lower_tolerance);

        % Display calculated statistics
        X_name = string(entry.Properties.VariableNames(1));

        fprintf('\n');
        fprintf('%s noise mean: %f\n', X_name, X_mean);
        fprintf('%s noise squared mean: %f\n', X_name, X_squared_mean);
        fprintf('%s noise variance: %f\n', X_name, X_var);

        % Compute rolling mean and variance
        rolling_mean = movmean(values, windowSize);
        rolling_var = movvar(values, windowSize);

        % Plot Rolling Mean with Tolerance Bands
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_mean, 'LineWidth', 1.5);
        hold on;
        yline(X_mean, 'Color', 'r', 'LineWidth', 1.5);
        yline(upper_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
        yline(lower_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
        hold off;
        title(strcat(X_name, ' Rolling Mean'));
        xlabel('Time (ms)');
        ylabel('Mean');

        % Plot Rolling Variance
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_var, 'LineWidth', 1.5);
        hold on;
        hold off;
        title(strcat(X_name, ' Rolling Variance'));
        xlabel('Time (ms)');
        ylabel('Variance');
    end
end
