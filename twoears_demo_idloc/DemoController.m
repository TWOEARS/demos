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
        bbVis;  % visualiser for blackboard
        afeVis; % visualiser for AFE
        locVis; % visualiser for Localisation
        
        % Define simulator variables
        brirs;
        refSourceAzimuths; % Reference source azimuths
        bStopNow = false;
        
        % Define Robot parameters
        pathToGenomix = '';
        
        
        % Define localisation demo parameters
        bSolveConfusion = false; % flag for rotating head/body during localisation to solve confusion
        bFullBodyRotation = false; % If true, use full body rotation as well as head rotation
        bFrontLocationOnly = false; % flag for localiation in the frontal plane only        
        bSimulation = true; % If true, use simulation instead of robot
        
        % Energy threshold (average ratemap) for valid frames in
        % localisation
        energyThresholdJido = 1E-9;
        energyThresholdSimulation = 1E-11;
        
        runningMode = 'locOnly';    % 'locOnly'     - localisation only
                                    % 'segStream'   - segregated streams
                                    % 'fullStream'  - full streams
                                    % 'jointCNN'    - joint CNN
                                    % 'fullAndSegStream'
    end
    
    methods
        function obj = DemoController(gui)
            
            startAMLTTP;
            % Get genomix path
            obj.pathToGenomix = getGenomixPath();
            
            % Setup visualisers
            handles = guidata(gui);
            obj.bbVis = VisualiserBlackboard(handles.axesConsole);
            obj.afeVis = VisualiserAFE(handles.uipanelAFE);
            obj.locVis = VisualiserIdentityLocalisation(handles.axesRoom);
            
            obj.setDemoMode(true);
        end
        
        % Setup Robot
        function success = setupRobot(obj)
            success = true;
            obj.bStopNow = false;
            obj.bSolveConfusion = false;
            obj.bFrontLocationOnly = false;
            
            if obj.bSimulation
                obj.bFullBodyRotation = false;
                obj.brirs = { ...
                    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
                    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
                    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
                    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
                    };
            else
                obj.bFullBodyRotation = true;
                if exist(obj.pathToGenomix, 'dir') == 0
                    errordlg('Genomix path not found');
                    success = false;
                else
                    % Create the robot connection
                    obj.robot = JidoInterface(obj.pathToGenomix); % need to change this
                end
            end
        end
        
        % Change demo mode
        function setDemoMode(obj, bSimulation)
            obj.reset();
            
            obj.bSimulation = bSimulation;
            obj.setupRobot();
        end
        
        % Run the blackboard
        function startBlackboard(obj)
            
            % initializations for identification models
            if strcmp(obj.runningMode, 'segStream')
                startSegmentationTraining; % requires adding stream-segregation-training-pipeline to path
                segidModelsDir = 'learned_models/IdentityKS/mc3_fc5_0.5s_segmented_nsGroundtruth_models_dataset_1';
                segidModelsDir = cleanPathFromRelativeRefs( db.getFile( segidModelsDir ) );
                segModelsDirContents = dir( [segidModelsDir filesep '*.model.mat'] );
                segidModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), segModelsDirContents );
                donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'crash','engine','dog','footsteps'} ) ) ), segidModels );
                segidModels(donotusemodels) = [];
                [segidModels(1:numel(segidModels)).dir] = deal( segidModelsDir );
                idModels = [];
            elseif strcmp(obj.runningMode, 'fullStream')
                idModelsDir = 'learned_models/IdentityKS/mc3_fc5_0.5s_models_dataset_1';
                idModelsDir = cleanPathFromRelativeRefs( db.getFile( idModelsDir ) );
                modelsDirContents = dir( [idModelsDir filesep '*.model.mat'] );
                idModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), modelsDirContents );
                donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'crash','engine','dog','footsteps'} ) ) ), idModels );
                idModels(donotusemodels) = [];
                [idModels(1:numel(idModels)).dir] = deal( idModelsDir );
                segidModels = [];
            elseif strcmp(obj.runningMode, 'fullAndSegStream')
                startSegmentationTraining; % requires adding stream-segregation-training-pipeline to path
                segidModelsDir = 'learned_models/IdentityKS/mc3_fc5_0.5s_segmented_nsGroundtruth_models_dataset_1';
                segidModelsDir = cleanPathFromRelativeRefs( db.getFile( segidModelsDir ) );
                segModelsDirContents = dir( [segidModelsDir filesep '*.model.mat'] );
                segidModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), segModelsDirContents );
                donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'crash','engine','dog','footsteps','knock','piano','alarm'} ) ) ), segidModels );
                segidModels(donotusemodels) = [];
                [segidModels(1:numel(segidModels)).dir] = deal( segidModelsDir );
                idModelsDir = 'learned_models/IdentityKS/mc3_fc5_0.5s_models_dataset_1';
                idModelsDir = cleanPathFromRelativeRefs( db.getFile( idModelsDir ) );
                modelsDirContents = dir( [idModelsDir filesep '*.model.mat'] );
                idModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), modelsDirContents );
                donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'crash','engine','dog','footsteps','knock','piano','alarm'} ) ) ), idModels );
                idModels(donotusemodels) = [];
                [idModels(1:numel(idModels)).dir] = deal( idModelsDir );
            else
                idModels = [];
                segidModels = [];
            end
            idFs = 16000;
            ppRemoveDc = false;
            
            if strcmp(obj.runningMode, 'jointCNN')
                addPathsIfNotIncluded( getCaffePath );
            end
            
            if obj.bSimulation

                [sourceSets, sourceVolumes] = setupScenes;

                for ii = 1:length(sourceSets)

                    % Reset controller
                    obj.reset();

                    sourceList = sourceSets{ii};
                    [obj.robot, refAzimuths, robotOrientation] = setupBinauralSimulator(sourceList, sourceVolumes(ii));
                    nSources = length(refAzimuths);
                    % Plot ground true source positions
                    for jj = 1:nSources
                        obj.locVis.plotMarkerAtAngle(jj, refAzimuths(jj), sourceList{jj});
                    end

                    fprintf('Robot position %d: %.0f degrees (world)\n', ii, robotOrientation);

                    obj.robot.rotateHead(0, 'absolute');
                    obj.robot.moveRobot(0, 0, robotOrientation, 'absolute');
                    obj.robot.Init = true;
                    obj.robot.start();

                    % Create blackboard
                    obj.bbs = buildBBS(obj.robot, ...
                        obj.bFrontLocationOnly, ...
                        obj.bSolveConfusion, ...
                        obj.bFullBodyRotation,...
                        idModels, segidModels, ...
                        ppRemoveDc, idFs, obj.runningMode);
                    % Set energy threshold for detecting valid frames
                    obj.bbs.setEnergyThreshold(obj.energyThresholdSimulation);

                    % Set visualisers
                    obj.bbs.setVisualiser(obj.bbVis);
                    obj.bbs.setLocVis(obj.locVis);
                    obj.bbs.setAfeVis(obj.afeVis);

                    % Run the blackboard system
                    obj.bbs.run();

                    obj.robot.shutdown();

                    if obj.bStopNow
                        return;
                    end
                end
                % End of the simulation
            else
                % Reset controller
                obj.reset();
                
                % Start the real rebot
                obj.robot.start();
                
                % Initialisation
                obj.robot.rotateHead(0, 'absolute');
                
                % Create blackboard
                obj.bbs = buildBBS(obj.robot, ...
                    obj.bFrontLocationOnly, ...
                    obj.bSolveConfusion, ...
                    obj.bFullBodyRotation, ...
                    idModels, segidModels, ...
                    ppRemoveDc, idFs, obj.runningMode);
                
                % Set energy threshold for detecting valid frames
                obj.bbs.setEnergyThreshold(obj.energyThresholdJido);
                
                % Set visualisers
                obj.bbs.setVisualiser(obj.bbVis);
                obj.bbs.setLocVis(obj.locVis);
                obj.bbs.setAfeVis(obj.afeVis);
                
                % Run the blackboard system
                obj.bbs.run();
            end
        end
        
        function stop(obj)
            obj.bStopNow = true;
            if ~isempty(obj.robot)
                obj.robot.stop();
            end
        end

        function reset(obj)
            obj.bbVis.reset;
            obj.locVis.reset;
            obj.afeVis.reset;
        end
    end
end

