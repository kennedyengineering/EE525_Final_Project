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

        % Plot autocorrelation
        X_name = entry.Properties.VariableNames(1);

        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(lags * dt, R_estimated, 'LineWidth', 1.5);
        xlabel('\tau');
        ylabel(sprintf('R_{%s}(\\tau)', string(X_name)));
        title(strcat(X_name, ' Autocorrelation'));
        grid on;

        % Calculate the power spectral density
        % https://www.mathworks.com/help/signal/ug/power-spectral-density-estimates-using-fft.html
        R_estimated = R_estimated(2:end);
        N = length(R_estimated);
        fs = 1/dt;

        xdft = fft(R_estimated);
        xdft = xdft(1:N/2+1);
        psdx = (1/(fs*N)) * abs(xdft).^2;
        psdx(2:end-1) = 2*psdx(2:end-1);
        freq = 0:fs/N:fs/2;

        % Plot power spectral density
        subplot(width(table{1}), 2, subplotcount);
        subplotcount = subplotcount + 1;
        plot(freq, pow2db(psdx), 'LineWidth', 1.5);
        xlabel('Frequency (Hz)');
        ylabel('Power/Frequency (dB/Hz)');
        xlim([0, freq(end)]);
        title(strcat(X_name,' Power Spectral Density'));
        grid on;

    end
end
