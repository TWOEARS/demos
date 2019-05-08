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
        startScene = 1;
        
        % Define localisation demo parameters
        bLocDecCmdRotate = false; % flag for rotating head/body during localisation to solve confusion
        bFrontLocationOnly = false; % flag for localiation in the frontal plane only        
        bSimulation = true; % If true, use simulation instead of robot
        nsrcsGroundtruth = true;
        bUseAdream = false;
        bFsInitSI = false;
        bMaxLatDistRotate = true;
        bTestSet = false;
        bRndRotation = false;
        
        % Energy threshold (average ratemap) for valid frames in
        % localisation
        energyThresholdSimulation = 1E-11;
        
        runningMode = 'both';                         % 'frequencyMasked loc',
                                                      % 'segregated identification',
                                                      % or 'both'
    end
    
    methods
        function obj = DemoController(gui)
            startTwoEars( fullfile( pwd, 'Config.xml' ) );
            if nargin >= 1 &&  ~isempty( gui )
                % Setup visualisers
                handles = guidata(gui);
                obj.bbVis = VisualiserBlackboard(handles.axesConsole);
                obj.afeVis = VisualiserAFE(handles.uipanelAFE);
                obj.locVis = VisualiserIdentityLocalisation(handles.axesRoom);
                obj.reset();
            end
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
            if any( strcmp( obj.runningMode, {'frequencyMasked loc', 'both'} ) ) ...
                    || obj.bFsInitSI
                idModelsDir = fullfile( pwd, 'models', 'fs' );
                modelsDirContents = dir( [idModelsDir filesep '*.model.mat'] );
                idModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), modelsDirContents );
%                 donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'piano','phone','crash','engine','dog','footsteps'} ) ) ), idModels );
%                 idModels(donotusemodels) = [];
                [idModels(1:numel(idModels)).dir] = deal( idModelsDir );
            end
            
            [sourceSets, sourceVolumes] = setupScenes( obj.bTestSet );
            
            for ii = obj.startScene:length(sourceSets)
                
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
                    obj.bLocDecCmdRotate, ...
                    obj.nsrcsGroundtruth, ...
                    obj.bFsInitSI, ...
                    obj.bMaxLatDistRotate, ...
                    obj.bRndRotation, ...
                    idModels, segidModels, ...
                    16000, obj.runningMode, ...
                    labels,onOffsets,activity,refAzimuths);
                % Set energy threshold for detecting valid frames
                obj.bbs.setEnergyThreshold(obj.energyThresholdSimulation);
                
                % Set visualisers
                if ~isempty( obj.bbVis )
                    obj.reset();
                    obj.bbs.setVisualiser(obj.bbVis);
                    obj.bbs.setLocVis(obj.locVis);
                    obj.bbs.setAfeVis(obj.afeVis);
                end
                
                % Run the blackboard system
                obj.bbs.run();
                
                obj.robot.shutdown();
                
                modelData = readoutBB( obj.bbs ); %#ok<NASGU>
                saveName_str = '';
                if obj.bUseAdream
                    saveName_str = [saveName_str '.adream'];
                end
                if obj.bTestSet
                    saveName_str = [saveName_str '_test'];
                end
                if obj.bLocDecCmdRotate
                    saveName_str = [saveName_str '_headMovingLocRule'];
                elseif obj.bMaxLatDistRotate
                    saveName_str = [saveName_str '_headMovingMLD'];
                elseif obj.bRndRotation
                    saveName_str = [saveName_str '_headMovingRND'];
                else
                    saveName_str = [saveName_str '_headFixed'];
                end
                if obj.nsrcsGroundtruth
                    saveName_str = [saveName_str '_nsGt'];
                else
                    saveName_str = [saveName_str '_nsModel'];
                end
                save( ['results_' num2str( ii ) saveName_str], ...
                                    'modelData', 'labels', 'onOffsets', 'activity', 'refAzimuths' );
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
            if ~isempty( obj.bbVis )
                obj.bbVis.reset;
                obj.locVis.reset;
                obj.afeVis.reset;
            end
        end
        
        function setSolveConfusion(obj, bLocDecCmdRotate)
            obj.bLocDecCmdRotate = bLocDecCmdRotate;
            if ~isempty(obj.locDecKS)
                obj.locDecKS.setSolveConfusion(bLocDecCmdRotate);
            end
        end
        
    end
end

