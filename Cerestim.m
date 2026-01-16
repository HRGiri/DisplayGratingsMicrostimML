classdef Cerestim < mladapter  % Cerestim Adapter Class
     
%
%specifying a range of delays (ISIs)
%


properties
    % User variables (both readable and writable)
    Stimulator = []     % Stimmex cerestim96 stimulator object
    Channel = []
    %Channel2 = 8
    delay = []
    Amplitude = []      % Array of amplitudes (uA) for the current trial
    Frequency = []      % Array of frequency (Hz) for the current trial
    Pulses = 1       %dummy variable, always stays 1  % Array of no. of Pulses for the current trial
    Pulse_number=7;
    Duration = []       % Array of duration (ms) for the current trial
    verbose = 0         % Verbosity during running of trial (1: display during the start of the trial)
end


    properties (SetAccess = protected)
        % Output variables (only readable)
        
    end
    properties (Access = protected)
        % Internal variables
        currStimNum = 1       % Current stim number in trial
        doStim = []         % Logical array of whether to stimulate for the current trial, based on hardware limits
    end

    methods        
        % The first line of the constructor and four other methods (init, fini, analyze, draw) must be a call for the base class method.        
        function obj = Cerestim(varargin)    % Cerestim(mladapter, stimulator, channel, amplitude, frequency, Pulses, duration)
            obj@mladapter(varargin{1});      % Call to base class. It is necessary to complete the adapter chain.
            % Assign values to user variables
            obj.Stimulator = varargin{2};
            obj.Channel = varargin{3};
            %obj.Channel2 = varargin{4};
            obj.delay = varargin{4};
            obj.Amplitude = varargin{5};
            obj.Frequency = varargin{6};
            obj.Pulses = varargin{7};
            obj.Pulse_number = varargin{8};
            obj.Duration = varargin{9};
            obj.setPatterns();
            
        end
        function delete(obj)
            % Things to do when this adapter is destroyed by MATLAB
            obj.disableStimulator();
        end
        
        function init(obj,p)
            init@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.                                   
        end

        function fini(obj,p)
            fini@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.
        end

        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.

            % Set the sequence for uStim in the first frame of the scene
            if p.scene_frame() == 0
                if ~isempty(obj.Stimulator)
                    if obj.doStim(obj.currStimNum)
                        % Create a program sequence using the waveform defined above
                        obj.Stimulator.beginSequence; % Begin program definition

                        %                         obj.Stimulator.autoStim(obj.Channel(1), obj.currStimNum); % autoStim(Channel 1, Waveform ID)
                        %                         obj.Stimulator.wait(obj.delay(obj.currStimNum));
                        %                         obj.Stimulator.autoStim(obj.Channel(2), obj.currStimNum); % autoStim(Channel 2, Waveform ID)
                        %

                        % Parameters
                        ISI = obj.delay(obj.currStimNum);          %delay between A and B
                        freq= obj.Frequency(obj.currStimNum);
                        interPairInterval = (1000/freq)-ISI; % delay between Pulse pairs

                        % Main loop
                        if(ISI ~= -1 || ISI ~=-2)
                        for i = 1:obj.Pulse_number
                            obj.Stimulator.autoStim(obj.Channel(1), obj.currStimNum); % autoStim(Channel 1, Waveform ID)

                            obj.Stimulator.wait(ISI);  % wait delay m

                            %  pause(ISI);                    % wait delay ms
                            obj.Stimulator.autoStim(obj.Channel(2), obj.currStimNum); % autoStim(Channel 2, Waveform ID)
                            obj.Stimulator.wait(interPairInterval);      % wait before next Pulse pair
                        end
                        end

                        if(ISI == -1)
                            obj.Stimulator.wait(1);  % wait delay m

                        end

                        if(ISI == -2)
                            obj.Stimulator.autoStim(obj.Channel(2), obj.currStimNum); % autoStim(Channel 2, Waveform ID)


                        end





                        obj.Stimulator.endSequence; % End program definition
                    end
                end
            end

            obj.Success = obj.Adapter.Success;  % Assign the child adapter's success state, if there's no analysis.

        end
        function draw(obj,p)
            draw@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.
            
            % Stimulate on the first frame of the scene
            if p.scene_frame() == 0 
                if ~isempty(obj.Stimulator)
                    if obj.doStim(obj.currStimNum)                    
                        obj.Stimulator.play(1);                        % Play our program; number of repeats
                    end
                end
                obj.currStimNum = obj.currStimNum + 1;
            end            
        end

        function setPatterns(obj)   
            % This function sets the waveform patterns for all stimuli of
            % the current trial. Call this function after setting the
            % required user variables.
            totalStim = length(obj.Amplitude);
            if ~isempty(obj.Stimulator)
                obj.printToCommand('clc');
                for i=1:totalStim
                    amp = obj.Amplitude(i);
                    Pulses = obj.Pulses(i);
                    Pulse_number=obj.Pulse_number;
                    frequency = obj.Frequency(i);
                    duration = obj.Duration(i);                    
                    obj.printToCommand("Microstimulation(I=" + amp...
                            + ", n=" + Pulses + ...
                            ", f=" + frequency + ")");
                    
                    % Do not set stim patterns for the following values
                    if amp == 0 || Pulses == 0  || frequency < 16
                        obj.doStim = cat(1,obj.doStim,false);
                        continue
                    else
                        obj.doStim = cat(1,obj.doStim,true);
                    end
                    
                    % When duration > 0, Pulses is determined by frequency
                    if duration > 0
                        Pulses = 1 + (duration * frequency) / 1000;
                    end
                                        
                    % Program our waveforms (stim patterns)
                    obj.Stimulator.setStimPattern('waveform',i,...% We can define multiple waveforms and distinguish them by ID
                        'polarity',0,...% 0=CF, 1=AF
                        'Pulses',Pulses,...% Number of Pulses in stim pattern
                        'amp1',amp,...% Amplitude of first phase in uA
                        'amp2',amp,...% Amplitude of second phase in uA
                        'width1',170,...% Width for first phase in us
                        'width2',170,...% Width for second phase in us
                        'interphase',60,...% Time between phases in us
                        'frequency',frequency);% Frequency determines time between biphasic Pulses                        
                end                
            else
                obj.printToCommand("Cannot do microstimulation as no device connected");
            end
        end
        
        function disableStimulator(obj)
            obj.Stimulator = [];
        end

        function printToCommand(obj, message)            
            if obj.verbose
                if strcmp(message, 'clc')
                    clc; %#ok<UNRCH>
                else
                    disp(message)
                end
            end
        end

    end
end
