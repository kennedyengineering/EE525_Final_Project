% Compute autocorrelation

clear; clc;

% Define the path to the data file
dataFilePath = "../../data/static_log_raw_4g_500dps.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);

% Identify accelerometer and gyroscope data
accelIdx = contains(data.Properties.VariableNames, 'Accel');
accelTable = data(:, accelIdx);

gyroIdx = contains(data.Properties.VariableNames, 'Gyro');
gyroTable = data(:, gyroIdx);

% Define constants
dt = 0.008;

% Number of lags
max_tau = 60;  % Maximum delay in seconds
max_lag = floor(max_tau / dt);  % Maximum lag in number of samples
lags = -max_lag:max_lag;  % Lags for autocorrelation estimation

% Preallocate the autocorrelation array
R_estimated = zeros(size(lags));

% Plot accelerometer autocorrelations
for table={accelTable, gyroTable}

    % Create new figure
    figure;
    hold on;
    subplotcount = 1;

    for entry=table{1}

        % Calculate the autocorrelation
        X = entry{:, :};

        R_estimated = xcov(X, max_lag) / var(X);

        % Plot
        X_name = entry.Properties.VariableNames(1);

        subplot(width(table{1}), 1, subplotcount);
        subplotcount = subplotcount + 1;
        plot(lags * dt, R_estimated, 'LineWidth', 1.5);
        xlabel('\tau');
        ylabel(sprintf('R_{%s}(\\tau)', string(X_name)));
        title(X_name);
        grid on;

    end
end
