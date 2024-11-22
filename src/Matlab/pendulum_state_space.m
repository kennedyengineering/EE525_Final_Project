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

% Define the model
function x = simulate_system(g, r, m, b, ts, duration, x0)
    % Parameters
    % g - gravity (m/s^2)
    % r - radius of pendulum (m)
    % m - mass of pendulum (kg)
    % ts - sample time (s)
    % b - damping coefficient
    % X - state (rad, rad/s)
    % X0 - initial state (rad, rad/s)

    % Continuous-time state-space matrices
    A_c = [0, 1; -g/r, -b/m];
    B_c = [0; 0];
    C_c = eye(2);  % Identity matrix
    D_c = [0; 0];

    % Discretization
    A_d = expm(A_c * ts);
    B_d = integral(@(t) expm(A_c * t) * B_c, 0, ts, 'ArrayValued', true);
    C_d = C_c;
    D_d = D_c;

    % Initial conditions
    x = zeros(2, duration);
    x(:, 1) = x0;

    for k = 1:duration - 1
        x(:, k+1) = A_d * x(:, k);  % No input since B_d * u = 0
    end
end

% Theoretical parameters
G = 9.81;  % Gravity (m/s^2)
R = 0.4064;  % Length of pendulum (16 inches in meters)
M = 0.073;  % Mass of pendulum (73g in kg)
Ts = 1/30;  % Sampling time of 30 FPS video (s)
B = 0.02;  % Damping coefficient (initial guess)

% Simulating the system
X0 = [theta(1); d_theta(1)];
Duration = length(time);
Ts = time(2);
X_theoretical = simulate_system(G, R, M, B, Ts, Duration, X0);

% Plot results
figure;
title('Theoretical Discrete-Time Simulation of Pendulum');
hold on;
plot(time, X_theoretical(1, :), 'r', 'DisplayName', 'Theta (rad)'); % Angular displacement
plot(time, X_theoretical(2, :), 'b', 'DisplayName', 'Angular Velocity (rad/s)'); % Angular velocity
xlabel('Time (s)');
ylabel('State');
legend;
grid on;

figure;
title('Theoretical Discrete-Time Simulation of Pendulum vs Observed State');
hold on;
plot(time, X_theoretical(1, :), 'r', 'DisplayName', 'Simulated Theta (rad)');
plot(time, X_theoretical(2, :), 'b', 'DisplayName', 'Simulated Angular Velocity (rad/s)');
plot(time, theta, 'DisplayName', 'Observed Theta (rad)');
plot(time(1:end-1), d_theta, 'DisplayName', ' Observed Angular Velocity (rad/s)');
xlabel('Time (s)');
ylabel('State');
legend;
grid on;

% Define objective function
function error = objective(params, ts, duration, x0, true_theta)
    x = simulate_system(params(1), params(2), params(3), params(4), ts, duration, x0);
    error = sum((x(1,:) - true_theta').^2);
end

objective_fn = @(params) objective(params, Ts, Duration, X0, theta);

% Optimization using fminsearch to minimize the objective function
initial_guess = [G, R, M, B];
[optimal_params, squared_error] = fminsearch(objective_fn, initial_guess);
disp("Optimal parameters");
disp(optimal_params);
disp("Minimum squared error");
disp(squared_error);

% Plot results
X_optimal = simulate_system(optimal_params(1), optimal_params(2), optimal_params(3), optimal_params(4), Ts, Duration, X0);

figure;
title('Optimal Discrete-Time Simulation of Pendulum');
hold on;
plot(time, X_optimal(1, :), 'r', 'DisplayName', 'Theta (rad)'); % Angular displacement
plot(time, X_optimal(2, :), 'b', 'DisplayName', 'Angular Velocity (rad/s)'); % Angular velocity
xlabel('Time (s)');
ylabel('State');
legend;
grid on;

figure;
title('Optimal Discrete-Time Simulation of Pendulum vs Observed State');
hold on;
plot(time, X_optimal(1, :), 'r', 'DisplayName', 'Simulated Theta (rad)');
plot(time, X_optimal(2, :), 'b', 'DisplayName', 'Simulated Angular Velocity (rad/s)');
plot(time, theta, 'DisplayName', 'Observed Theta (rad)');
plot(time(1:end-1), d_theta, 'DisplayName', ' Observed Angular Velocity (rad/s)');
xlabel('Time (s)');
ylabel('State');
legend;
grid on;
