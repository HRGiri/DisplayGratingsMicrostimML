% DisplayImagesTiming file
hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');  % Stop the task immediately if "x" key is pressed
set_bgcolor([0.5 0.5 0.5]);                                                 % Sets subject screen background color to Gray
bhv_variable('Stimuli', TrialRecord.User.Stimuli);                          % Save the current trial stimuli in data.UserVars variable

% Initializing task variables
if exist('eye_','var'), tracker = eye_;     % detect an available tracker
else, error('This task requires eye input. Please set it up or turn on the simulation mode.');
end

% Mapping to the TaskObjects defined in the userloop
stim_per_trial = 3;
stim = 1:stim_per_trial;

% time intervals (in ms):
wait_for_fix = 1000;
hold_fix = 1000;
stimulus_duration = 800;
isi_duration = 700;
pulse_duration = 50;

% fixation point parameters:
fix_size = 0.2;             % circle diameter (in degrees)
fix_color = [1 1 1];        % [R G B] values between 0 and 1
fix_window = [3 3];         % rectangle with side angles (in degrees)
hold_window = fix_window ;  

% Add variables on the Control screen to make on-the-fly changes
editable('pulse_duration','fix_window','fix_size');
editable('-color', 'fix_color');
editable('stim_per_trial','wait_for_fix','hold_fix','stimulus_duration','isi_duration');

% creating useful adapters
% Graphic adapter for fixation point
fixation_point = CircleGraphic(null_);
fixation_point.EdgeColor = fix_color;
fixation_point.FaceColor = fix_color;
fixation_point.Size = fix_size;
fixation_point.Position = [0 0];
fixation_point.Zorder = 1;

% Adapter to play audio at the start of the trial
sndTrialStart = AudioSound(null_);
sndTrialStart.List = 'Audio\trialStart.wav';    % path to the audio file
sndTrialStart.PlayPosition = 0;                 % play from 0 sec

% Adapter to play audio when the fixation is acquired
sndAquireStart = AudioSound(null_);
sndAquireStart.List = 'Audio\acquireStart.wav'; % path to the audio file
sndAquireStart.PlayPosition = 0;                % play from 0 sec

% creating Scenes
% sceneFix: wait for fixation
fix1 = SingleTarget(tracker);   % we use eye signals (eye_) for tracking
fix1.Target = fixation_point;   % set fixation point as the target
fix1.Threshold = fix_window;    % Examines if the gaze is in the Threshold window around the Target.
wth1 = WaitThenHold(fix1);      % 
wth1.WaitTime = wait_for_fix;   % 
wth1.HoldTime = 1;              % Supposed to be 0, but if kept 0 ML thinks the subject didn't hold fixation and WTH adapter's success condition doesn't become true
wth1.AllowEarlyFix = true;     % End the scene if the monkey is fixating before the scene starts
con1 = Concurrent(wth1);        %
con1.add(sndTrialStart);        % Start the trial and concurrently play the trialStart audio

sceneFix = create_scene(con1);   % In this scene, we will present the fixation_point and wait for fixation.

% sceneHold: hold fixation
fix2 = SingleTarget(tracker);   % We use eye signals (eye_) for tracking
fix2.Target = fixation_point;   % Set fixation point as the target
fix2.Threshold = fix_window;    % Examines if the gaze is in the Threshold window around the Target.
wth2 = WaitThenHold(fix2);      %
wth2.WaitTime = 0;              % We already know the fixation is acquired, so we don't wait.
wth2.HoldTime = hold_fix;
con2 = Concurrent(wth2);
con2.add(sndAquireStart);

sceneHold = create_scene(con2);  % In this scene, we will present the fixation_point and hold fixation for 1000ms.

% sceneStim: present stimulus
fix3 = SingleTarget(tracker);
fix3.Target = fixation_point;
fix3.Threshold = hold_window;
wth3 = WaitThenHold(fix3);
wth3.WaitTime = 0;               % We already know the fixation is acquired, so we don't wait.
wth3.HoldTime = stimulus_duration;

sceneStim = cell(1,stim_per_trial);
for i=1:stim_per_trial
    sceneStim{i} = create_scene(wth3, stim(i)); % present stimulus i
end

% sceneISI: hold fixation until next stimulus
fix4 = SingleTarget(tracker);
fix4.Target = fixation_point;
fix4.Threshold = hold_window;
wth4 = WaitThenHold(fix4);
wth4.WaitTime = 0;
wth4.HoldTime = isi_duration;
sceneISI = create_scene(wth4);

% TASK:
error_type = 0;

while true
    run_scene(sceneFix);                            % Run the first scene (eventmaker 10)
    if ~wth1.Success; error_type = 4; break; end    % If the WithThenHold failed (fixation is not acquired), fixation was never made and therefore this is a "no fixation (4)" error.
    
    run_scene(sceneHold,10);
    if ~wth2.Success; error_type = 3; break; end    % If the WithThenHold failed (fixation is broken), this is a "break fixation (3)" error.

    for i=1:stim_per_trial-1
        run_scene(sceneStim{i},20);                     % Run the scene for presenting i'th stimulus (eventmarker 20)
        if ~wth3.Success; error_type = 3; break; end    % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
        
        if isi_duration ~= 0
            run_scene(sceneISI,10);
            if ~wth4.Success; error_type = 3; break; end
        else
            eventmarker(10);
        end
    end

    run_scene(sceneStim{stim_per_trial},20);                       % Run the scene for presenting last stimulus (eventmarker 20)
    if ~wth3.Success; error_type = 3; break; end    % The failure of WithThenHold indicates that the subject didn't maintain fixation on the stimulus.
    
    idle(0);                                        % Clear screens
    goodmonkey(pulse_duration, 'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',50);   % Successful trial, give reward
    break
end

if 0~=error_type; idle(700); end
trialerror(error_type);     % Add the result to the trial history
set_iti(1000);
