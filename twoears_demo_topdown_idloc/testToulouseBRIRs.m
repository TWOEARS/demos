function [sig, fsHz] = testToulouseBRIRs(sourceList, sourceVolumes)

fsHz = 44100;
sigLen = 10;

[robot, refAzimuths, robotOrientation] = setupBinauralSimulator(sourceList,sourceVolumes);
%nSources = length(refAzimuths);

% Plot ground true source positions
%for jj = 1:nSources
%    fprintf('     Source %d: %s position %.0f degrees (torso)\n', jj, sourceList{jj}, refAzimuths(jj));
%    locVis.plotMarkerAtAngle(jj, refAzimuths(jj), sourceList{jj});
%end

% fprintf('==== Robot position %d: %.0f degrees (world)\n', ii, robotOrientation);

robot.rotateHead(0, 'absolute');
robot.moveRobot(0, 0, robotOrientation, 'absolute');
robot.Init = true;
sig = double(robot.getSignal(sigLen));
%soundsc(sig, 44100);
%pause;

robot.shutdown();
% locVis.reset;


