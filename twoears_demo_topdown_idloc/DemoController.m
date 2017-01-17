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
        bSolveConfusion = false; % flag for rotating head/body during localisation to solve confusion
        bFrontLocationOnly = false; % flag for localiation in the frontal plane only   
        bIdentifySources = true; % flag for performing source identification
        
        demoMode = 'sim'; % 'sim', 'recording' or 'jido'
        
        % Energy threshold (average ratemap) for valid frames in
        % localisation
        energyThresholdJido = 2e-4; % for magnitude ratemap
        energyThresholdSimulation = 2E-6;
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
                    obj.brirs = { ...
                        'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
                        'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
                        'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
                        'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
                        };
                    
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
                
                    for ii = 1:length(obj.brirs)

                        % Get metadata from BRIR
                        brir = SOFAload(db.getFile(obj.brirs{ii}), 'nodata');

                        % Get 0 degree look head orientation from BRIR
                        nsteps = size(brir.ListenerView, 1);
                        robotPos = SOFAconvertCoordinates(brir.ListenerView(ceil(nsteps/2),:),'cartesian','spherical');
                        robotOrientation = robotPos(1); % World frame

                        fprintf('Robot position %d: %.0f degrees (world)\n', ii, robotOrientation);

                        for jj = 1:size(brir.EmitterPosition,1) % loop over all loudspeakers

                            obj.robot = setupBinauralSimulator();

                            % Get source direction from BRIR
                            y = brir.EmitterPosition(jj, 2) - brir.ListenerPosition(2);
                            x = brir.EmitterPosition(jj, 1) - brir.ListenerPosition(1);
                            refAzi = atan2d(y, x) - robotOrientation; % Reference azimuth

                            % Reset controller
                            obj.reset();

                            % Plot a marker at the reference azimuth
                            obj.locVis.plotMarkerAtAngle(refAzi);

                            % Load new BRIRs and initialise binaural simulator
                            obj.robot.Sources{1}.IRDataset = simulator.DirectionalIR(obj.brirs{ii}, jj);
                            obj.robot.rotateHead(0, 'absolute');
                            obj.robot.moveRobot(0, 0, robotOrientation, 'absolute');
                            obj.robot.Init = true;
                            obj.robot.start();

                            % Create blackboard
                            [obj.bbs, obj.locDecKS, obj.segKS] = buildBlackboardSystem(obj.robot, ...
                                obj.bFrontLocationOnly, ...
                                obj.bSolveConfusion, ...
                                obj.bIdentifySources, ...
                                segidModels);

                            obj.segKS.setTargetSource(obj.targetSource);
                            obj.segKS.setBackgroundSource(obj.backgroundSource);

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

