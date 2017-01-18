function testToulouseBRIRs(sceneNums)


locVis = VisualiserIdentityLocalisation;
sigLen = 5;


[sourceSets, sourceVolumes] = setupScenes;
if nargin < 1
    sceneNums = 1:length(sourceSets);
end

for ii = sceneNums

    sourceList = sourceSets{ii};
    [robot, refAzimuths, robotOrientation] = setupBinauralSimulator(sourceList,sourceVolumes{ii});
    nSources = length(refAzimuths);
    % Plot ground true source positions
    for jj = 1:nSources
        fprintf('     Source %d: %s position %.0f degrees (torso)\n', jj, sourceList{jj}, refAzimuths(jj));
        locVis.plotMarkerAtAngle(jj, refAzimuths(jj), sourceList{jj});
    end

    fprintf('==== Robot position %d: %.0f degrees (world)\n', ii, robotOrientation);

    robot.rotateHead(0, 'absolute');
    robot.moveRobot(0, 0, robotOrientation, 'absolute');
    robot.Init = true;
    sig = robot.getSignal(sigLen);
    soundsc(sig, 44100);
    pause;

    robot.shutdown();
    locVis.reset;
        
end


