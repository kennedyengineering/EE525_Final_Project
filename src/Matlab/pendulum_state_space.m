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
posX = data{:, posXIdx};            % Pendulum bob position

posYIdx = matches(data.Properties.VariableNames, 'PosY');
posY = data{:, posYIdx};            % Pendulum bob position

clickPosXIdx = matches(data.Properties.VariableNames, 'ClkPosX');
clickPosX = data{1, clickPosXIdx};  % Initial estimate for fulcrum position

clickPosYIdx = matches(data.Properties.VariableNames, 'ClkPosY');
clickPosY = data{1, clickPosYIdx};  % Initial estimate for fulcrum position

pxPerInchIdx = matches(data.Properties.VariableNames, 'PxPerInch');
pxPerInch = data{1, pxPerInchIdx};  % Conversion factor

% Plot observed pendulum position over time (combined)
figure;
hold on;
xlabel('Time (s)');
ylabel('Position (pixel)');
plot(time, posX, 'DisplayName', 'X-Axis');
plot(time, posY, 'DisplayName', 'Y-Axis');
title('Observed Pendulum Position')
legend;

% Plot observed pendulum position over time (independently)
figure;
sgtitle('Observed Pendulum Position');
hold on;

subplot(2,1,1);
plot(time, posX, 'DisplayName', 'X-Axis');
title('Pendulum Position X-Axis')
xlabel('Time (s)');
ylabel('Position (pixel)');

subplot(2,1,2);
plot(time, posY, 'DisplayName', 'Y-Axis');
title('Pendulum Position Y-Axis');
xlabel('Time (s)');
ylabel('Position (pixel)');

% Plot observed theta and angular velocity
vec = [posX, posY] - [clickPosX, clickPosY];
theta = atan2(vec(:, 1), vec(:, 2));
theta = theta - mean(theta);    % remove offset caused by marker not being centered

d_theta = diff(theta) / time(2);

figure;
hold on;
xlabel('Time (s)');
ylabel('State');
plot(time, theta, 'DisplayName', 'Theta (rad)');
plot(time(1:end-1), d_theta, 'DisplayName', 'Angular Velocity (rad/s)');
title('Observed Pendulum Angle and Angular Velocity');
legend;

% Parameters
g = 9.81;  % Gravity (m/s^2)
R = 0.4064;  % Length of pendulum (16 inches in meters)
m = 0.073;  % Mass of pendulum (73g in kg)
Ts = 1/30;  % Sampling time of 30 FPS video (s)
b = 0.02;  % Damping coefficient (initial guess)

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
x0 = [theta(1); d_theta(1)];  % Initial angle (radians) and angular velocity (rad/s)
x = zeros(2, length(time));
x(:, 1) = x0;

for k = 1:length(time) - 1
    x(:, k+1) = A_d * x(:, k);  % No input since B_d * u = 0
end

% Plot results
figure;
plot(time, x(1, :), 'r', 'DisplayName', 'Theta (rad)'); % Angular displacement
hold on;
plot(time, x(2, :), 'b', 'DisplayName', 'Angular Velocity (rad/s)'); % Angular velocity

% Set up labels and legend
xlabel('Time (s)');
ylabel('State');
legend;
grid on;
title('Discrete-Time Simulation of Pendulum', 'Interpreter', 'latex');

% TODO
% use initial guess of beta to start optimization
% find beta that minimizes error
% report beta and error
