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

% Plot observed pendulum position over time
figure;
hold on;
xlabel('time (s)');
ylabel('pixel');
plot(time, posX, 'DisplayName', 'X Position');
plot(time, posY, 'DisplayName', 'Y Position');
title('Observed Pendulum Position')
legend;

% Plot observed theta and angular velocity
vec = [posX, posY] - [clickPosX, clickPosY];
theta = atan2(vec(:, 1), vec(:, 2));
theta = theta - mean(theta);    % remove offset caused by marker not being centered

d_theta = diff(theta) / time(2);

figure;
hold on;
xlabel('time (s)');
ylabel('state');
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
plot(time, x(1, :), 'r', 'DisplayName', '\theta (rad)'); % Angular displacement
hold on;
plot(time, x(2, :), 'b', 'DisplayName', '\dot{\theta} (rad/s)'); % Angular velocity

% Set up labels and legend
xlabel('Time (s)', 'Interpreter', 'latex');
ylabel('State', 'Interpreter', 'latex');
legend({'$\theta$ (rad)', '$\dot{\theta}$ (rad/s)'}, 'Interpreter', 'latex', 'Location', 'best');
grid on;
title('Discrete-Time Simulation of Pendulum', 'Interpreter', 'latex');

% Finding the optimal beta (damping coefficient)
function error = calculateMatchError(beta, time, theta_obs, Ts, g, R, m)
    % State space model
    A_c = [0, 1; -g/R, -beta/m];
    A_d = expm(A_c * Ts);

    % Initial conditions using central difference for velocity
    d_theta_init = (theta_obs(3) - theta_obs(1)) / (2 * Ts);
    x = zeros(2, length(time));
    x(:, 1) = [theta_obs(1); d_theta_init];

    % Simulate
    for k = 1:length(time) - 1
        x(:, k+1) = A_d * x(:, k);
    end

    % Calculate frequency-weighted error
    f = 1 / (2*pi) * sqrt(g/R);  % Natural frequency
    window = exp(-time/(1/(2*pi*f)));  % Weight earlier oscillations more
    error = sqrt(mean(window .* (theta_obs - x(1, :)').^2));
end

% Grid search for initial estimation
betas = linspace(0.01, 0.1, 50);
errors = zeros(size(betas));
for i = 1:length(betas)
    errors(i) = calculateMatchError(betas(i), time, theta, Ts, g, R, m);
end

% Find best initial guess
[~, idx] = min(errors);
beta_init = betas(idx);

% Fine-tune with optimization
options = optimset('Display', 'iter', 'TolX', 1e-6);
beta_opt = fminbnd(@(b) calculateMatchError(b, time, theta, Ts, g, R, m), ...
    max(0.001, beta_init-0.01), beta_init+0.01, options);

% Final simulation with optimal beta
A_c = [0, 1; -g/R, -beta_opt/m];
A_d = expm(A_c * Ts);
d_theta_init = (theta(3) - theta(1)) / (2 * Ts);
x_final = zeros(2, length(time));
x_final(:, 1) = [theta(1); d_theta_init];
for k = 1:length(time) - 1
    x_final(:, k+1) = A_d * x_final(:, k);
end

% Plot results
figure;
plot(time, theta, 'b', 'LineWidth', 1.5, 'DisplayName', 'Observed');
hold on;
plot(time, x_final(1, :), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Simulated');
xlabel('Time (s)');
ylabel('Theta (rad)');
legend;
title(sprintf('Pendulum Motion (\\beta = %.4f, RMSE = %.4f)', beta_opt, ...
    sqrt(mean((theta - x_final(1, :)').^2))));
grid on;

fprintf('Optimal damping coefficient: %.4f\n', beta_opt);
fprintf('Final RMSE: %.4f\n', sqrt(mean((theta - x_final(1, :)').^2)));
