classdef RobotRecording < simulator.RobotInterface
    %RobotRecording Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = private)
        SampleRate              % Sample rate of the audio stream server 
                                % in Hz.
        binaural = [];
        
        BlockSize;
        
        timeStamp;
    end
    
    properties (Access = public)
        client                  % Handle to the genomix client.
        kemar                   % KEMAR control interface.
        jido                    % Jido interface.
        bass                    % Interface to the audio stream server.
    end
    
    properties (Access = private)
        headOrientation
        sampleIndex
    end
    
    methods (Access = public)
        function obj = RobotRecording()
            
            [obj.binaural, obj.SampleRate] = audioread('../audio/jido_rec_mixed.wav');
            obj.sampleIndex = 0;
            obj.BlockSize = 0.5 * obj.SampleRate;
            
            % Set robot active
            obj.bActive = true;
            
            obj.timeStamp = tic;
        end

        
        %% Grab binaural audio of a specified length
        function [earSignals, durSec, durSamples] = ...
                getSignal(obj, durSec)

            % Make sure durSec has passed since last time this method is
            % called
            while toc(obj.timeStamp) < durSec
                pause(durSec - toc(obj.timeStamp))
            end
            
            % Get binaural signals
            blockSizeSamples = round(durSec * obj.SampleRate);
            if obj.sampleIndex+blockSizeSamples > size(obj.binaural,1)
                obj.sampleIndex = 0;
            end
            earSignals = obj.binaural(obj.sampleIndex+1:obj.sampleIndex+blockSizeSamples,:);
            
            obj.sampleIndex = obj.sampleIndex + blockSizeSamples;
            
            % Get signal length
            durSamples = size(earSignals, 1);
            durSec = durSamples / obj.SampleRate;
            
            sound(earSignals, obj.SampleRate);
            obj.timeStamp = tic;
        end
  
        
        %% Rotate the head with mode = {'absolute', 'relative'}
        function rotateHead(obj, angleDeg, mode)
        
        end
        
        
        %% Get the head orientation relative to the base orientation
        function azimuth = getCurrentHeadOrientation(obj)
            azimuth = 0;
        end
        
        
        %% Get the maximum head orientation relative to the base orientation
        function [maxLeft, maxRight] = getHeadTurnLimits(obj)
            maxLeft = 90;
            maxRight = -90;
        end
        
        
        %% Move the robot to a new position
        function moveRobot(obj, posX, posY, theta, mode)
        end
        

        %% Get the current robot position
    	function [posX, posY, theta] = getCurrentRobotPosition(obj)

            posX = 0;
            posY = 0;
            theta = 0;
        end
        
        
        
        
        %% Returns true if robot is active
        function b = isActive(obj)
            b = obj.bActive;
        end
        


    end
end

