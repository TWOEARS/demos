function [bbs,locDecKs]  = buildBBS(sim, bFrontLocationOnly, bSolveConfusion, ...
                                  bNsrcsGroundtruth, bFsInitSI, ...
                                  idModels, idSegModels, fs, runningMode, ...
                                  labels, onOffsets, activity, azms )

fprintf( 'Building blackboard system' );
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
if bFsInitSI
    segIdLeakFactor = 1.0;
else
    segIdLeakFactor = 0.75;
end
segIdGaussWidth = 10;
segIdMaxObjects = inf;
idLeakFactor = 1.0;
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
if any( strcmp( runningMode, {'frequencyMasked loc', 'both'} ) ) || bFsInitSI
    for ii = 1 : numel( idModels )
        if bFsInitSI && ~strcmp( idModels(ii).name, idSegModels(ii).name )
            error( 'To enable Fullstream models initiating Segregated Identification, include FS and SegId models for the same event types in the same order.' );
        end
        idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        idKss{ii}.setInvocationFrequency(10);
    end  
    collectId = bbs.createKS('IntegrateFullstreamIdentitiesKS', {idLeakFactor,inf,idClassThresholds});
end
%% ground truth intrusion
groundtruthKs = bbs.createKS('GroundTruthKS', {labels, onOffsets, activity, azms, bNsrcsGroundtruth});
%% knowledge source binding
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, {dnnlocKs}, 'replaceOld' );
bbs.blackboardMonitor.bind({dnnlocKs}, {locDecKs}, 'add' );
bbs.blackboardMonitor.bind({locDecKs}, {rot}, 'replaceOld', 'RotateHead' );

bbs.blackboardMonitor.bind({locDecKs}, {groundtruthKs}, 'replaceOld' );
if ~bNsrcsGroundtruth
    bbs.blackboardMonitor.bind({locDecKs}, {nsrcsKs}, 'replaceOld' );
end

if any( strcmp( runningMode, {'frequencyMasked loc', 'both'} ) )
%     % TODO: integrate frequencyMasked location models
%     for ii = 1 : numel( idKss )
%         bbs.blackboardMonitor.bind({idKss{ii}}, {typeMaskedLoc{ii}}, 'replaceOld', 'SoundEventDetected' );
%     end
    if bFsInitSI
        bbs.blackboardMonitor.bind({spatSegrKs}, idKss, 'replaceOld' );
    else
        bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
    end
    bbs.blackboardMonitor.bind(idKss, {collectId}, 'replaceParallelOld' );    
end

if any( strcmp( runningMode, {'segregated identification', 'both'} ) )
    if ~bNsrcsGroundtruth
        bbs.blackboardMonitor.bind({nsrcsKs}, {spatSegrKs}, 'replaceOld' );
    else
        bbs.blackboardMonitor.bind({groundtruthKs}, {spatSegrKs}, 'replaceOld', 'NSrcsTruth' );
    end
    if bFsInitSI
        for ii = 1 : numel( idKss )
            bbs.blackboardMonitor.bind({idKss{ii}}, {idSegKss{ii}}, 'replaceOld', 'SoundEventDetected' );
        end
    else
        bbs.blackboardMonitor.bind({spatSegrKs}, idSegKss, 'replaceOld' );
    end
    bbs.blackboardMonitor.bind(idSegKss, {collectSegId}, 'replaceParallelOld' );
end

fprintf( ';\n' );
