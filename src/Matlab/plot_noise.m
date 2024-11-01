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

    % Plot Accelerometer Noise to Describe Stationary and Ergodic
    desired_window_size = 0.5; %s
    window_size = floor(desired_window_size / dt);
    window_size_seconds = window_size * dt * 1000;

    figure(Position=figure_size);
    sgtitle(sprintf('Accelerometer Noise Rolling Mean and Variance (Window Length: %d ms)', window_size_seconds));
    hold on;
    subplotcount = 1;

    % Loop through each entry in the table (assuming gyroscope data)
    for entry = table{1}
        % Extract values and compute statistics
        values = entry{:, :};
        X_mean = mean(values);
        X_squared_mean = mean(values.^2);
        X_std = std(values);
        X_var = var(values);

        % Rolling Mean Tolerances
        tolerance = 0.02 * max(abs(values));
        upper_tolerance = X_mean + tolerance;
        lower_tolerance = X_mean - tolerance;

        % Display tolerance information
        fprintf('Rolling Mean Upper tolerance band: %.4e\n', upper_tolerance);
        fprintf('Rolling Mean Lower tolerance band: %.4e\n', lower_tolerance);

        % Display calculated statistics
        X_name = string(entry.Properties.VariableNames(1));

        fprintf('\n');
        fprintf('%s noise mean: %f\n', X_name, X_mean);
        fprintf('%s noise squared mean: %f\n', X_name, X_squared_mean);
        fprintf('%s noise variance: %f\n', X_name, X_var);

        % Compute rolling mean and variance
        rolling_mean = movmean(values, window_size);
        rolling_var = movvar(values, window_size);

        % Plot Rolling Mean with Tolerance Bands for Gyroscope Noise (Enhanced Labeling)
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_mean, 'LineWidth', 1.5);
        hold on;
        yline(X_mean, 'Color', 'r', 'LineWidth', 1.5);
        yline(upper_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        yline(lower_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        hold off;
        title(sprintf('%s Rolling Mean', X_name));
        xlabel('Time (ms)');
        ylabel('Mean (m/s^2)');
        xlim([time(1), time(end) + 5]);

        % Annotate directly on the plot with adjusted positions and bold text
        text(time(end) * 1.02, X_mean, 'Mean', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.02, upper_tolerance * 1.02, '+2%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.02, lower_tolerance * 0.98, '-2%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');

        % Rolling Variance Tolerances
        var_mean = mean(X_var);
        tolerance = 0.6 * var_mean; % 60%
        upper_tolerance = var_mean + tolerance;
        lower_tolerance = var_mean - tolerance;

        % Display tolerance information
        fprintf('Rolling Variance Upper tolerance band: %.4e\n', upper_tolerance);
        fprintf('Rolling Variance Lower tolerance band: %.4e\n', lower_tolerance);

        % Plot Rolling Variance for Accel Noise
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_var, 'LineWidth', 1.5);
        title(sprintf('%s Rolling Variance', X_name));
        hold on;
        yline(var_mean, 'Color', 'r', 'LineWidth', 1.5);
        yline(upper_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        yline(lower_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        hold off;
        xlabel('Time (ms)');
        ylabel('Variance (m/s^2)^2');
        xlim([time(1), time(end) + 5]);

         % Annotate directly on the plot with adjusted positions and bold
         % text (NOT related with actual tolerance percentages)
        text(time(end) * 1.04, var_mean * 1.2, 'Mean', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.04, upper_tolerance * 1.3, '+60%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.04, lower_tolerance * 0.6, '-60%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
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
    desired_window_size = 0.5; %s
    window_size = floor(desired_window_size / dt);
    window_size_seconds = window_size * dt * 1000;

    figure(Position=figure_size);
    sgtitle(sprintf('Gryoscope Noise Rolling Mean and Variance (Window Length: %d ms)', window_size_seconds));
    hold on;
    subplotcount = 1;

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
        rolling_mean = movmean(values, window_size);
        rolling_var = movvar(values, window_size);

        % Plot Rolling Mean with Tolerance Bands for Gyroscope Noise (Enhanced Labeling)
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_mean, 'LineWidth', 1.5);
        hold on;
        yline(X_mean, 'Color', 'r', 'LineWidth', 1.5);
        yline(upper_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        yline(lower_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        hold off;
        title(sprintf('%s Rolling Mean', X_name));
        xlabel('Time (ms)');
        ylabel('Mean (rad/s)');
        xlim([time(1), time(end) + 5]);

        % Annotate directly on the plot with adjusted positions and bold text
        text(time(end) * 1.02, X_mean, 'Mean', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.02, upper_tolerance * 1.02, '+2%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.02, lower_tolerance * 0.98, '-2%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');

        % Rolling Variance Tolerances
        var_mean = mean(X_var);
        tolerance = 0.6 * var_mean; % 60%
        upper_tolerance = var_mean + tolerance;
        lower_tolerance = var_mean - tolerance;

        % Display tolerance information
        fprintf('Rolling Variance Upper tolerance band: %.4e\n', upper_tolerance);
        fprintf('Rolling Variance Lower tolerance band: %.4e\n', lower_tolerance);

        % Plot Rolling Variance for Accel Noise
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(time, rolling_var, 'LineWidth', 1.5);
        title(sprintf('%s Rolling Variance', X_name));
        hold on;
        yline(var_mean, 'Color', 'r', 'LineWidth', 1.5);
        yline(upper_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        yline(lower_tolerance, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 2);
        hold off;
        xlabel('Time (ms)');
        ylabel('Variance (rad/s)^2');
        xlim([time(1), time(end) + 5]);

         % Annotate directly on the plot with adjusted positions and bold
         % text (NOT related with actual tolerance percentages)
        text(time(end) * 1.04, var_mean * 1.2, 'Mean', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.04, upper_tolerance * 1.5, '+60%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        text(time(end) * 1.04, lower_tolerance * 0.2, '-60%', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
    end
end
