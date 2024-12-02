% V2G simulation environment to demonstrate grid load balancing using EVs

% January (Winter) in Delhi 2023
%% Assumptions:
% 1. n vehicles, each with their own battery capacity, maximum charge and
%    discharge rates, initial SOCs, time of connection and disconnection

% 2. The objective of this code is to support load balancing of the grid.

% 3. The grid will provide the load forecast to the charge point and
%    according to the EVCC and SECC capability, will provide power to the grid
%    to acheive load balancing.

clear
clc
close all

% Initialising Assumed values for the n vehicles:

n = 100000;     %number of chargers  
% Indexing each charger in the system.
Charger_Index = [1:1:n];

% Initial SOCs: SOC_0
% creating a vector of SOCs drawn from a uniform distribution from the
% range of 20% to 80% SOC for 100 vehicles.

SOC = randi([20, 60], 1, n);      % in percent

% Time of connection of a vehicle (uniform distribution) (initial
% condition)
T_connection = zeros(1, n);

% Duration of Time connected to charger (hours)
T_connectedDur = randi([6, 10], 1, n);

% Time of disconnection of a vehicle
T_disconnection = T_connection + T_connectedDur;


% Randomly generated Maximum charging rates of n vehicles 
% (min = P_max_LL kW, max = P_max_UL kW) 
% normal distribution with a mean = [(P_max_LL + P_max_UL)/2] kW 
% and standard deviation = 8 kW

P_max_UL = 30;      % highest P_max of all vehicles in kW
P_max_LL = 4;       % lowest P_max of all vehicles in kW
P_max_mean = (P_max_LL + P_max_UL)/2;   

P_max_mu = P_max_mean;     % Mean of the distribution in kW
P_max_sigma = 8;  % Standard deviation in kW

% Initialize the P_max vector to store values within the range
P_max = [];

% Continue generating numbers until we have the desired count
while length(P_max) < n
    % Generate a batch of random numbers
    P_max_batch = normrnd(P_max_mu, P_max_sigma, [1, n]);
    
    % Keep only the numbers within the range [4, 30] kW
    P_max_batch = P_max_batch(P_max_batch >= P_max_LL & P_max_batch <= P_max_UL);
    
    % Append valid numbers to the vector
    P_max = [P_max, P_max_batch];
end

% Trim the vector to exactly 'n' elements in case it exceeded
P_max = P_max(1:n);

P_max = round(sort(P_max, 'ascend'),2);      %in kW

% Randomly generated Battery Capacity of the n vehicles
% (min = E_LL kW, max = E_UL kW) 
% normal distribution with a mean = [(E_LL + E_UL)/2] kWh 
% and standard deviation = 15 kWh

E_UL = 100;      % highest P_max of all vehicles in kWh
E_LL = 30;       % lowest P_max of all vehicles in kWh
E_mean = (E_LL + E_UL)/2;   


E_mu = E_mean;     % Mean of the distribution
E_sigma = 15;  % Standard deviation 

% Initialize the E vector to store values within the range
E = [];

% Continue generating numbers until we have the desired count
while length(E) < n
    % Generate a batch of random numbers
    E_batch = normrnd(E_mu, E_sigma, [1, n]);
    
    % Keep only the numbers within the range [30, 100]
    E_batch = E_batch(E_batch >= 30 & E_batch <= 100);
    
    % Append valid numbers to the vector
    E = [E, E_batch];
end

% Trim the vector to exactly 'n' elements in case it exceeded
E = E(1:n);  

E = round(sort(E, 'ascend'),2);      %in kWh

Car_models = [P_max', E'];


% Initialising the input forecast load curve

inputData = "LoadDataDelhiWinter.csv";

%read data

loadData = readtable(inputData);

time = loadData.time;
load_forecast = loadData.HourlyDemandMet_inMW_*1000;    %in kW

%% ALL ASSUMPTIONS AND VECTORS INITIALISED

% ----------------------------------------------------------------------------

%% CONTROL ALGORITHM:
% initialising initial vectors
% error = 0
% no. of charge steps = 5
% no. of discharge steps = 5
% load_forecast average taken over 1 day

