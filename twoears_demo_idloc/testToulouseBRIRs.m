function testToulouseBRIRs


locVis = VisualiserIdentityLocalisation;
sigLen = 10;


sourceSets{1} = {'alarm'};
sourceSets{2} = {'fire'};
sourceSets{3} = {'alarm', 'fire'};
                    % sourceSets{4} = {'female', 'fire'};
                    
for ii = 3:length(sourceSets)

    sourceList = sourceSets{ii};
    [robot, refAzimuths, robotOrientation] = setupBinauralSimulator(sourceList);
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
    pause(sigLen);

    robot.shutdown();
    locVis.reset;
        
end


