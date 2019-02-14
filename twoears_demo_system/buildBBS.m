function [bbs,locDecKs]  = buildBBS(sim, bFrontLocationOnly, bSolveConfusion, ...
                                  bNsrcsGroundtruth, ...
                                  idModels, idSegModels, fs, runningMode, ...
                                  labels, onOffsets, activity, azms )

% runningMode:
% 'frequencyMasked loc'
% 'segregated identification'
% 'both'
ppRemoveDc = false;

bbs = BlackboardSystem(1);
bbs.setRobotConnect(sim);
%% localization KSs
bbs.setDataConnect('AuditoryFrontEndKS', fs, 0.5);
if bFrontLocationOnly
    dnnlocKs = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE-FRONT'});
else
    dnnlocKs = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE'});
end
fprintf( '.' );
locDecKs = bbs.createKS( 'LocalisationDecisionKS', {bSolveConfusion,0.5} );
fprintf( '.' );
rot = bbs.createKS('HeadRotationKS', {sim});
fprintf( '.' );
%%
idClassThresholds.fire = 0.5;
segIdClassThresholds.fire = 0.5;
segIdLeakFactor = 0.25;
segIdGaussWidth = 10;
segIdMaxObjects = 2;
idLeakFactor = 0.5;
%% nsrcs KS
if ~bNsrcsGroundtruth
    nsrcsKs = bbs.createKS( 'NumberOfSourcesKS', {'nSrcs','learned_models/NumberOfSourcesKS/mc3_models_dataset_1',ppRemoveDc} );
end
fprintf( '.' );
%% identification KSs
if any( strcmp( runningMode, {'segregated identification', 'both'} ) )
    segmModelFileName = '70c4feac861e382413b4c4bfbf895695.mat';
    dirSegr = fullfile( db.tmp, 'learned_models', 'SegmentationKS' );
    if ~exist(dirSegr, 'dir')
        mkdir( dirSegr );
    end
    copyfile(  cleanPathFromRelativeRefs( [pwd '/../../AMLTTP/test/' segmModelFileName] ), ...
               fullfile( dirSegr, segmModelFileName ), ...
               'f' );
    fprintf( '.' );
    spatSegrKs = bbs.createKS( 'StreamSegregationKS', ...
        {cleanPathFromRelativeRefs( [pwd '/../../AMLTTP/test/SegmentationTrainerParameters5.yaml'] )} );
    fprintf( '.' );
    for ii = 1 : numel( idSegModels )
        idSegKss{ii} = bbs.createKS('SegmentIdentityKS', {idSegModels(ii).name, idSegModels(ii).dir, ppRemoveDc});
        fprintf( '.' );
        idSegKss{ii}.setInvocationFrequency(10);
    end
    collectSegId = bbs.createKS('IntegrateSegregatedIdentitiesKS', {segIdLeakFactor,segIdGaussWidth,segIdMaxObjects,segIdClassThresholds});
end
if any( strcmp( runningMode, {'frequencyMasked loc', 'both'} ) )
    for ii = 1 : numel( idModels )
        idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        idKss{ii}.setInvocationFrequency(10);
    end  
    collectId = bbs.createKS('IntegrateFullstreamIdentitiesKS', {idLeakFactor,inf,idClassThresholds});
end
%% ground truth intrusion
groundtruthKs = bbs.createKS('GroundTruthKS', {labels, onOffsets, activity, azms, bNsrcsGroundtruth});
%% knowledge source binding
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, {groundtruthKs}, 'replaceOld' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, {dnnlocKs}, 'replaceOld' );
bbs.blackboardMonitor.bind({dnnlocKs}, {locDecKs}, 'add' );
bbs.blackboardMonitor.bind({locDecKs}, {rot}, 'replaceOld', 'RotateHead' );
if ~bNsrcsGroundtruth
    bbs.blackboardMonitor.bind({locDecKs}, {nsrcsKs}, 'replaceOld' );
end
if any( strcmp( runningMode, {'segregated identification', 'both'} ) )
    if ~bNsrcsGroundtruth
        bbs.blackboardMonitor.bind({nsrcsKs}, {spatSegrKs}, 'replaceOld' );
    else
        bbs.blackboardMonitor.bind({groundtruthKs}, {spatSegrKs}, 'replaceOld', 'NSrcsTruth' );
    end
    bbs.blackboardMonitor.bind({spatSegrKs}, idSegKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idSegKss{end}}, {collectSegId}, 'replaceOld' );
end
if any( strcmp( runningMode, {'frequencyMasked loc', 'both'} ) )
    bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idKss{end}}, {collectId}, 'replaceOld' );    
end
