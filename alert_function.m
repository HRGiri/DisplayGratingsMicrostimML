function alert_function(hook,MLConfig,TrialRecord)
% Note:
% Edited version of the ML main alert_function
% Keep this The alert_function.m in the task directory
% This function has priority over the one in the main ML directory.
% To make sure this works, in the task window, Alert should be ON

persistent id id2
filenameCorrect = 'Audio\Correct.wav';  % change the filename appropriately
fileNameIncorrect = 'Audio\NotCorrect.wav';

switch hook
    case 'trial_end'
        % destroys all the sound objects
        mgldestroysound(id);
        mgldestroysound(id2);
        if TrialRecord.TrialErrors(1,TrialRecord.CurrentTrialNumber)==0
            id = mgladdsound(filenameCorrect);
            mglsetproperty(id, 'looping',false, 'collective',false);
            mglplaysound(id);
        else
            id2 = mgladdsound(fileNameIncorrect);
            mglsetproperty(id2, 'looping',false, 'collective',false);
            mglplaysound(id2);
        end
end
end
