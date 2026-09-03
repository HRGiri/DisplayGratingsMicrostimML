% Grating parameters
params.RF = "IN"; % Receptive Field (RF) conditions, IN/OUT
params.azi = 0; % Azimuths (deg), V1_dona = -1.75, V4_dona = -1.35
params.ele = 0; % Elevations (deg), V1_dona = -2.5, V4_dona = -0.6
params.radii = 1000;  % Aperture radii (deg)
params.sf = 0.5*(2.^(0:3)); % Spatial Frequencies (SFs) (cpd)
params.ori = [0,45,90,135];   % Orientations (deg)
params.con = 25*(2.^[0,2]); % Contrasts (%)

% Microstimulation parameters
params.amp = [0, 2, 4, 8, 16, 32, 64];   % Current amplitude (uA)
params.pulses = 7;%[0, 2, 3, 4, 5, 6, 7];  % Number of biphasic pulses
params.frequency = 20;%[0,20,30,40,50,60,70];  % Frequency of biphasic pulses
params.duration = 0; % ms; When duration > 0, pulses is determined by frequency
params.width = 170; %[0, 170, 272, 340, 680, 1360];

% Define the channel to be stimulated
% For Dona
% Ch 12 -> elec1-27
% Ch 95 -> elec1-1
% Ch 24 -> elec1-6
% Ch 56 -> elec1-42
% Ch 55 -> elec1-41
% Ch 57 -> elec1-31
% Ch 52 -> elec1-33
% Ch 58 -> elec1-32
% Ch 59 -> elec1-21
% Ch 60 -> elec1-22
% Ch 25 -> elec1-25
% Ch 62 -> elec1-23
% For Jojo
% Ch 35 -> elec2-76
% Ch 84 -> elec2-70
% Ch 70 -> elec2-85
% Ch 79 -> elec2-89
% Ch 72 -> elec2-84
% Ch 33 -> elec2-77
% Ch 41 -> elec2-73
% Ch 37 -> elec2-75
% Ch 49 -> elec2-61
microstimChannel = 49;
