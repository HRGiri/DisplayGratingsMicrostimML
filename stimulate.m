function stimulate(stimulator, channel, waveform, pulses, amp, frequency, duration)
    % STIMULATE Play the microstimulator given the channel number, 
    % waveform ID, no. of pulses, amplitude, and frequency
    
    %   First the stimulation pattern is set, then a program sequence is
    %   created, and then stimulation is done once. If either the current
    %   amplitude or the number of pulses is 0, or frequency is below the 
    %   least Cerestim can go, no stimulation is done

    if amp == 0 || pulses == 0  || frequency < 16
        return
    end
    
    % When duration > 0, pulses is determined by frequency
    if duration > 0
        pulses = 1 + (duration * frequency) / 1000;
    end
    
    disp("Microstimulation(I=" + amp + ", n=" + pulses + ", f=" + frequency + ")");
    
    if ~isempty(stimulator)        
        % Program our waveform (stim pattern)
        stimulator.setStimPattern('waveform',1,...% We can define multiple waveforms and distinguish them by ID
            'polarity',0,...% 0=CF, 1=AF
            'pulses',pulses,...% Number of pulses in stim pattern
            'amp1',amp,...% Amplitude of first phase in uA
            'amp2',amp,...% Amplitude of second phase in uA
            'width1',170,...% Width for first phase in us
            'width2',170,...% Width for second phase in us
            'interphase',60,...% Time between phases in us
            'frequency',frequency);% Frequency determines time between biphasic pulses
        
        % Create a program sequence using the waveform defined above
        stimulator.beginSequence; % Begin program definition
            stimulator.autoStim(channel, waveform); % autoStim(Channel, Waveform ID)                
        stimulator.endSequence; % End program definition
        
        stimulator.play(1);                        % Play our program; number of repeats

        disp("Done!");
    else
        disp("Cannot do microstimulation as no device connected");
    end
end

