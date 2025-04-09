function stimulate(stimulator)
% STIMULATE Play the microstimulator
%   Detailed explanation goes here
    if ~isempty(stimulator)              
        stimulator.play(1);                        % Play our program; number of repeats
    else
        disp("MicroStimulation done!")
    end
end

