function [sim,refAzimuths,robotOrientation] = setupBinauralSimulator(sourceList, sourceVolumes)
%
%
% sourceList = {'alarm', 'fire', 'male', 'female'}
%

% Number of sources
nSources = length(sourceList);
if nargin < 2
    sourceVolumes = ones(nSources,1);
end

brirs = {...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
};
brirIndex = 2;
sourcePosIndices = [4 3 2 1];
                    
% Get metadata from BRIR
brir = SOFAload(db.getFile(brirs{brirIndex}), 'nodata');

% Get 0 degree look head orientation from BRIR
nsteps = size(brir.ListenerView, 1);
robotPos = SOFAconvertCoordinates(brir.ListenerView(ceil(nsteps/2),:),'cartesian','spherical');
robotOrientation = robotPos(1); % World frame


% Initialise binaural simulator
sim = simulator.SimulatorConvexRoom();

% Basis parameters - Block size, sample rate and the renderer type
fsHz = 44100;
set(sim, ...
	'BlockSize',            4096, ...
    'SampleRate',           fsHz, ...
    'LengthOfSimulation',   60, ...
    'Renderer',             @ssr_brs ...
    );

% Set the acoustic scene - nSources and a binaural sensor
switch nSources
    case 1
        set(sim, ...
            'Sources', {simulator.source.Point()}, ...
            'Sinks', simulator.AudioSink(2) ...
        );
    case 2
        set(sim, ...
            'Sources', {simulator.source.Point(),...
                simulator.source.Point()}, ...
            'Sinks', simulator.AudioSink(2) ...
        );
    case 3
        set(sim, ...
            'Sources', {simulator.source.Point(),...
                simulator.source.Point(), ...
                simulator.source.Point()}, ...
            'Sinks', simulator.AudioSink(2) ...
        );
    case 4
        set(sim, ...
            'Sources', {simulator.source.Point(),...
                simulator.source.Point(), ...
                simulator.source.Point(), ...
                simulator.source.Point()}, ...
            'Sinks', simulator.AudioSink(2) ...
        );
    otherwise
        error('Support up to 4 sources');
end

% Binaural sensor
set(sim.Sinks, 'Name', 'Head');

for n = 1:nSources
    set(sim.Sources{n}, ...
        'AudioBuffer', simulator.buffer.Ring(1), ...
        'Name', sourceList{n}, ...
        'Volume', sourceVolumes(n));
    sim.Sources{n}.AudioBuffer.loadFile(...
        sprintf('../audio/%s.wav', sourceList{n}), ...
        sim.SampleRate);
end

% Set source positions
refAzimuths = zeros(nSources, 1);
for jj = 1:nSources
    srcPos = sourcePosIndices(jj);
    sim.Sources{jj}.IRDataset = simulator.DirectionalIR(brirs{brirIndex}, srcPos);

    % Get source direction from BRIR
    y = brir.EmitterPosition(srcPos, 2) - brir.ListenerPosition(2);
    x = brir.EmitterPosition(srcPos, 1) - brir.ListenerPosition(1);
    refAzimuths(jj) = atan2d(y, x) - robotOrientation; % Reference azimuth
end