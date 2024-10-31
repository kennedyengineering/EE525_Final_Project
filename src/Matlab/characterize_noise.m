% Characterize noise

clear; clc;

% Define the path to the data file
dataFilePath = "../../data/static_log_raw_4g_500dps.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);

% Extract the first column as X
x = data{:, 1};

% Get variable names for X
xName = data.Properties.VariableNames(1);

autocorr(data.AccelX,NumLags=100);

fs = 125;

N = length(data.AccelX(2:end));
xdft = fft(data.AccelX(2:end));
xdft = xdft(1:N/2+1);
psdx = (1/(fs*N)) * abs(xdft).^2;
psdx(2:end-1) = 2*psdx(2:end-1);
freq = 0:fs/length(data.AccelX(2:end)):fs/2;

plot(freq,pow2db(psdx))
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")
