classdef DemoController < handle
    %DemoController   Controller class for visualising a blackboard
    %
    %   Ning Ma, University of Sheffield
    %   n.ma@sheffield.ac.uk, 9 Dec 2014
    %
    
    properties
        % Define blackboard system
        bbs;
        robot; 
        locDecKS;
        bbVis;  % visualiser for blackboard
        afeVis; % visualiser for AFE
        locVis; % visualiser for Localisation
        
        % Define simulator variables
        refSourceAzimuths; % Reference source azimuths
        bStopNow = false;
        
        % Define localisation demo parameters
        bSolveConfusion = true; % flag for rotating head/body during localisation to solve confusion
        bFrontLocationOnly = false; % flag for localiation in the frontal plane only        
        bSimulation = true; % If true, use simulation instead of robot
        nsrcsGroundtruth = true;
        bUseAdream = false;
        
        % Energy threshold (average ratemap) for valid frames in
        % localisation
        energyThresholdSimulation = 1E-11;
        
        runningMode = 'segregated identification';    % 'frequencyMasked loc',
                                                      % 'segregated identification',
                                                      % or 'both'
    end
    
    methods
        function obj = DemoController(gui)
            startTwoEars( fullfile( pwd, 'Config.xml' ) );
            
            % Setup visualisers
            handles = guidata(gui);
            obj.bbVis = VisualiserBlackboard(handles.axesConsole);
            obj.afeVis = VisualiserAFE(handles.uipanelAFE);
            obj.locVis = VisualiserIdentityLocalisation(handles.axesRoom);
            
            obj.reset();
        end
                
        % Run the blackboard
        function startBlackboard(obj)
            % initializations for identification models
            idModels = [];
            segidModels = [];
            if any( strcmp( obj.runningMode, {'segregated identification', 'both'} ) )
                segidModelsDir = fullfile( pwd, 'models', 'segId' );
                segModelsDirContents = dir( [segidModelsDir filesep '*.model.mat'] );
                segidModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), segModelsDirContents );
%                 donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'piano','phone','crash','engine','dog','footsteps'} ) ) ), segidModels );
%                 segidModels(donotusemodels) = [];
                [segidModels(1:numel(segidModels)).dir] = deal( segidModelsDir );
            end
            if any( strcmp( obj.runningMode, {'frequencyMasked loc', 'both'} ) )
                idModelsDir = fullfile( pwd, 'models', 'fs' );
                modelsDirContents = dir( [idModelsDir filesep '*.model.mat'] );
                idModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), modelsDirContents );
%                 donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'piano','phone','crash','engine','dog','footsteps'} ) ) ), idModels );
%                 idModels(donotusemodels) = [];
                [idModels(1:numel(idModels)).dir] = deal( idModelsDir );
            end
            
            [sourceSets, sourceVolumes] = setupScenes();
            
            for ii = 1:length(sourceSets)
                
                % Reset controller
                obj.reset();
                
                sourceList = sourceSets{ii};
                [obj.robot, refAzimuths, robotOrientation,labels,onOffsets,activity] = ...
                    setupBinauralSimulator(sourceList, sourceVolumes{ii}, obj.bUseAdream);
                
                fprintf('Robot position %d: %.0f degrees (world)\n', ii, robotOrientation);
                
                obj.robot.rotateHead(0, 'absolute');
                obj.robot.moveRobot(0, 0, robotOrientation, 'absolute');
                obj.robot.Init = true;
                obj.robot.start();
                
                % Create blackboard
                [obj.bbs, obj.locDecKS] = buildBBS(obj.robot, ...
                    obj.bFrontLocationOnly, ...
                    obj.bSolveConfusion, ...
                    obj.nsrcsGroundtruth, ...
                    idModels, segidModels, ...
                    16000, obj.runningMode, ...
                    labels,onOffsets,activity,refAzimuths);
                % Set energy threshold for detecting valid frames
                obj.bbs.setEnergyThreshold(obj.energyThresholdSimulation);
                
                % Set visualisers
                obj.bbs.setVisualiser(obj.bbVis);
                obj.bbs.setLocVis(obj.locVis);
                obj.bbs.setAfeVis(obj.afeVis);
                
%                 disp( 'Press key to continue.' );
%                 pause;
                
                % Run the blackboard system
                obj.bbs.run();
                
                obj.robot.shutdown();
            end
            % End of the simulation
        end
        
        function stop(obj)
            obj.bStopNow = true;
            if ~isempty(obj.robot)
                obj.robot.stop();
            end
            obj.reset();
            obj.bStopNow = false;
        end

        function reset(obj)
            obj.bbVis.reset;
            obj.locVis.reset;
            obj.afeVis.reset;
        end
        
        function setSolveConfusion(obj, bSolveConfusion)
            obj.bSolveConfusion = bSolveConfusion;
            if ~isempty(obj.locDecKS)
                obj.locDecKS.setSolveConfusion(bSolveConfusion);
            end
        end
        
    end
end

