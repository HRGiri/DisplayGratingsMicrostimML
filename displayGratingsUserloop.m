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
if isempty(stimTable)
    % Prerequisite variables (HARDCODED):
    azi = 0; % Azimuths (deg), V1_dona = -1.75, V4_dona = -1.35
    ele = 0; % Elevations (deg), V1_dona = -2.5, V4_dona = -0.6
    radii = 2.^(6); % Aperture radii (deg)
    sf = 0.5*(2.^(0)); % Spatial Frequencies (SFs) (cpd)
    ori = [0, 45, 90]; % Orientations (deg)
    con = 25*(2.^(2)); % Contrasts (%)
    RF = ["IN"]; % Receptive Field (RF) conditions, IN/OUT

    % Creating the stimulus table:
    stimTable = table('Size', [length(RF)*length(azi)*length(ele)*length(sf)*length(ori)*length(con)*length(radii), 7], 'VariableNames', ...
        ["RF", "azi", "ele", "radii", "sf", "ori","con"], 'VariableTypes', ["string", "double", "double", "double", "double", "double", "double"]); % MATLAB is too retarded to build DataFrames like Pandas:
    row = 1;
    for i = 1:length(RF)
        for j = 1:length(azi)
            for k = 1:length(ele)
                for m = 1:length(radii)
                    for n = 1:length(sf)
                        for o = 1:length(ori)
                            for p = 1:length(con)
                                stimTable{row, :} = [RF(i), azi(j), ele(k), radii(m), sf(n), ori(o), con(p)];
                                row = row + 1;
                            end
                        end
                    end
                end
            end
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
    condition = mod(condition+stim_per_trial-1, size(stimTable, 1))+1;      % increment the condition # by stim_per_trial
end

% Initialize the conditions for a new block
if isempty(stimList)                                            % If there are no stimuli left in the block
    stimList = setdiff(1:size(stimTable, 1), stimBorrow);       %
    stimBorrow = [];
    block=block+1;
end

if length(stimList)>=stim_per_trial                                         % If more than 2 stimuli left in the current block
    stimCurrent = datasample(stimList, stim_per_trial, 'Replace',false);    % randomly sample 3 stimuli from the list
    stimPrev = stimCurrent;
else
    stimPrev = stimList;
    stimBorrow = datasample(imageNum, stim_per_trial-length(stimList), 'Replace', false);
    stimCurrent = [stimList stimBorrow];
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