function scenario = produceScenario( scDef )

speakerFieldnames = {'s1','s2','s3','s4'};
spChAssignment = [1,2,3,4];

mix = zeros( 44100 * scDef.length, 4 );

spUsed = [];
scenario = struct();
scenario.onOffs = zeros( 0, 2 );
scenario.etypes = {};
scenario.eSpeakers = [];
for ii = 1 : numel( speakerFieldnames )
    spFn = speakerFieldnames{ii};
    if ~isfield( scDef, spFn )
        continue; 
    else
        spUsed(end+1) = ii;
    end
    spIdx = spChAssignment(ii);
    spFlists = scDef.(spFn).flist;
    jjidx = 1;
    for jj = 1 : size( spFlists, 1 )
        mljjkk = 0;
        for kk = 1 : numel( spFlists{jj} )
            [fpMeta, fpWav] = getFlistSequence( spFlists{jj}{kk}, scDef.(spFn).inbetweenFilesGap{jj}(kk) );
            seqWavjjkk{kk} = audioread( fpWav );
            meta = load( fpMeta );
            onsDel = zeros( ceil( 44100 * scDef.(spFn).onsetDelay{jj}(kk) ), 1 );
            meta.onOffs = meta.onOffs + scDef.(spFn).onsetDelay{jj}(kk);
            seqWavjjkk{kk} = [onsDel; seqWavjjkk{kk}];
            seqWavjjkk{kk} = DataProcs.SceneEarSignalProc.adjustSNR( 44100, seqWavjjkk{1}, 'energy', seqWavjjkk{kk}, 0 );
            seqWavjjkk{kk} = seqWavjjkk{kk}(:,1);
            ljjkk = size( seqWavjjkk{kk}, 1 );
            if jjidx+ljjkk-1 <= size( mix, 1 )
                mix(jjidx:jjidx+ljjkk-1,spIdx) = mix(jjidx:jjidx+ljjkk-1,spIdx) + seqWavjjkk{kk};
                mljjkk = max( ljjkk, mljjkk );
            else
                mix(jjidx:end,spIdx) = mix(jjidx:end,spIdx) + seqWavjjkk{kk}(1:size( mix, 1 ) - jjidx + 1);
                mljjkk = max( size( mix, 1 ) - jjidx + 1, mljjkk );
            end
            meta.onOffs = meta.onOffs + (jjidx / 44100);
            scenario.onOffs = [scenario.onOffs; meta.onOffs];
            scenario.etypes = [scenario.etypes, meta.etypes];
            scenario.eSpeakers = [scenario.eSpeakers, repmat( ii, size( meta.etypes ) )];
        end
        jjidx = jjidx + mljjkk;
    end
    if numel( spUsed ) > 1
        tmp = DataProcs.SceneEarSignalProc.adjustSNR( 44100, mix(:,spUsed(1)), 'energy', mix(:,ii), 0 );
        mix(:,ii) = tmp(:,1);
    end
end
sigSorted = sort( abs( mix(:) ) );
sigSorted(sigSorted<=0.1*mean(sigSorted)) = [];
nUpperSigSorted = round( numel( sigSorted ) * 0.0001 );
sigUpperAbs = median( sigSorted(end-nUpperSigSorted:end) ); % ~0.99995 percentile
mix = mix * 1/sigUpperAbs;

scenario.mix = mix;
[scenario.onOffs,sidx] = sortrows( scenario.onOffs );
scenario.etypes = scenario.etypes(sidx);
scenario.eSpeakers = scenario.eSpeakers(sidx);

audiowrite( 'mix.wav', mix, 44100 );

end
