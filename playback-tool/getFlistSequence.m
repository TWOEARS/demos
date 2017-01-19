function [fpath_metadata, fpath_wav_concat] = getFlistSequence( flist, gap_sec )

dst_dir = fullfile(cleanPathFromRelativeRefs( db.tmp ), 'scenarioSequences');
if ~exist( dst_dir, 'dir' )
    mkdir( dst_dir );
end
[~,fname_set] = fileparts( flist );
fpath_base = fullfile( dst_dir, [fname_set num2str( gap_sec )] );
fpath_wav_concat = [fpath_base '.wav'];
fpath_metadata = [fpath_base '.mat'];

%if exist( fpath_wav_concat, 'file' ), return; end

%%
fid = fopen( flist );
wav_list = {};
nextLine = fgetl(fid);       %# Read the first line from the file
while ischar( nextLine )         %# Loop while not at the end of the file
    if numel( nextLine ) > 0
        wav_list{end+1} = nextLine;  % Add the line to the cell array
    end
    nextLine = fgetl(fid);            % Read the next line from the file
end
fclose(fid);
clear fid;

%%
wav_concat = [];
onOffs = zeros( 0, 2 );
etypes = {};
for ii = randperm( numel(wav_list) );
    fprintf( '.' );
    wavFilepath = db.getFile( wav_list{ii} );
    eventType = IdEvalFrame.readEventClass( wavFilepath );
    [onOffsTmp,etypesTmp] = IdEvalFrame.readOnOffAnnotations( wavFilepath );
    noEType = cellfun( @isempty, etypesTmp );
    etypesTmp(noEType) = repmat( {eventType}, size( noEType ) );
    [y, Fs] = audioread( wavFilepath );
    if Fs ~= 44100
        y = resample( y, 44100, Fs );
    end
    if size( y, 2 ) > 1
        [~, maxIdx] = max( rms( y ) );
        y = y(:, maxIdx); % stereo to mono
    end
    yrms = max( rms( y ) );
    y = y ./ yrms;
    if isempty( wav_concat )
        wav_concat = zeros( size(y, 1), 1 );
        wav_concat(:, 1) = y;
        onOffs = onOffsTmp;
        etypes = etypesTmp;
    else
        y_adjusted = DataProcs.SceneEarSignalProc.adjustSNR(44100, wav_concat, 'energy', y, 0);
        wlenSoFar = size( wav_concat, 1 ) / 44100;
        wav_concat = vertcat( wav_concat, y_adjusted(:, 1) );
        onOffsTmp = onOffsTmp + wlenSoFar;
        onOffs = [onOffs; onOffsTmp];
        etypes = [etypes, etypesTmp];
    end
    wav_concat = vertcat( wav_concat, ...
        zeros( ceil(44100*gap_sec), size(wav_concat, 2) ) );
end
fprintf( '.' );

%%
wav_concat = wav_concat ./ max(max(abs(wav_concat)));
audiowrite( fpath_wav_concat, wav_concat, 44100 );
save( fpath_metadata, 'onOffs', 'etypes' );
fprintf( ';' );

end


