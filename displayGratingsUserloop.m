function [C,timingfile,userdefined_trialholder] = displayGratingsUserloop(MLConfig,TrialRecord)
% Adapted from Pai's grating completion protocol
% default return value
C = [];
% timingfile = 'displayGratingsTiming.m';
timingfile = 'displayGratingsTimingAdapter.m';      % Timing file that uses the Cerestim Adapter
userdefined_trialholder = '';

% Number of total blocks, in case the task is to be quit after an exact
% number of blocks
num_blocks = 100;     % Should always be an even number
if mod(num_blocks,2) == 1
    error("num_blocks should be an even number")
end

% define variables to keep track of the stimuli shown/remaining
persistent stimList                 % List of stimuli left to display in a block
persistent stimPrev                 % List of stimuli of the current block displayed in the prev trial
persistent stimBorrow               % List of stimuli of the next block displayed in the prev trial

% Createa table of all stimulus combinations and return timing file if it the very first call
persistent stimTable
persistent stimLength
persistent blockSum

if isempty(stimTable)    

    % Prerequisite variables (HARDCODED):
    % Grating parameters
    params.RF = ["IN"]; % Receptive Field (RF) conditions, IN/OUT
    params.azi = 0; % Azimuths (deg), V1_dona = -1.75, V4_dona = -1.35
    params.ele = 0; % Elevations (deg), V1_dona = -2.5, V4_dona = -0.6
    params.radii = 1000; % Aperture radii (deg)
    params.sf = 0.5*(2.^(0:3)); % Spatial Frequencies (SFs) (cpd)
    params.ori = (0:45:135); % Orientations (deg)
    params.con = [0,25,50,100]; %25*(2.^(1)); % Contrasts (%)
    
    % Microstimulation parameters
    params.amp = [0, 2, 4, 8, 16, 32, 64];   % Current amplitude (uA)
    params.pulses = 7;%[0, 2, 3, 4, 5, 6, 7];  % Number of biphasic pulses
    params.frequency = 40;%[0,20,30,40,50,60,70];  % Frequency of biphasic pulses
    params.duration = 0; % ms; When duration > 0, pulses is determined by frequenc

    % Creating the stimulus table:
    stimTable = create_stimtable(params=params);
    stimLength = size(stimTable, 1);
    TrialRecord.User.StimTable = stimTable;
    
    % Define the channel to be stimulated
    % For Dona
    % Ch 12 -> elec1-27
    % Ch 95 -> elec1-1
    % Ch 24 -> elec1-6
    % Ch 56 -> elec1-42
    % Ch 55 -> elec1-41
    % Ch 57 -> elec1-31
    % For Jojo
    % Ch 35 -> elec2-76
    % Ch 84 -> elec2-70
    % Ch 70 -> elec2-85
    % Ch 79 -> elec2-89
    % Ch 72 -> elec2-84
    % Ch 33 -> elec2-77
    % Ch 41 -> elec2-73
    TrialRecord.User.MicrostimChannel = 41;

    %%
    % Create stimulator object
    stimulator = cerestim96();
    
    %%
    
    % Scan for devices
    DeviceList = stimulator.scanForDevices();    

    if ~isempty(DeviceList)
    
        % Select a device to connect to
        stimulator.selectDevice(0);
        
        % Connect to the stimulator
        stimulator.connect; 
                
        TrialRecord.User.Stimulator = stimulator;
    else
        TrialRecord.User.Stimulator = [];
        disp("No Stimulator Devices conected");
    end
    return
end

stim_per_trial = TrialRecord.Editable.stim_per_trial;
% get current block and current condition
block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

if isempty(TrialRecord.TrialErrors)                                         % If its the first trial
    condition = 1;                                                          % set the condition # to 1
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end) % If the last trial is a success
    stimList = setdiff(stimList, stimPrev);                                 % remove previous trial stimuli from the list of stimuli
    condition = mod(condition+stim_per_trial-1, stimLength)+1;                 % increment the condition # by stim_per_trial
end

% Initialize the conditions for a new block
if isempty(stimList)                                            % If there are no stimuli left in the block
    stimList = setdiff(1:stimLength, stimBorrow);       %
    block=block+blockSum+1;
    stimBorrow = [];
    blockSum = 0;
end

if length(stimList)>=stim_per_trial                                         % If more than 2 stimuli left in the current block
    stimCurrent = datasample(stimList, stim_per_trial, 'Replace',false);    % randomly sample 3 stimuli from the list
    stimPrev = stimCurrent;
elseif length(stimList)+stimLength>stim_per_trial
    stimPrev = stimList;
    stimBorrow = datasample(1:stimLength, stim_per_trial-length(stimList), 'Replace', false);
    stimCurrent = [stimList stimBorrow];
    stimCurrent = stimCurrent(randperm(stim_per_trial));
else
    stimPrev = stimList;
    blockSum = floor((stim_per_trial - length(stimList))/stimLength);
    stimBorrow = datasample(1:stimLength, stim_per_trial-length(stimList)-blockSum*stimLength, 'Replace', false);
    stimCurrent = [stimList repmat(1:stimLength,1,blockSum) stimBorrow];
    stimCurrent = stimCurrent(randperm(stim_per_trial));
end

Info = stimTable(stimCurrent, :);
for j = string(Info.Properties.VariableNames)
    for i = 1:stim_per_trial
        Info_struct.(strcat(j, string(i))) = Info.(j)(i);
    end
end
TrialRecord.setCurrentConditionInfo(Info_struct);

% Set the stimuli
stim = cell(1,stim_per_trial);
for i=1:stim_per_trial
    stim{i} = 'gen(make_grating.m)';
end

C = cell(1,stim_per_trial);
for i=1:stim_per_trial
    C{i} = stim{i};
end

TrialRecord.User.Stimuli = stimCurrent;                     % save the stimuli for the next trial in user variable
TrialRecord.User.stim_idx = 1;

% Set the block number and the condition number of the next trial
if block == num_blocks + 1
    TrialRecord.NextBlock = -1;     % Exit if the next block number reaches the maximum number of blocks
else
    TrialRecord.NextBlock = block;
end
TrialRecord.NextCondition = condition;
