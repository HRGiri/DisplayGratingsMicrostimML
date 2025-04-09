function [C,timingfile,userdefined_trialholder] = displayGratingsUserloop(MLConfig,TrialRecord)
% Adapted from Pai's grating completion protocol
% default return value
C = [];
timingfile = 'displayGratingsTiming.m';
userdefined_trialholder = '';

% define variables to keep track of the stimuli shown/remaining
persistent stimList                 % List of stimuli left to display in a block
persistent stimPrev                 % List of stimuli of the current block displayed in the prev trial
persistent stimBorrow               % List of stimuli of the next block displayed in the prev trial

% Createa table of all stimulus combinations and return timing file if it the very first call
persistent stimTable
persistent stimLength
persistent blockSum
persistent microStimCondition
if isempty(stimTable)
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
        
        %%
        % Program our waveform (stim pattern)
        stimulator.setStimPattern('waveform',1,...% We can define multiple waveforms and distinguish them by ID
            'polarity',0,...% 0=CF, 1=AF
            'pulses',10,...% Number of pulses in stim pattern
            'amp1',1,...% Amplitude in uA
            'amp2',1,...% Amplitude in uA
            'width1',100,...% Width for first phase in us
            'width2',100,...% Width for second phase in us
            'interphase',100,...% Time between phases in us
            'frequency',20);% Frequency determines time between biphasic pulses
        
        %%
        % Create a program sequence using any previously defined waveforms (we only have one)
        stimulator.beginSequence; % Begin program definition
            stimulator.autoStim(1, 1); % autoStim(Channel, Waveform ID)            
        stimulator.endSequence; % End program definition
        %%
        TrialRecord.User.Stimulator = stimulator;
    else
        TrialRecord.User.Stimulator = [];
        disp("No Stimulator Devices conected");
    end
    % Prerequisite variables (HARDCODED):
    params.RF = ["IN"]; % Receptive Field (RF) conditions, IN/OUT
    params.azi = 0; % Azimuths (deg), V1_dona = -1.75, V4_dona = -1.35
    params.ele = 0; % Elevations (deg), V1_dona = -2.5, V4_dona = -0.6
    params.radii = 2.^(6); % Aperture radii (deg)
    params.sf = 0.5*(2.^(0:1)); % Spatial Frequencies (SFs) (cpd)
    params.ori = (0:45:135); % Orientations (deg)
    params.con = 25*(2.^(1)); % Contrasts (%)

    % Creating the stimulus table:
    stimTable = create_stimtable(params=params);
    stimLength = size(stimTable, 1);
    TrialRecord.User.StimTable = stimTable;

    % Condition when microstim is required (HARDCODED)
    cond.sf = 1;
    cond.ori = 90;
    cond.con = 50;

    TrialRecord.User.MicroStimCondition = cond;

    % Determine the condition index
    microStimCondition = 0;
    condition_names = ["sf"  "ori" "con"];      % Only these for now, will update other params when required
    for i=1:stimLength
        match_condition = true;
        for j=1:size(condition_names,2)
            if stimTable{i,condition_names(j)} ~= cond.(condition_names(j))
                match_condition = false;
                break;
            end            
        end
        
        if match_condition
            microStimCondition = i;
            break;
        end
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

% Logical array for microstim
TrialRecord.User.MicroStim = stimCurrent == microStimCondition;

% Set the block number and the condition number of the next trial
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;
