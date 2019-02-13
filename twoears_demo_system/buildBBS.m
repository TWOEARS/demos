function [bbs,locDec]  = buildBBS(sim, bFrontLocationOnly, bSolveConfusion, ...
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
    dnnloc = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE-FRONT'});
else
    dnnloc = bbs.createKS('DnnLocationKS', {'MCT-DIFFUSE'});
end
locDec = bbs.createKS( 'LocalisationDecisionKS', {bSolveConfusion,0.5} );
rot = bbs.createKS('HeadRotationKS', {sim});
%%
idClassThresholds.fire = 0.5;
segIdClassThresholds.fire = 0.5;
segIdLeakFactor = 0.25;
segIdGaussWidth = 10;
segIdMaxObjects = 2;
idLeakFactor = 0.5;
%% identification KSs
nsrcs = bbs.createKS( 'NumberOfSourcesKS', {'nSrcs','learned_models/NumberOfSourcesKS/mc3_models_dataset_1',ppRemoveDc} );
fprintf( '.' );
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
    segment = bbs.createKS( 'StreamSegregationKS', ...
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
idCheat = bbs.createKS('GroundTruthPlotKS', {labels, onOffsets, activity, azms});
%% knowledge source binding
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, {idCheat}, 'replaceOld' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, {dnnloc}, 'replaceOld' );
bbs.blackboardMonitor.bind({dnnloc}, {locDec}, 'add' );
bbs.blackboardMonitor.bind({locDec}, {rot}, 'replaceOld', 'RotateHead' );
if any( strcmp( runningMode, {'segregated identification', 'both'} ) )
    bbs.blackboardMonitor.bind({locDec}, {nsrcs}, 'replaceOld' );
    bbs.blackboardMonitor.bind({nsrcs}, {segment}, 'replaceOld' );
    bbs.blackboardMonitor.bind({segment}, idSegKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idSegKss{end}}, {collectSegId}, 'replaceOld' );
end
if any( strcmp( runningMode, {'frequencyMasked loc', 'both'} ) )
    bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
    bbs.blackboardMonitor.bind({idKss{end}}, {collectId}, 'replaceOld' );    
end
