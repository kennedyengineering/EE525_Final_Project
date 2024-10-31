% Plot noise

clear; clc;

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

% Number of lags
max_tau = 60;  % Maximum delay in seconds
max_lag = floor(max_tau / dt);  % Maximum lag in number of samples

% Analyze accel noise
for table={accelNoiseTable}

    % Plot noise
    figure;
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
    figure;
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
    figure;
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

    % Display noise mean and variance
    for entry=table{1}

        % Compute mean and variance
        values = entry{:, :};
        X_mean = mean(values);
        X_var = var(values);

        % Display
        X_name = string(entry.Properties.VariableNames(1));

        fprintf('\n');
        fprintf('%s noise mean: %f\n', X_name, X_mean);
        fprintf('%s noise variance: %f\n', X_name, X_var);
    end

end
