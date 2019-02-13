function makeTestSignal( testFlist, testSignalFile, bPermute, bReverse, minLoopDur_s )

[sourceFiles,nFiles] = readFileList(testFlist);
if nargin >= 3 && bPermute
    sourceFiles = sourceFiles(randperm(nFiles));
end
if nargin >= 4 && bReverse
    sourceFiles = flip( sourceFiles );
end
if nargin >= 5
    sourceFiles_new = {};
    for ii = 1 : numel( sourceFiles )
        sf_info = audioinfo( db.getFile( sourceFiles{ii} ) );
        sf_len = sf_info.Duration;
        repTimes = ceil( minLoopDur_s / sf_len );
        sourceFiles_new = [sourceFiles_new repmat( sourceFiles(ii), 1, repTimes )];
        fprintf( '.' );
    end
    sourceFiles = sourceFiles_new';
end
fprintf( '.' );
[sourceSignals, sourceLabels] = readAudioFiles(...
    sourceFiles, ...
    'Samplingrate', 44100, ...
    'Zeropadding', 0.5 * 44100,...
    'Normalize', true, ...
    'CellOutput', true);
fprintf( ':' );
refSig = readAudioFiles( {'sound_databases/generalSoundsNI/femaleSpeech/bbaezp.wav'}, ...
                         'Samplingrate', 44100, ...
                         'Zeropadding', 0,...
                         'Normalize', true );
fprintf( ':' );
for ii = 1:nFiles
    sourceSignals{ii} = DataProcs.SceneEarSignalProc.adjustSNR( ...
                                          44100, refSig, 'energy', sourceSignals{ii}, 0 );
    sourceSignals{ii}(:,2) = [];
    fprintf( '.' );
end
sourceSignal = vertcat(sourceSignals{:});
onOffsets = vertcat(sourceLabels.cumOnsetsOffsets);
labels = vertcat(sourceLabels.class);
labels(cellfun(@isempty,labels)==1) = [];

fprintf( ':' );
activity = DataProcs.SceneEarSignalProc.detectActivity( 44100, sourceSignal, -40, 50e-3, 20e-3, 10e-3 )';
fprintf( '.' );
[energy, tFramesSec] = DataProcs.SceneEarSignalProc.runningEnergy( 44100, sourceSignal, 20e-3, 10e-3 );
energy = energy';
fprintf( '.' );
energy = interp1( tFramesSec, energy, (1:numel(sourceSignal))./44100 )';
fprintf( ':' );

save( testSignalFile, 'sourceSignal', 'onOffsets', 'labels', 'activity', 'energy' );
fprintf( ';\n' );
