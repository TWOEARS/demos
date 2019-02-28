function modelData = readoutBB( bbs )

modelData.finishTime = bbs.blackboard.currentSoundTimeIdx;

% NIGENS classes
classes = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
           {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
           {'maleSpeech'},{'femaleScream','maleScream'}};
classes = cellfun( @(c)(strcat( c{:} )), classes, 'UniformOutput', false );

% FS id
idhyps = bbs.blackboard.getData( 'integratedIdentityHypotheses' );
modelData.fs_d = zeros( numel( idhyps ), 13 );
for ii = 1:13
    idhyps_ii = arrayfun( @(x)(x.data(arrayfun( @(a)(strcmp(a.label,classes{ii})), x.data))), idhyps );
    modelData.fs_d(:,ii) = arrayfun( @(a)(a.d), idhyps_ii );
end
modelData.fs_onOffs = zeros( numel( idhyps ), 2 );
modelData.fs_onOffs(:,2) = cat( 1, idhyps(:).sndTmIdx );
modelData.fs_onOffs(:,1) = modelData.fs_onOffs(:,2) - arrayfun( @(a)(a.data(1).concernsBlocksize_s), idhyps )';

% SI id
idhyps = bbs.blackboard.getData( 'singleBlockObjectHypotheses' );
modelData.si_dects.onOffs(:,2) = cat( 1, idhyps(:).sndTmIdx );
modelData.si_dects.onOffs(:,1) = modelData.si_dects.onOffs(:,2) - 0.5;
idhyps = arrayfun( @(x)(x.data(arrayfun( @(a)(a.d > 0), x.data))), idhyps, 'UniformOutput', false );
for jj = 1 : numel( idhyps )
    headOrientation = bbs.blackboard.getData( 'headOrientation', modelData.si_dects.onOffs(jj,2) );
    for ii = 1:13
        idhyps_jj_ii = idhyps{jj}(arrayfun( @(a)(strcmp(a.label,classes{ii})), idhyps{jj} ));
        modelData.si_dects.locs{jj,ii} = unique( wrapTo180( [idhyps_jj_ii.loc] + headOrientation.data ) );
    end
end

% nsrcs
nshyps = bbs.blackboard.getData( 'NumberOfSourcesHypotheses' );
modelData.ns_onOffs = zeros( numel( nshyps ), 2 );
modelData.ns_onOffs(:,2) = cat( 1, nshyps(:).sndTmIdx );
modelData.ns_onOffs(:,1) = modelData.ns_onOffs(:,2) - arrayfun( @(a)(a.data.concernsBlocksize_s), nshyps )';
modelData.ns = arrayfun( @(a)(a.data.n), nshyps )';

% bottom-up loc
lochyps = bbs.blackboard.getData( 'locationHypothesis' );
modelData.locbu_onOffs = zeros( numel( lochyps ), 2 );
modelData.locbu_onOffs(:,2) = cat( 1, lochyps(:).sndTmIdx );
modelData.locbu_onOffs(:,1) = modelData.locbu_onOffs(:,2) - 0.5;
for jj = 1 : numel( lochyps )
    [modelData.locbu_azms(jj,:),azmsidxs] = sort( ...
        wrapTo360( round( lochyps(jj).data.azimuths + lochyps(jj).data.headOrientation ) ) );
    modelData.locbu_pd(jj,:) = lochyps(jj).data.sourcesDistribution(azmsidxs);
end
if any( std( modelData.locbu_azms, [], 1 ) > 0 )
    error( 'Code is wrong, this should not happen' );
end

% top-down loc

end