load_new = zeros(1, length(time));
P_ev = zeros(1,n);
available = ones(1,n);
SOC_Mat = [SOC'];
Pev_Mat = [P_ev'];
EV_Power = [0];
EV_Power_charge = [0];
EV_Power_discharge = [0];
error = 0.0;
step_nos_charge = 5;
step_nos_discharge = 5;
avg = 1;
m = avg*24;

% making a matrix of the parameters
%% || 1Charger_Index || 2SOC || 3T_connection || 4T_connecteDur || 5T_disconnection || 6E || 7P_ev || 8P_max || 9available ||

% It is an nX9 matrix

Vehicle_Mat = [Charger_Index', SOC', T_connection', T_connectedDur', T_disconnection', E', P_ev', P_max', available'];

%------------------------------------------------------------------------------


for t = 1:length(time)
    if t <= length(time) - m
        % Calculate the mean of the next 5 elements from index t
        load_forecast_mean = mean(load_forecast(t:t+(m-1)));
    else
        % Calculate the mean of the last 5 elements, handling edge cases
        load_forecast_mean = mean(load_forecast(end-(m-1):end));
    end
    


    disp(t)
    Vehicle_Mat(:, 7) = P_ev';      %resetting the P_ev column

    % disconnecting the vehicles which have already been fully charged and
    % updating their SOCs/ car models/ time of disconnection
    % after one hour to simulate charge lost in
    % travelling
    for i = 1:n
        if t - 1  >= Vehicle_Mat(i, 5) && Vehicle_Mat(i, 2) == 80
            new_car = randi([1, n]);
            Vehicle_Mat(i, 8) = Car_models(new_car, 1);
            Vehicle_Mat(i, 6) = Car_models(new_car, 2);
            Vehicle_Mat(i, 2) = randi([40, 60]);
            Vehicle_Mat(i, 3) = t - 1;
            Vehicle_Mat(i, 4) = randi([6, 10]);
            Vehicle_Mat(i, 5) = Vehicle_Mat(i, 3) + Vehicle_Mat(i, 4); 
            Vehicle_Mat(i, 9) = 1;

        else
            continue
        
        end
    end

    disp('New users updated')

    % Finding and marking those EVs whose SOC has reached a critical level
    % and have to operate at maximum charging power to achieve full charge
    % by the time of disconnection. They charge no matter the time of day
    % until the time of disconnection is reached
    for i = 1: n
        if Vehicle_Mat(i, 9) == 0
            Vehicle_Mat(i, 7) = Vehicle_Mat(i, 8);

        elseif Vehicle_Mat(i, 9) == 1 && ((80 - Vehicle_Mat(i, 2))*(Vehicle_Mat(i, 6)/100)/(Vehicle_Mat(i, 5) - t)) >= Vehicle_Mat(i, 8)
            Vehicle_Mat(i, 7) = Vehicle_Mat(i, 8);
            Vehicle_Mat(i, 9) = 0;

        else
            continue
        end
    end


    % adding this load to the forecast load
    load_new(t) = load_forecast(t) + sum(Vehicle_Mat(:, 7));
    load_no_v2g(t) = load_new(t);
    disp('new load after critical addition updated')

    % providing anciliary services
   
    % condition 1, load after critical is greater than average
    if load_new(t) > (1 + error)*load_forecast_mean

        Vehicle_Mat = sortrows(Vehicle_Mat, 2, "descend");

        for i = 1: n
            if Vehicle_Mat(i, 9) == 0
                continue

            elseif Vehicle_Mat(i, 2) < 22
                Vehicle_Mat(i, 7) = 0;

            else
                k = 0;
                while load_new(t) >= (1 + error)*load_forecast_mean && abs(Vehicle_Mat(i, 7)) <= Vehicle_Mat(i, 8)
                    Vehicle_Mat(i, 7) = -k*(Vehicle_Mat(i, 8)/step_nos_discharge);
                    load_new(t) = load_new(t) + Vehicle_Mat(i, 7);
                    k = k + 1;
                end
                Vehicle_Mat(i, 7) =  Vehicle_Mat(i, 7);
            end
        end
    end
    
    % condition 2, load after critical is in the error range
    if load_new(t) >= (1 - error)*load_forecast_mean && load_new(t) <= (1 + error)*load_forecast_mean
        for i = 1: n
            if Vehicle_Mat(i, 9) == 0
                continue

            else
                Vehicle_Mat(i, 7) = 0;
            end
        end
    end

    % condition 3 , load after critical chargers is less than average
    if load_new(t) < (1 - error)*load_forecast_mean

        Vehicle_Mat = sortrows(Vehicle_Mat, 2, "ascend");
       
        for i = 1: n
            if Vehicle_Mat(i, 9) == 0
                continue

            elseif Vehicle_Mat(i, 2) == 80
                Vehicle_Mat(i, 7) = 0;
            
            else
                k = 0;
                while load_new(t) <= (1 - error)*load_forecast_mean && Vehicle_Mat(i, 7) <= Vehicle_Mat(i, 8)
                    Vehicle_Mat(i, 7) = k*(Vehicle_Mat(i, 8)/step_nos_charge);
                    load_new(t) = load_new(t) + Vehicle_Mat(i, 7);
                    k = k + 1;
                end
                Vehicle_Mat(i, 7) = Vehicle_Mat(i, 7);
            end
        end
    end

    
    % updating the SOCs
    for i = 1: n
        Vehicle_Mat(i, 2) = Vehicle_Mat(i, 2) + 100*(Vehicle_Mat(i, 7)/Vehicle_Mat(i, 6));

        if Vehicle_Mat(i, 2) > 80
            Vehicle_Mat(i, 2) = 80;
        
        elseif Vehicle_Mat(i, 2) < 20
            Vehicle_Mat(i, 2) = 20;

        else
            Vehicle_Mat(i, 2) = Vehicle_Mat(i, 2);

        end
    end

    disp('SOCs updated')

    % storing values for plotting
    SOC_Mat = [SOC_Mat, Vehicle_Mat(:, 2)];
    Pev_Mat = [Pev_Mat, Vehicle_Mat(:, 7)];
    EV_Power = [EV_Power, sum(Vehicle_Mat(:, 7))];
    EV_Power_charge = [EV_Power_charge, sum(Vehicle_Mat(Vehicle_Mat(:, 7) > 0, 7))];
    EV_Power_discharge = [EV_Power_discharge, sum(Vehicle_Mat(Vehicle_Mat(:, 7) <= 0, 7))];

end

%% Main plot showing 
% 1. Forecast Load
% 2. Balanced Load
% 3. Net EV Power injected/ taken from grid
% 4. EV charging power
% 5. EV discharging power

time = datetime(time, 'InputFormat', 'dd-MMM hha');
initial_time = datetime(year(time(1)), month(time(1)), day(time(1)), 0, 0, 0);

% Define x-axis ticks for grid lines (every hour)
x_ticks = time(1):hours(1):time(end);

% Define x-axis ticks for labels (every 3 hours)
x_labels = time(1):hours(12):time(end);

figure
hold on
yyaxis right

plot([initial_time; time], EV_Power*1000/1000000, 'ko','DisplayName', 'Net EV Power');
plot([initial_time; time], EV_Power_charge*1000/1000000,'g--', 'DisplayName', 'EV Charging Power', 'LineWidth', 1.5);
plot([initial_time; time], EV_Power_discharge*1000/1000000,'m--', 'DisplayName', 'EV Discharging Power', 'LineWidth', 1.5);

yyaxis left

plot(time, load_new*1000/1000000, 'r-.', 'DisplayName', 'Balanced Load', 'LineWidth', 1.5);
plot(time, load_forecast*1000/1000000, 'b-','DisplayName', 'Load Forecast', 'LineWidth', 2);

legend('show'); 
xlabel('Time of day (hours)');
ylabel('Load (MW)');
yyaxis left
ylabel('Load (MW)'); % Label for left y-axis
yyaxis right
ylabel('EV Power (MW)'); % Label for right y-axis
title('Delhi Winter (January 2023)')

grid on

xticks(initial_time:hours(1):time(end));
ax = gca;
ax.XTickLabel = cellstr(datestr(x_ticks, 'dd-mmm HH:MM')); 
ax.XTickLabel(~ismember(x_ticks, x_labels)) = {''}; 
grid on
ax.XGrid = 'on';
ax.YGrid = 'on';

%% Plot for one charger Power and SOC of EV connected to it


test_charger_index = randi([1, n]);


figure
tiledlayout(2, 1)

nexttile
plot([initial_time; time], Pev_Mat(test_charger_index, :))
title('Delhi Winter 2023: EV Power and SOC for Charger No.', num2str(test_charger_index), 'LineWidth', 1)
xlabel('Time of the day (hours)');
ylabel('EV Power (kW)');
xticks(initial_time:hours(1):time(end));
ax = gca;
ax.XTickLabel = cellstr(datestr(x_ticks, 'dd-mmm HH:MM')); 
ax.XTickLabel(~ismember(x_ticks, x_labels)) = {''}; 
grid on
ax.XGrid = 'on';
ax.YGrid = 'on';

nexttile
plot([initial_time; time], SOC_Mat(test_charger_index, :), 'LineWidth', 1)
xlabel('Time of the day (hours)')
ylabel('EV SOC (%)')
xticks(initial_time:hours(1):time(end));
ax = gca;
ax.XTickLabel = cellstr(datestr(x_ticks, 'dd-mmm HH:MM'));
ax.XTickLabel(~ismember(x_ticks, x_labels)) = {''}; 
grid on
ax.XGrid = 'on';
ax.YGrid = 'on';