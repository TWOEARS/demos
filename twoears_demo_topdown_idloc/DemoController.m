classdef DemoController < handle
    %DemoController   Controller class for visualising a blackboard
    %
    %   Ning Ma, University of Sheffield
    %   n.ma@sheffield.ac.uk, 9 Dec 2014
    %
    
    properties
        % Define blackboard system
        bbs;
        segKS;    % FactorialSourceModelKS
        locDecKS; % LocalisastionDecisionKS
        targetSource = [];
        backgroundSource = [];
        
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
        bSolveConfusion = true; % flag for rotating head/body during localisation to solve confusion
        bFrontLocationOnly = false; % flag for localiation in the frontal plane only   
        bIdentifySources = false; % flag for performing source identification
        
        demoMode = 'sim'; % 'sim', 'recording' or 'jido'
        
        % Energy threshold (average ratemap) for valid frames in
        % localisation
        energyThresholdJido = 1E-9;
        energyThresholdSimulation = 1E-11;
    end
    
    methods
        function obj = DemoController(gui)

            % Get genomix path
            obj.pathToGenomix = getGenomixPath();
            
            % Setup visualisers
            handles = guidata(gui);
            obj.bbVis = VisualiserBlackboard(handles.axesConsole);
            obj.afeVis = VisualiserAFE(handles.uipanelAFE);
            %obj.locVis = VisualiserLocalisation(handles.axesRoom);
            obj.locVis = VisualiserIdentityLocalisation(handles.axesRoom);
            
            obj.setDemoMode('sim');
        end
        
        % Setup Robot
        function success = setupRobot(obj)
            success = true;
            obj.bStopNow = false;
            
            switch obj.demoMode
                case 'sim'
                    
                case 'recording'
                    obj.robot = RobotRecording;
                    
                case 'jido'
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
        % 'sim', 'recording' or 'jido'
        function setDemoMode(obj, mode)
            obj.reset();
            
            obj.demoMode = mode;
            obj.setupRobot();
        end
        
        % Run the blackboard
        function startBlackboard(obj)
            
            segidModelsDir = 'learned_models/IdentityKS/mc3_fc5_0.5s_segmented_nsGroundtruth_models_dataset_1';
            segidModelsDir = cleanPathFromRelativeRefs( db.getFile( segidModelsDir ) );
            segModelsDirContents = dir( [segidModelsDir filesep '*.model.mat'] );
            segidModels = arrayfun( @(x)(struct('name', {x.name(1:end-10)})), segModelsDirContents );
            donotusemodels = arrayfun( @(x)( any( strcmpi( x.name, {'femaleScreammaleScream','piano','knock','crash','engine','dog','footsteps'} ) ) ), segidModels );
            segidModels(donotusemodels) = [];
            [segidModels(1:numel(segidModels)).dir] = deal( segidModelsDir );

            switch obj.demoMode
                case 'sim'
                
                    [sourceSets, sourceVolumnes] = setupScenes;
                    
                    for ii = 1:length(sourceSets)

                        % Reset controller
                        obj.reset();
                        
                        sourceList = sourceSets{ii};
                        [obj.robot, refAzimuths, robotOrientation] = setupBinauralSimulator(sourceList, sourceVolumnes{ii});
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
                        
                        sig = obj.robot.getSignal(10);
                        fsHz = 44100;

                        % Create blackboard
                        [obj.bbs, obj.locDecKS, obj.segKS] = buildBlackboardSystem(obj.robot, ...
                            obj.bFrontLocationOnly, ...
                            obj.bSolveConfusion, ...
                            obj.bIdentifySources, ...
                            segidModels, ...
                            'ADREAM-SIM');

                        obj.segKS.setTargetSource(obj.targetSource);
                        obj.segKS.setBackgroundSource(obj.backgroundSource);

                        % Set energy threshold for detecting valid frames
                        obj.bbs.setEnergyThreshold(obj.energyThresholdSimulation);

                        % Set visualisers
                        obj.bbs.setVisualiser(obj.bbVis);
                        obj.bbs.setLocVis(obj.locVis);
                        obj.bbs.setAfeVis(obj.afeVis);

                        pause;
                        soundsc(sig,fsHz);
                        
                        % Run the blackboard system
                        obj.bbs.run();

                        obj.robot.shutdown();

                        if obj.bStopNow
                            return;
                        end

                    end
                    % End of the simulation
                    
                case {'recording', 'jido'}
                    % Reset controller
                    obj.reset();

                    % Start the real rebot
                    obj.robot.start();

                    % Create blackboard
                    [obj.bbs, obj.locDecKS, obj.segKS] = buildBlackboardSystem(...
                        obj.robot, ...
                        obj.bFrontLocationOnly, ...
                        obj.bSolveConfusion, ...
                        obj.bIdentifySources, ...
                        segidModels);

                    obj.segKS.setTargetSource(obj.targetSource);
                    obj.segKS.setBackgroundSource(obj.backgroundSource);

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
        
        function setTargetSource(obj, source)
            obj.targetSource = source;
            if ~isempty(obj.segKS)
                obj.segKS.setTargetSource(source);
            end
        end
        
        function setBackgroundSource(obj, source)
            obj.backgroundSource = source;
            if ~isempty(obj.segKS)
                obj.segKS.setBackgroundSource(source);
            end
        end
        
        function setSolveConfusion(obj, bSolveConfusion)
            obj.bSolveConfusion = bSolveConfusion;
            if ~isempty(obj.locDecKS)
                obj.locDecKS.setSolveConfusion(bSolveConfusion);
            end
        end
        
        function setIdentifySources(obj, bIdentifySources)
            obj.bIdentifySources = bIdentifySources;
        end
    end
end

