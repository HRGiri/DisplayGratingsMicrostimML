classdef Cerestim < mladapter  % Cerestim Adapter Class
     
    properties
        % User variables (both readable and writable)
        Stimulator = []     % Stimmex cerestim96 stimulator object
        Channel = 1         % Channel to stimulate on
        Amplitude = []      % Array of amplitudes (uA) for the current trial
        Frequency = []      % Array of frequency (Hz) for the current trial
        Pulses = []         % Array of no. of pulses for the current trial
        Duration = []       % Array of duration (ms) for the current trial
        Offset = 0          % Time offset from visual stim (ms)
        verbose = 0         % Verbosity during running of trial (1: display during the start of the trial)
    end
    properties (SetAccess = protected)
        % Output variables (only readable)
        
    end
    properties (Access = protected)
        % Internal variables
        currStimNum = 1       % Current stim number in trial
        doStim = []         % Logical array of whether to stimulate for the current trial, based on hardware limits
        isSetPattern = false
        isStimulate = false
    end

    methods        
        % The first line of the constructor and four other methods (init, fini, analyze, draw) must be a call for the base class method.        
        function obj = Cerestim(varargin)    % Cerestim(mladapter, stimulator, channel, amplitude, frequency, pulses, duration)
            obj@mladapter(varargin{1});      % Call to base class. It is necessary to complete the adapter chain.            
            % Assign values to user variables
            obj.Stimulator = varargin{2};
            obj.Channel = varargin{3};
            obj.Amplitude = varargin{4};
            obj.Frequency = varargin{5};
            obj.Pulses = varargin{6};            
            obj.Duration = varargin{7};
            obj.Offset = varargin{8};

            obj.setPatterns();
            
        end
        function delete(obj) 
            % Things to do when this adapter is destroyed by MATLAB
            obj.disableStimulator();
        end
        
        function init(obj,p)
            init@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.
            obj.isSetPattern = false;
            obj.isStimulate = false;
        end

        function fini(obj,p)
            fini@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.
        end

        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.
            

            % Set the sequence for uStim in the first frame of the scene
            % afer offset
            if p.scene_time() >= obj.Offset                
                if ~obj.isSetPattern
                    if ~isempty(obj.Stimulator)                    
                        if obj.doStim(obj.currStimNum)
                            % Create a program sequence using the waveform defined above
                            obj.Stimulator.beginSequence; % Begin program definition
                                obj.Stimulator.autoStim(obj.Channel, obj.currStimNum); % autoStim(Channel, Waveform ID)                
                            obj.Stimulator.endSequence; % End program definition                        
                        end                        
                    end
                    obj.isSetPattern = true;
                end
            end

            obj.Success = obj.Adapter.Success;  % Assign the child adapter's success state, if there's no analysis.

        end
        function draw(obj,p)
            draw@mladapter(obj,p);  % Call to base class. It is necessary to complete the adapter chain.
            
            % Stimulate on the first frame of the scene after the offset
            if p.scene_time() >= obj.Offset
                if ~obj.isStimulate
                    if ~isempty(obj.Stimulator)
                        if obj.doStim(obj.currStimNum)                    
                            obj.Stimulator.play(1);                        % Play our program; number of repeats
                        end
                    end
                    obj.isStimulate = true;
                    obj.currStimNum = obj.currStimNum + 1;
                end
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
                    pulses = obj.Pulses(i);
                    frequency = obj.Frequency(i);
                    duration = obj.Duration(i);                    
                    obj.printToCommand("Microstimulation(I=" + amp...
                            + ", n=" + pulses + ...
                            ", f=" + frequency + ")");
                    
                    % Do not set stim patterns for the following values
                    if amp == 0 || pulses == 0  || frequency < 16
                        obj.doStim = cat(1,obj.doStim,false);
                        continue
                    else
                        obj.doStim = cat(1,obj.doStim,true);
                    end
                    
                    % When duration > 0, pulses is determined by frequency
                    if duration > 0
                        pulses = 1 + (duration * frequency) / 1000;
                    end
                                        
                    % Program our waveforms (stim patterns)
                    obj.Stimulator.setStimPattern('waveform',i,...% We can define multiple waveforms and distinguish them by ID
                        'polarity',0,...% 0=CF, 1=AF
                        'pulses',pulses,...% Number of pulses in stim pattern
                        'amp1',amp,...% Amplitude of first phase in uA
                        'amp2',amp,...% Amplitude of second phase in uA
                        'width1',170,...% Width for first phase in us
                        'width2',170,...% Width for second phase in us
                        'interphase',60,...% Time between phases in us
                        'frequency',frequency);% Frequency determines time between biphasic pulses                        
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
