function testToulouseBRIRs


brirs = { ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
    };

locVis = VisualiserLocalisation;
sigLen = 5;

for ii = 1:length(brirs)

    % Get metadata from BRIR
    brir = SOFAload(db.getFile(brirs{ii}), 'nodata');

    % Get 0 degree look head orientation from BRIR
    nsteps = size(brir.ListenerView, 1);
    robotPos = SOFAconvertCoordinates(brir.ListenerView(ceil(nsteps/2),:),'cartesian','spherical');
    robotOrientation = robotPos(1); % World frame

    fprintf('==== Robot position %d: %.0f degrees (world)\n', ii, robotOrientation);

    for jj = 1:size(brir.EmitterPosition,1) % loop over all loudspeakers

        robot = setupBinauralSimulator();

        % Get source direction from BRIR
        y = brir.EmitterPosition(jj, 2) - brir.ListenerPosition(2);
        x = brir.EmitterPosition(jj, 1) - brir.ListenerPosition(1);
        refAzi = wrapTo180(atan2d(y, x) - robotOrientation); % Reference azimuth

        fprintf('     Source position %d: %.0f degrees (torso)\n', jj, refAzi);
        locVis.plotMarkerAtAngle(refAzi);

        % Load new BRIRs and initialise binaural simulator
        robot.Sources{1}.IRDataset = simulator.DirectionalIR(brirs{ii}, jj);
        robot.rotateHead(0, 'absolute');
        robot.moveRobot(0, 0, robotOrientation, 'absolute');
        robot.Init = true;

        sig = robot.getSignal(sigLen);
        soundsc(sig, 44100);
        pause(sigLen);

        robot.shutdown();
        locVis.reset;
        
    end
end


