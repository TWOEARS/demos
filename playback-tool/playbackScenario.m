function playbackScenario( scenario, Fs, deviceId, channelAssignment )
% scenario.mix: 4-channel stream
% scenario.onOffs: n x 2 array, on- and offsets of events, sorted by onsets
% scenario.etypes: corresponding event types
% scenario.eSpeakers: corresponding speaker emmiting
if ~exist('Fs', 'var') || isempty( Fs )
    Fs = 44100;
end
if ~exist('deviceId', 'var') || isempty( deviceId )
    deviceId = 5;
end
if ~exist('channelAssignment', 'var') || isempty( channelAssignment )
    channelAssignment = [1 2 3 4];
end
playrec('init', Fs, deviceId, -1)

vis = VisualiserLayout();
set(gcf,'CurrentCharacter','@');
playrec('play', scenario.mix, channelAssignment)
tic;

elapsed_sec = 0;
scenario_dur = max(scenario.onOffs(:,2));
while elapsed_sec <= scenario_dur
    vis.updateSpeakerText(elapsed_sec, ...
        scenario.onOffs, ...
        scenario.etypes, ...
        scenario.eSpeakers);
    elapsed_sec = toc;
    
    keyIn = get(gcf,'CurrentCharacter');
 
    if keyIn ~= '@'
        if keyIn == 'q'
            set(gcf,'CurrentCharacter', '@');
            elapsed_sec = inf;
        end
    end
    pause(0.4);
end
vis.reset();
playrec('reset');
close all
