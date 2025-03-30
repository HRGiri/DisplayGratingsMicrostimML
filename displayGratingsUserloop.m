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
if isempty(stimTable)
    % Prerequisite variables (HARDCODED):
    params.RF = ["IN"]; % Receptive Field (RF) conditions, IN/OUT
    params.azi = -1.75; % Azimuths (deg), V1_dona = -1.75, V4_dona = -1.35
    params.ele = -2.5; % Elevations (deg), V1_dona = -2.5, V4_dona = -0.6
    params.radii = 1.5; % Aperture radii (deg)
    params.sf = 0.5*(2.^(3)); % Spatial Frequencies (SFs) (cpd)
    params.ori = [0 90]; % Orientations (deg)
    params.con = 25*(2.^(2)); % Contrasts (%)

    % Creating the stimulus table:
    stimTable = create_stimtable(params=params);
    stimLength = size(stimTable, 1);
    TrialRecord.User.StimTable = stimTable;
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
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;