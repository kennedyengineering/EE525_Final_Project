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


% Function to Compute and Plot the Ellipsoid
function [x_coords,y_coords] = ellipse2(G,Npoints)
    %% Draw the perimeter of the ellipsoid in R^2 such that x'*G*x = 1
    % Citation:
    % https://www.mathworks.com/matlabcentral/answers/86615−how−to−plot−an−ellipse
    [V,E] = eigs(G,2,'smallestabs'); % Index 1 will be smallest, so major axis.
    E = diag(E);
    b = 1/sqrt(max(E));
    a = 1/sqrt(min(E));
    switch nargin
        case 2
            t = linspace(0,2*pi,Npoints);
        case 1
            t = linspace(0,2*pi,1e2);
        otherwise
            error('ellipse2:nargin','Unexpected number of input arguments.');
    end
    % This gives a normal ellipse with major axis dead horizontal.
    x = a*cos(t);
    y = b*sin(t);
    % V(1,2) is vertical component of semi−major axis endpoint.
    % V(1,1) is horizontal component of semi−major axis endpoint.
    theta = atan2(V(1,2),V(1,1));
    % Rotation matrix
    R = [cos(theta), -sin(theta);
        sin(theta), cos(theta)];
    % Rotate coordinates of normal ellipse
    C = R*[x;y];
    x_coords = C(1,:);
    y_coords = C(2,:);
    if nargout == 0
        plot(x_coords,y_coords);
    end
end

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

function plot_observability_ellipsoid_system(g, r, m, b, ts, title_str, xlabel_str, ylabel_str)
    % Continuous-time state-space matrices
    A_c = [0, 1; -g/r, -b/m];
    C_c = eye(2);  % Identity matrix

    % Discretize the system
    A_d = expm(A_c * ts);
    C_d = C_c;

    % Compute Observability Gramian
    n_states = size(A_d, 1);
    O_d = [];
    for i = 0:n_states-1
        O_d = [O_d; C_d * (A_d^i)];
    end
    G_o_d = O_d' * O_d;

    % Plot observability ellipsoid
    plot_observability_ellipsoid(G_o_d, title_str, xlabel_str, ylabel_str);
end

function plot_transformed_observability_ellipsoid(g, r, m, b, ts, title_str, xlabel_str, ylabel_str)
    % Continuous-time state-space matrices
    A_c = [0, 1; -g/r, -b/m];
    C_c = eye(2);  % Identity matrix

    % Discretize the system
    A_d = expm(A_c * ts);
    C_d = C_c;

    % Compute Observability Gramian
    n_states = size(A_d, 1);
    O_d = [];
    for i = 0:n_states-1
        O_d = [O_d; C_d * (A_d^i)];
    end
    G_o_d = O_d' * O_d;

    % Transformation matrix
    [V, E] = eig(G_o_d);
    T = sqrt(E) * V';
    Obz = [C_d / T; C_d / T * T * A_d / T];
    Gz = Obz' * Obz;

    % Plot transformed observability ellipsoid
    plot_observability_ellipsoid(Gz, title_str, xlabel_str, ylabel_str);
end

function plot_observability_ellipsoid(G, title_str, xlabel_str, ylabel_str)
    % Eigen decomposition
    [eig_vectors, eig_values] = eig(G);
    eigenvalues = diag(eig_values);
    [sorted_eigenvalues, idx] = sort(eigenvalues, 'descend');
    sorted_eigenvectors = eig_vectors(:, idx);

    % Define semi-major and semi-minor axes
    a = 1 / sqrt(sorted_eigenvalues(1));
    b = 1 / sqrt(sorted_eigenvalues(2));

    % Generate ellipse coordinates
    theta = linspace(0, 2*pi, 100);
    ellipse_x = a * cos(theta);
    ellipse_y = b * sin(theta);
    ellipse_coords = [ellipse_x; ellipse_y];
    rotated_ellipse = sorted_eigenvectors * ellipse_coords;

    % Most and least observable directions
    most_observable_vector = sorted_eigenvectors(:, 1);
    least_observable_vector = sorted_eigenvectors(:, 2);

    % Plot
    figure;
    plot(rotated_ellipse(1, :), rotated_ellipse(2, :), 'k-', 'LineWidth', 1.5);
    hold on;
    quiver(0, 0, most_observable_vector(1), most_observable_vector(2), a, ...
        'Color', 'b', 'LineWidth', 1.5, 'MaxHeadSize', 2);
    quiver(0, 0, least_observable_vector(1), least_observable_vector(2), b, ...
        'Color', 'r', 'LineWidth', 1.5, 'MaxHeadSize', 2);
    xlabel(xlabel_str, 'Interpreter', 'latex', 'FontSize', 14);
    ylabel(ylabel_str, 'Interpreter', 'latex', 'FontSize', 14);
    title(title_str, 'Interpreter', 'latex', 'FontSize', 16);
    legend('Ellipsoid', 'Most Observable', 'Least Observable', 'Location', 'best');
    grid on;
    axis equal;
    hold off;
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

% Compute and plot original observability ellipsoid
plot_observability_ellipsoid_system(G, R, M, B, Ts, ...
    'Original Observability Ellipsoid', ...
    '$\theta$ (Angular Displacement)', ...
    '$\dot{\theta}$ (Angular Velocity)');

% Compute and plot transformed observability ellipsoid
plot_transformed_observability_ellipsoid(G, R, M, B, Ts, ...
    'Transformed Observability Ellipsoid', ...
    '$z_1$ (Transformed State 1)', ...
    '$z_2$ (Transformed State 2)');

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

% Show status before optimization
disp('Unoptimized parameters');
disp(initial_guess)
disp('Unoptimized squared error');
disp(objective_fn(initial_guess));

% Show status after optimization
disp("Optimal parameters");
disp(optimal_params);
disp("Optimal squared error");
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
