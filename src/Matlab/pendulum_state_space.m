% Modeling pendulum motion from video analysis

clc; clear; close all;

% Define the path to the data file
dataFilePath = "../../data/vision2_analysis/usb_pendulum_video_1_analysis.csv";

% Check if the file exists
if ~isfile(dataFilePath)
    error('Data file does not exist: %s', dataFilePath);
end

% Read data from log file into a table
data = readtable(dataFilePath);

% Identify relevant data
timeIdx = matches(data.Properties.VariableNames, 'Timestamp');
time = data{:, timeIdx};

posXIdx = matches(data.Properties.VariableNames, 'PosX');
posX = data{:, posXIdx};

posYIdx = matches(data.Properties.VariableNames, 'PosY');
posY = data{:, posYIdx};

clickPosXIdx = matches(data.Properties.VariableNames, 'ClkPosX');
clickPosX = data{1, clickPosXIdx};

clickPosYIdx = matches(data.Properties.VariableNames, 'ClkPosY');
clickPosY = data{1, clickPosYIdx};

pxPerInchIdx = matches(data.Properties.VariableNames, 'PxPerInch');
pxPerInch = data{1, pxPerInchIdx};

% Parameters
g = 9.81;  % Gravity (m/s^2)
R = 0.4064;  % Length of pendulum (16 inches in meters)
m = 0.073;  % Mass of pendulum (73g in kg)
Ts = 1/30;  % Sampling time of 30 FPS video (s)

b = 0.1;  % Damping coefficient (initially unknown)

% Continuous-time state-space matrices
A_c = [0, 1; -g/R, -b/m];
B_c = [0; 0];
C_c = eye(2);  % Identity matrix
D_c = [0; 0];

% Discretization
A_d = expm(A_c * Ts);
B_d = integral(@(t) expm(A_c * t) * B_c, 0, Ts, 'ArrayValued', true);
C_d = C_c;
D_d = D_c;

% Display results
disp('Continuous-Time A Matrix:'); disp(A_c);
disp('Discrete-Time A Matrix:'); disp(A_d);
disp('Discrete-Time B Matrix:'); disp(B_d);
disp('C Matrix:'); disp(C_d);
disp('D Matrix:'); disp(D_d);

% Simulating the system (optional)
% Initial conditions
x0 = [0.1; 0];  % Initial angle (radians) and angular velocity (rad/s)
time = 0:Ts:5;  % Simulate for 5 seconds
x = zeros(2, length(time));
x(:, 1) = x0;

for k = 1:length(time) - 1
    x(:, k+1) = A_d * x(:, k);  % No input since B_d * u = 0
end

% Plot results
figure;
plot(time, x(1, :), 'r', 'DisplayName', '\theta (rad)'); % Angular displacement
hold on;
plot(time, x(2, :), 'b', 'DisplayName', '\dot{\theta} (rad/s)'); % Angular velocity

% Set up labels and legend
xlabel('Time (s)', 'Interpreter', 'latex');
ylabel('State', 'Interpreter', 'latex');
legend({'$\theta$ (rad)', '$\dot{\theta}$ (rad/s)'}, 'Interpreter', 'latex', 'Location', 'best');
grid on;
title('Discrete-Time Simulation of Pendulum', 'Interpreter', 'latex');