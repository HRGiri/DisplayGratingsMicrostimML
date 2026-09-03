% Grating parameters
params.RF = "IN"; % Receptive Field (RF) conditions, IN/OUT
params.azi = 0; % Azimuths (deg), V1_dona = -1.75, V4_dona = -1.35
params.ele = 0; % Elevations (deg), V1_dona = -2.5, V4_dona = -0.6
params.radii = 1000;  % Aperture radii (deg)
params.sf = 0.5*(2.^(0:3)); % Spatial Frequencies (SFs) (cpd)
params.ori = [0,45,90,135];   % Orientations (deg)
params.con = 25*(2.^(0:2)); % Contrasts (%)

% Microstimulation parameters
params.amp = 0;   % Current amplitude (uA)
params.pulses = -1;  % Number of biphasic pulses (Not used for this experiment
params.frequency = 0; % Frequency of biphasic pulses
params.duration = 0; % ms; When duration > 0, pulses is determined by frequency
params.width = 0;
